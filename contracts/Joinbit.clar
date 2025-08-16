
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
(define-constant err-proposal-not-found (err u110))
(define-constant err-proposal-ended (err u111))
(define-constant err-already-voted (err u112))
(define-constant err-insufficient-reputation (err u113))
(define-constant err-proposal-not-passed (err u114))
(define-constant err-proposal-already-executed (err u115))
(define-constant err-voting-period-not-ended (err u116))
(define-constant err-invalid-proposal-type (err u117))
(define-constant err-invalid-referral-code (err u118))
(define-constant err-self-referral (err u119))
(define-constant err-referral-cooldown (err u120))
(define-constant err-referrer-not-active (err u121))
(define-constant err-max-referrals-reached (err u122))
(define-constant err-referral-code-exists (err u123))

(define-data-var last-token-id uint u0)
(define-data-var last-proposal-id uint u0)
(define-data-var min-reputation-to-propose uint u100)
(define-data-var voting-period-blocks uint u1440)
(define-data-var quorum-percentage uint u25)
(define-data-var membership-price uint u1000000)
(define-data-var contract-paused bool false)
(define-data-var referral-cooldown-blocks uint u144)
(define-data-var max-referrals-per-member uint u100)
(define-data-var total-referral-codes uint u0)

(define-map token-count principal uint)
(define-map membership-tiers uint {tier: (string-ascii 20), benefits: (string-ascii 100), price: uint})
(define-map member-benefits principal {tier: uint, expires-at: uint, active: bool})
(define-map marketplace {token-id: uint} {price: uint, seller: principal})
(define-map member-reputation principal {reputation: uint, last-activity: uint, votes-cast: uint})
(define-map proposals uint {
  id: uint,
  proposer: principal,
  title: (string-ascii 50),
  description: (string-ascii 200),
  proposal-type: (string-ascii 20),
  target-value: uint,
  votes-for: uint,
  votes-against: uint,
  total-votes: uint,
  created-at: uint,
  ends-at: uint,
  executed: bool,
  passed: bool
})
(define-map proposal-votes {proposal-id: uint, voter: principal} {vote: bool, weight: uint})
(define-map reputation-rewards principal {total-earned: uint, last-claim: uint})
(define-map referral-codes (string-ascii 10) {owner: principal, created-at: uint, total-referrals: uint})
(define-map member-referrals principal {referrer: principal, referred-at: uint, rewards-earned: uint})
(define-map referral-stats principal {total-referred: uint, total-earned: uint, last-referral: uint})
(define-map tier-commission-rates uint {bronze-rate: uint, silver-rate: uint, gold-rate: uint})
(define-map referral-leaderboard uint {member: principal, referral-count: uint, total-earnings: uint})

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
    (map-set member-reputation recipient {
      reputation: u50,
      last-activity: stacks-block-height,
      votes-cast: u0
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

(define-public (earn-reputation (amount uint) (activity-type (string-ascii 20)))
  (let
    (
      (current-rep (default-to {reputation: u0, last-activity: u0, votes-cast: u0} (map-get? member-reputation tx-sender)))
      (new-reputation (+ (get reputation current-rep) amount))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (map-set member-reputation tx-sender {
      reputation: new-reputation,
      last-activity: stacks-block-height,
      votes-cast: (get votes-cast current-rep)
    })
    (ok new-reputation)
  )
)

(define-public (submit-proposal (title (string-ascii 50)) (description (string-ascii 200)) (proposal-type (string-ascii 20)) (target-value uint))
  (let
    (
      (proposal-id (+ (var-get last-proposal-id) u1))
      (proposer-rep (default-to {reputation: u0, last-activity: u0, votes-cast: u0} (map-get? member-reputation tx-sender)))
      (ends-at (+ stacks-block-height (var-get voting-period-blocks)))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (asserts! (>= (get reputation proposer-rep) (var-get min-reputation-to-propose)) err-insufficient-reputation)
    (map-set proposals proposal-id {
      id: proposal-id,
      proposer: tx-sender,
      title: title,
      description: description,
      proposal-type: proposal-type,
      target-value: target-value,
      votes-for: u0,
      votes-against: u0,
      total-votes: u0,
      created-at: stacks-block-height,
      ends-at: ends-at,
      executed: false,
      passed: false
    })
    (var-set last-proposal-id proposal-id)
    (try! (earn-reputation u10 "proposal-submit"))
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
      (voter-rep (default-to {reputation: u0, last-activity: u0, votes-cast: u0} (map-get? member-reputation tx-sender)))
      (vote-weight (+ (get reputation voter-rep) u1))
      (existing-vote (map-get? proposal-votes {proposal-id: proposal-id, voter: tx-sender}))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (asserts! (< stacks-block-height (get ends-at proposal)) err-proposal-ended)
    (asserts! (is-none existing-vote) err-already-voted)
    (map-set proposal-votes {proposal-id: proposal-id, voter: tx-sender} {vote: vote, weight: vote-weight})
    (map-set proposals proposal-id (merge proposal {
      votes-for: (if vote (+ (get votes-for proposal) vote-weight) (get votes-for proposal)),
      votes-against: (if vote (get votes-against proposal) (+ (get votes-against proposal) vote-weight)),
      total-votes: (+ (get total-votes proposal) vote-weight)
    }))
    (map-set member-reputation tx-sender {
      reputation: (get reputation voter-rep),
      last-activity: stacks-block-height,
      votes-cast: (+ (get votes-cast voter-rep) u1)
    })
    (try! (earn-reputation u5 "vote-cast"))
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
      (total-members (var-get last-token-id))
      (required-quorum (/ (* total-members (var-get quorum-percentage)) u100))
      (vote-passed (> (get votes-for proposal) (get votes-against proposal)))
      (quorum-met (>= (get total-votes proposal) required-quorum))
    )
    (asserts! (>= stacks-block-height (get ends-at proposal)) err-voting-period-not-ended)
    (asserts! (not (get executed proposal)) err-proposal-already-executed)
    (asserts! (and vote-passed quorum-met) err-proposal-not-passed)
    (map-set proposals proposal-id (merge proposal {
      executed: true,
      passed: true
    }))
    (if (is-eq (get proposal-type proposal) "price-change")
      (var-set membership-price (get target-value proposal))
      true
    )
    (if (is-eq (get proposal-type proposal) "pause-contract")
      (var-set contract-paused true)
      true
    )
    (if (is-eq (get proposal-type proposal) "unpause-contract")
      (var-set contract-paused false)
      true
    )
    (try! (earn-reputation u20 "proposal-execute"))
    (ok true)
  )
)

(define-public (claim-reputation-reward)
  (let
    (
      (member-rep (default-to {reputation: u0, last-activity: u0, votes-cast: u0} (map-get? member-reputation tx-sender)))
      (current-rewards (default-to {total-earned: u0, last-claim: u0} (map-get? reputation-rewards tx-sender)))
      (reputation-score (get reputation member-rep))
      (blocks-since-last-claim (- stacks-block-height (get last-claim current-rewards)))
      (reward-amount (/ (* reputation-score blocks-since-last-claim) u10000))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (asserts! (> reward-amount u0) err-insufficient-payment)
    (map-set reputation-rewards tx-sender {
      total-earned: (+ (get total-earned current-rewards) reward-amount),
      last-claim: stacks-block-height
    })
    (try! (stx-transfer? reward-amount contract-owner tx-sender))
    (ok reward-amount)
  )
)

(define-public (update-governance-params (min-rep uint) (voting-blocks uint) (quorum-pct uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set min-reputation-to-propose min-rep)
    (var-set voting-period-blocks voting-blocks)
    (var-set quorum-percentage quorum-pct)
    (ok true)
  )
)

(define-read-only (get-member-reputation (member principal))
  (map-get? member-reputation member)
)

(define-read-only (get-proposal-info (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-proposal-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-reputation-rewards (member principal))
  (map-get? reputation-rewards member)
)

(define-read-only (get-governance-params)
  {
    min-reputation-to-propose: (var-get min-reputation-to-propose),
    voting-period-blocks: (var-get voting-period-blocks),
    quorum-percentage: (var-get quorum-percentage),
    total-proposals: (var-get last-proposal-id)
  }
)

(define-read-only (calculate-voting-power (member principal))
  (let
    (
      (member-rep (default-to {reputation: u0, last-activity: u0, votes-cast: u0} (map-get? member-reputation member)))
      (member-perks (map-get? member-benefits member))
    )
    (match member-perks
      benefits (+ (get reputation member-rep) (* (get tier benefits) u10))
      (get reputation member-rep)
    )
  )
)

(define-public (generate-referral-code (code (string-ascii 10)))
  (let
    (
      (existing-code (map-get? referral-codes code))
      (member-perks (map-get? member-benefits tx-sender))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (asserts! (is-none existing-code) err-referral-code-exists)
    (map-set referral-codes code {
      owner: tx-sender,
      created-at: stacks-block-height,
      total-referrals: u0
    })
    (var-set total-referral-codes (+ (var-get total-referral-codes) u1))
    (ok true)
  )
)

(define-public (purchase-membership-with-referral (tier uint) (referral-code (string-ascii 10)))
  (let
    (
      (tier-info (unwrap! (map-get? membership-tiers tier) err-invalid-membership-tier))
      (price (get price tier-info))
      (referral-info (unwrap! (map-get? referral-codes referral-code) err-invalid-referral-code))
      (referrer (get owner referral-info))
      (referrer-benefits (map-get? member-benefits referrer))
      (referrer-stats (default-to {total-referred: u0, total-earned: u0, last-referral: u0} (map-get? referral-stats referrer)))
      (last-referral-time (get last-referral referrer-stats))
      (commission-rates (default-to {bronze-rate: u5, silver-rate: u10, gold-rate: u15} (map-get? tier-commission-rates u1)))
      (referrer-tier (match referrer-benefits benefits (get tier benefits) u1))
      (commission-rate (if (is-eq referrer-tier u3) (get gold-rate commission-rates)
                       (if (is-eq referrer-tier u2) (get silver-rate commission-rates)
                       (get bronze-rate commission-rates))))
      (referral-reward (/ (* price commission-rate) u100))
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (not (var-get contract-paused)) err-membership-not-active)
    (asserts! (not (is-eq tx-sender referrer)) err-self-referral)
    (asserts! (is-membership-active referrer) err-referrer-not-active)
    (asserts! (>= stacks-block-height (+ last-referral-time (var-get referral-cooldown-blocks))) err-referral-cooldown)
    (asserts! (< (get total-referred referrer-stats) (var-get max-referrals-per-member)) err-max-referrals-reached)
    (begin
      (try! (stx-transfer? price tx-sender contract-owner))
      (try! (stx-transfer? referral-reward contract-owner referrer))
      (try! (nft-mint? joinbit-membership token-id tx-sender))
      (var-set last-token-id token-id)
      (map-set token-count tx-sender (+ (default-to u0 (map-get? token-count tx-sender)) u1))
      (map-set member-benefits tx-sender {
        tier: tier,
        expires-at: (+ stacks-block-height u52560),
        active: true
      })
      (map-set member-reputation tx-sender {
        reputation: u50,
        last-activity: stacks-block-height,
        votes-cast: u0
      })
      (map-set member-referrals tx-sender {
        referrer: referrer,
        referred-at: stacks-block-height,
        rewards-earned: u0
      })
      (map-set referral-codes referral-code (merge referral-info {
        total-referrals: (+ (get total-referrals referral-info) u1)
      }))
      (map-set referral-stats referrer {
        total-referred: (+ (get total-referred referrer-stats) u1),
        total-earned: (+ (get total-earned referrer-stats) referral-reward),
        last-referral: stacks-block-height
      })
      (unwrap! (update-referral-leaderboard referrer) err-membership-not-active)
      (ok token-id)
    )
  )
)

(define-public (claim-referral-rewards)
  (let
    (
      (member-stats (default-to {total-referred: u0, total-earned: u0, last-referral: u0} (map-get? referral-stats tx-sender)))
      (pending-rewards (get total-earned member-stats))
    )
    (asserts! (is-membership-active tx-sender) err-membership-not-active)
    (asserts! (> pending-rewards u0) err-insufficient-payment)
    (map-set referral-stats tx-sender {
      total-referred: (get total-referred member-stats),
      total-earned: u0,
      last-referral: (get last-referral member-stats)
    })
    (try! (stx-transfer? pending-rewards contract-owner tx-sender))
    (ok pending-rewards)
  )
)

(define-public (set-commission-rates (tier uint) (bronze uint) (silver uint) (gold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set tier-commission-rates tier {
      bronze-rate: bronze,
      silver-rate: silver,
      gold-rate: gold
    })
    (ok true)
  )
)

(define-public (update-referral-params (cooldown uint) (max-referrals uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set referral-cooldown-blocks cooldown)
    (var-set max-referrals-per-member max-referrals)
    (ok true)
  )
)

(define-private (update-referral-leaderboard (member principal))
  (let
    (
      (member-stats (default-to {total-referred: u0, total-earned: u0, last-referral: u0} (map-get? referral-stats member)))
      (referral-count (get total-referred member-stats))
      (total-earnings (get total-earned member-stats))
      (next-position (+ (var-get total-referral-codes) u1))
    )
    (map-set referral-leaderboard next-position {
      member: member,
      referral-count: referral-count,
      total-earnings: total-earnings
    })
    (ok true)
  )
)

(define-public (boost-referral-rewards (member principal) (bonus-amount uint))
  (let
    (
      (member-stats (default-to {total-referred: u0, total-earned: u0, last-referral: u0} (map-get? referral-stats member)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-membership-active member) err-membership-not-active)
    (map-set referral-stats member {
      total-referred: (get total-referred member-stats),
      total-earned: (+ (get total-earned member-stats) bonus-amount),
      last-referral: (get last-referral member-stats)
    })
    (unwrap! (update-referral-leaderboard member) err-membership-not-active)
    (ok true)
  )
)

(define-read-only (get-referral-code-info (code (string-ascii 10)))
  (map-get? referral-codes code)
)

(define-read-only (get-member-referral-info (member principal))
  (map-get? member-referrals member)
)

(define-read-only (get-referral-stats (member principal))
  (map-get? referral-stats member)
)

(define-read-only (get-commission-rates (tier uint))
  (map-get? tier-commission-rates tier)
)

(define-read-only (get-referral-leaderboard (position uint))
  (map-get? referral-leaderboard position)
)

(define-read-only (get-leaderboard-position (member principal))
  (some u1)
)

(define-read-only (get-referral-system-stats)
  {
    total-referral-codes: (var-get total-referral-codes),
    referral-cooldown-blocks: (var-get referral-cooldown-blocks),
    max-referrals-per-member: (var-get max-referrals-per-member)
  }
)

(define-read-only (calculate-potential-reward (tier uint) (referrer-tier uint))
  (let
    (
      (tier-info (map-get? membership-tiers tier))
      (commission-rates (default-to {bronze-rate: u5, silver-rate: u10, gold-rate: u15} (map-get? tier-commission-rates u1)))
      (commission-rate (if (is-eq referrer-tier u3) (get gold-rate commission-rates)
                       (if (is-eq referrer-tier u2) (get silver-rate commission-rates)
                       (get bronze-rate commission-rates))))
    )
    (match tier-info
      membership-info (some (/ (* (get price membership-info) commission-rate) u100))
      none
    )
  )
)

(map-set membership-tiers u1 {tier: "Bronze", benefits: "Basic access to community features", price: u1000000})
(map-set membership-tiers u2 {tier: "Silver", benefits: "Premium features + priority support", price: u5000000})
(map-set membership-tiers u3 {tier: "Gold", benefits: "All features + exclusive events", price: u10000000})
(map-set tier-commission-rates u1 {bronze-rate: u5, silver-rate: u10, gold-rate: u15})


