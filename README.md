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

## 🔥 Loyalty Streak System

Joinbit now features an advanced loyalty streak system that rewards members for consistent daily engagement and activity!

### 🎯 How It Works

- **Daily Activity Tracking**: System automatically tracks member engagement across voting, proposals, and marketplace activities
- **Streak Milestones**: Progressive rewards for 7, 30, 90, and 365-day streaks
- **Tier-Based Multipliers**: Higher membership tiers earn greater streak rewards
- **Daily Reward Claims**: Claim rewards once per day for active streaks

### 🏆 Reward Structure

#### Base Rewards (Bronze Members)
- **7+ days**: 2x multiplier (0.2 STX)
- **30+ days**: 5x multiplier (0.5 STX) 
- **90+ days**: 10x multiplier (1.0 STX)
- **365+ days**: 20x multiplier (2.0 STX)

#### Tier Multipliers
- **Bronze**: 1x base reward
- **Silver**: 2x base reward  
- **Gold**: 3x base reward

### 🚀 New Functions

#### Public Functions
- `claim-streak-reward()` - Claim daily streak rewards (minimum 7-day streak)
- `update-streak-params(window, min-streak, base-reward)` - Admin function to adjust parameters

#### Read-Only Functions
- `get-loyalty-streak(member)` - View member's current and longest streaks
- `get-streak-milestone(milestone-id)` - Get milestone reward details
- `calculate-current-streak-reward(member)` - Preview potential reward amount
- `is-streak-reward-claimable(member)` - Check if daily reward is available
- `get-streak-system-stats()` - View system configuration

### 💡 Usage Examples

#### Check Your Streak Status
```clarity
(contract-call? .Joinbit get-loyalty-streak tx-sender)
```

#### Claim Daily Streak Reward
```clarity
(contract-call? .Joinbit claim-streak-reward)
```

#### Preview Reward Amount
```clarity
(contract-call? .Joinbit calculate-current-streak-reward tx-sender)
```

## 📈 Roadmap

- [x] 🏆 Loyalty rewards for long-term members ✅
- [ ] 🎨 Metadata and visual NFT attributes
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


