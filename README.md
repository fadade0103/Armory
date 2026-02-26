
Armory: NFT Marketplace for Digital Collectible Weapons

An innovative NFT marketplace built on the Stacks blockchain, specializing in digital collectible weapons and gear with verifiable rarity levels and battletested rating systems.

 Overview

Armory is a decentralized platform where users can discover, trade, and battle with NFT weapons and gear. Each collectible has cryptographically verified rarity, combat statistics, and ownership history recorded onchain.

 Features

 🏰 Weapon Forging
 Contract owner mints new weapon NFTs with unique attributes
 Each weapon has customizable name, rarity tier, and initial battle rating
 Immutable creation timestamp for provenance tracking

  Rarity System
 5Tier Rarity Classification:
   Tier 1: Common
   Tier 2: Uncommon
   Tier 3: Rare
   Tier 4: Epic
   Tier 5: Legendary
 Pertier statistics tracking for market analysis
 Raritybased value determination

 ⚔️ Battle Rating System
 Combat performance metrics on 0100 scale
 Ownerverified ratings based on battle test results
 Updateable ratings to reflect real combat history
 Ratingbased weapon tiering and matchmaking

 🛒 Marketplace Operations
 List: Sellers can list weapons at custom prices
 Unlist: Remove listings without losing NFT ownership
 Purchase: Buyers can acquire weapons with STX payments
 Transfer: Full ownership transfer with listing cleanup

 Smart Contract Architecture

 Data Structures
 Weapons Map: Stores complete weapon metadata and ownership
 Listings Map: Manages active marketplace listings
 Rarity Stats: Tracks aggregate statistics per rarity level
 Weapon Counter: Maintains total NFT supply

 Core Functions

 Public Functions
 forgeweapon: Mint new weapon NFT (Owner only)
 listweapon: Create marketplace listing for weapon
 unlistweapon: Remove active listing
 purchaseweapon: Acquire listed weapon
 updatebattlerating: Update combat performance metrics (Owner only)

 ReadOnly Functions
 gettotalweapons: Retrieve total weapons minted
 getweapon: Fetch complete weapon data
 getraritystats: View statistics for rarity tier
 getweaponowner: Check current weapon owner

 Error Codes

 Code  Meaning 

 401  Unauthorized access 
 404  Resource not found 
 400  Invalid rarity level (15) 
 401  Invalid battle rating (0100) 
 402  Insufficient balance 
 403  Resource already exists 

 Usage Example

clarion
;; Forge a new legendary sword
(contractcall? .armory forgeweapon
  "Excalibur's Edge"
  u5
  u95
)

;; List weapon for sale at 50 STX
(contractcall? .armory listweapon u1 u50000000)

;; Purchase weapon
(contractcall? .armory purchaseweapon u1 u50000000)

;; Update battle rating after combat
(contractcall? .armory updatebattlerating u1 u98)


 Technical Stack

 Language: Clarity
 Blockchain: Stacks Layer 2
 Testing: Clarinet
 Storage: Onchain maps


 Security Features

 Rolebased authorization (Owner/Nonowner)
 Ownership verification for transfers
 Price validation and safeguards
 Immutable provenance records
 Input validation for all parameters


 Getting Started

1. Install Clarinet: brew install clarinet (macOS) or follow [Clarinet docs](https://github.com/hirosystems/clarinet)
2. Clone this repository
3. Run tests: clarinet test
4. Deploy to testnet: clarinet deploy


 Testing & Validation

shellscript
 Run Clarinet checks
clarinet check

 Execute test suite
clarinet test

 Deploy to local environment
clarinet devnet start


 Future Enhancements

 Battle mechanics and PvP integration
 Seasonal ranking system
 Gear crafting and upgrades
 Staking rewards for rare weapons
 Crosschain weapon bridging


 License

MIT

 Contributing

Submissions and contributions are welcome! Please ensure all changes pass clarinet check before submitting pull requests.
