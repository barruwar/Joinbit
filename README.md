# 🎫 Joinbit - Membership NFT System

> 🚀 **Token-based exclusive memberships on Stacks blockchain**

## 📋 Overview

Joinbit is a comprehensive membership NFT system that enables communities to create, manage, and trade exclusive memberships as NFTs. Members can purchase different tiers of membership, trade them on the marketplace, and enjoy tier-based benefits.

## ✨ Features

- 🎯 **Multi-tier Membership System** - Bronze, Silver, and Gold tiers with different benefits
- 💰 **Built-in Marketplace** - Buy and sell membership NFTs
- ⏰ **Time-based Memberships** - Memberships expire and can be renewed
- 🔄 **Transferable NFTs** - Trade membership benefits between users
- 👑 **Admin Controls** - Contract owner can manage tiers and pause system
- 📊 **Membership Tracking** - Track active memberships and expiration dates

## 🏗️ Contract Structure

### Membership Tiers
- **Bronze** (Tier 1): 1 STX - Basic community access
- **Silver** (Tier 2): 5 STX - Premium features + priority support  
- **Gold** (Tier 3): 10 STX - All features + exclusive events

### Key Functions

#### 🛒 **Purchase & Management**
- `purchase-membership(tier)` - Buy a new membership NFT
- `renew-membership(tier)` - Extend your membership duration
- `mint-membership(recipient, tier)` - Admin mint for specific user

#### 🔄 **Trading & Marketplace**
- `list-for-sale(token-id, price)` - List your membership for sale
- `buy-from-marketplace(token-id)` - Purchase from marketplace
- `transfer(token-id, sender, recipient)` - Direct transfer

#### 📖 **Read Functions**
- `is-membership-active(member)` - Check if membership is valid
- `get-membership-info(member)` - Get member's tier and expiration
- `get-marketplace-listing(token-id)` - View marketplace listings

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo>
cd joinbit
```

```bash
clarinet check
```

```bash
clarinet test
```

### 🧪 Testing the Contract

#### Deploy locally:
```bash
clarinet console
```

#### Purchase a membership:
```clarity
(contract-call? .Joinbit purchase-membership u1)
```

#### Check membership status:
```clarity
(contract-call? .Joinbit is-membership-active tx-sender)
```

#### List for sale:
```clarity
(contract-call? .Joinbit list-for-sale u1 u2000000)
```

## 📊 Usage Examples

### For Community Members
1. **Join the community**: Purchase a membership tier that fits your needs
2. **Enjoy benefits**: Access tier-specific features and benefits
3. **Trade memberships**: Sell or transfer your membership NFT
4. **Renew membership**: Extend your membership before expiration

### For Community Owners
1. **Customize tiers**: Set up membership tiers with specific benefits and pricing
2. **Mint memberships**: Directly mint memberships for special members
3. **Manage system**: Pause/unpause contract and update pricing
4. **Monitor activity**: Track membership sales and renewals

## 🔧 Configuration

### Setting Up Custom Tiers
```clarity
(contract-call? .Joinbit set-membership-tier 
  u4 
  "Platinum" 
  "VIP access + personal support" 
  u20000000)
```

### Updating Prices
```clarity
(contract-call? .Joinbit update-membership-price u2000000)
```

## 🛡️ Security Features

- ✅ Owner-only administrative functions
- ✅ Membership expiration validation
- ✅ Transfer ownership verification
- ✅ Marketplace listing protection
- ✅ Contract pause mechanism

## 📈 Roadmap

- [ ] 🎨 Metadata and visual NFT attributes
- [ ] 🏆 Loyalty rewards for long-term members
- [ ] 🤝 Partnership integrations
- [ ] 📱 Mobile app integration
- [ ] 🔔 Expiration notifications

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.


