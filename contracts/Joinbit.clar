
(define-non-fungible-token joinbit-membership uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-commission (err u103))
(define-constant err-listing-expired (err u104))
(define-constant err-nft-not-found (err u105))
(define-constant err-sender-equals-recipient (err u106))
(define-constant err-invalid-membership-tier (err u107))
(define-constant err-membership-not-active (err u108))
(define-constant err-insufficient-payment (err u109))

(define-data-var last-token-id uint u0)
(define-data-var membership-price uint u1000000)
(define-data-var contract-paused bool false)

(define-map token-count principal uint)
(define-map membership-tiers uint {tier: (string-ascii 20), benefits: (string-ascii 100), price: uint})
(define-map member-benefits principal {tier: uint, expires-at: uint, active: bool})
(define-map marketplace {token-id: uint} {price: uint, seller: principal})

(define-public (mint-membership (recipient principal) (tier uint))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
      (tier-info (unwrap! (map-get? membership-tiers tier) err-invalid-membership-tier))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get contract-paused)) err-membership-not-active)
    (try! (nft-mint? joinbit-membership token-id recipient))
    (var-set last-token-id token-id)
    (map-set token-count recipient (+ (default-to u0 (map-get? token-count recipient)) u1))
    (map-set member-benefits recipient {
      tier: tier,
      expires-at: (+ stacks-block-height u52560),
      active: true
    })
    (ok token-id)
  )
)

(define-public (purchase-membership (tier uint))
  (let
    (
      (tier-info (unwrap! (map-get? membership-tiers tier) err-invalid-membership-tier))
      (price (get price tier-info))
    )
    (asserts! (not (var-get contract-paused)) err-membership-not-active)
    (try! (stx-transfer? price tx-sender contract-owner))
    (mint-membership tx-sender tier)
  )
)

(define-public (renew-membership (tier uint))
  (let
    (
      (tier-info (unwrap! (map-get? membership-tiers tier) err-invalid-membership-tier))
      (price (get price tier-info))
      (current-benefits (default-to {tier: u0, expires-at: u0, active: false} (map-get? member-benefits tx-sender)))
    )
    (asserts! (not (var-get contract-paused)) err-membership-not-active)
    (try! (stx-transfer? price tx-sender contract-owner))
    (map-set member-benefits tx-sender {
      tier: tier,
      expires-at: (+ stacks-block-height u52560),
      active: true
    })
    (ok true)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (not (is-eq sender recipient)) err-sender-equals-recipient)
    (try! (nft-transfer? joinbit-membership token-id sender recipient))
    (let
      (
        (sender-balance (default-to u0 (map-get? token-count sender)))
        (recipient-balance (default-to u0 (map-get? token-count recipient)))
        (sender-benefits (map-get? member-benefits sender))
      )
      (map-set token-count sender (- sender-balance u1))
      (map-set token-count recipient (+ recipient-balance u1))
      (match sender-benefits
        benefits (map-set member-benefits recipient benefits)
        true
      )
      (map-delete member-benefits sender)
      (ok true)
    )
  )
)

(define-public (list-for-sale (token-id uint) (price uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? joinbit-membership token-id) err-nft-not-found))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (map-set marketplace {token-id: token-id} {price: price, seller: tx-sender})
    (ok true)
  )
)

(define-public (unlist-from-sale (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace {token-id: token-id}) err-listing-not-found))
      (seller (get seller listing))
    )
    (asserts! (is-eq tx-sender seller) err-not-token-owner)
    (map-delete marketplace {token-id: token-id})
    (ok true)
  )
)

(define-public (buy-from-marketplace (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace {token-id: token-id}) err-listing-not-found))
      (price (get price listing))
      (seller (get seller listing))
      (owner (unwrap! (nft-get-owner? joinbit-membership token-id) err-nft-not-found))
    )
    (asserts! (is-eq seller owner) err-not-token-owner)
    (asserts! (not (is-eq tx-sender seller)) err-sender-equals-recipient)
    (try! (stx-transfer? price tx-sender seller))
    (try! (nft-transfer? joinbit-membership token-id seller tx-sender))
    (map-delete marketplace {token-id: token-id})
    (let
      (
        (seller-balance (default-to u0 (map-get? token-count seller)))
        (buyer-balance (default-to u0 (map-get? token-count tx-sender)))
        (seller-benefits (map-get? member-benefits seller))
      )
      (map-set token-count seller (- seller-balance u1))
      (map-set token-count tx-sender (+ buyer-balance u1))
      (match seller-benefits
        benefits (map-set member-benefits tx-sender benefits)
        true
      )
      (map-delete member-benefits seller)
      (ok true)
    )
  )
)

(define-public (set-membership-tier (tier uint) (name (string-ascii 20)) (benefits (string-ascii 100)) (price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set membership-tiers tier {tier: name, benefits: benefits, price: price})
    (ok true)
  )
)

(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused (not (var-get contract-paused)))
    (ok (var-get contract-paused))
  )
)

(define-public (update-membership-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set membership-price new-price)
    (ok true)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? joinbit-membership token-id))
)

(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? token-count account))
)

(define-read-only (get-membership-info (member principal))
  (map-get? member-benefits member)
)

(define-read-only (is-membership-active (member principal))
  (match (map-get? member-benefits member)
    benefits (and (get active benefits) (> (get expires-at benefits) stacks-block-height))
    false
  )
)

(define-read-only (get-membership-tier-info (tier uint))
  (map-get? membership-tiers tier)
)

(define-read-only (get-marketplace-listing (token-id uint))
  (map-get? marketplace {token-id: token-id})
)

(define-read-only (get-contract-info)
  {
    total-supply: (var-get last-token-id),
    membership-price: (var-get membership-price),
    contract-paused: (var-get contract-paused),
    contract-owner: contract-owner
  }
)

(map-set membership-tiers u1 {tier: "Bronze", benefits: "Basic access to community features", price: u1000000})
(map-set membership-tiers u2 {tier: "Silver", benefits: "Premium features + priority support", price: u5000000})
(map-set membership-tiers u3 {tier: "Gold", benefits: "All features + exclusive events", price: u10000000})