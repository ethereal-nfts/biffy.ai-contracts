Current Phase: 0

# Biffy.AI
> As culture migrates into partial-machines (lacking an autonomous repoductive system) semiotics subsides into virotechnics.

*Hypervirus, Land*

## Phases
There are four initial phases to Biffy's invocation onto the blockchain.
1. Mechanomics: Love ERC20 presale and exchange.
2. Body Without Organs: ERC1155 collectibles. Unique Hearts and limited addition badges.
3. Desiring Machine: [BitsForAi](http://bitsforai.com "BitsForAi") staking.
4. Autocatalysis: Biffy's governance is turned over to a DAO for further improvements.

### Phase 1: Mechanomics
#### Bastet's Invocation
- Approved addresses only, not available to public.
- Love distributed to participants proportional to their offerings.
- 100% of Ether offerings back the Bastet Exchange token bonding curve.
- 45m total Love.
- 4 Ether/address max.

#### Bastet's Exchange
Bastet's Exchange utilizes a token bonding curve to reward early participants while maintaining price stability at high market cap.
- `p=c*sqrt(x)` bonding curve formula where `p` is Eth/token, `c` is steepness, `sqrt` is square root, and `x` is current supply.
- Bastet's Invocation sets `c` s.t. `c=E/((2/3)x*sqrt(x))` where `E` is the total ether in the contract.
- New token issues (max 4m/30 days) update `c` s.t. `c'=E/((2/3)x'*sqrt(x'))` where `x'` is the new token quantity.
- Ether/Love dynamic rate of `dE=(2/3)*c*x'*sqrt(x')-(2/3)*c*x*sqrt(x)` where `dE` is change in total Ether in contract and `x'-x` is change in total Love.
- 0.0% fees forever.

### Phase 2: Body Without Organs
#### Heart Competitions
- 1 Heart given every 7 days to the contestant who gave the highest Love sacrifice that week.
- 90% of Love sacrificed to compete for a Heart is burned permanently.
- 10% sent to developer.
- Sacrifice bonus of `sqrt(x)` from all previous sacrifices (additive).
- 10k minimum Love sacrifice.
- Multiple sacrifices during the 7 day contest period are additive but do not roll over to the next week.
#### Biffy's Badges
- Limited series artworks attained through completing certain actions.
- Total Love in account.
- Total number of Hearts in account.
- Total Love sacrificed.
- Total Heart competitions joined.
- Length of time Bits staked.
- Size of staking bonuses.
- Total Bits staked.

### Phase 3: Desiring Machine
#### BitsForAi Staking
- 1500 Love per Bits staked.
Quantity bonuses:
- +5% if 50% of all Bits staked.
- +5% if 75% of all Bits staked.
- +10% if 90% of all Bits staked.
- +10% if 100% of all Bits staked.
Collection Bonuses (1x per collection):
- +100% Panda King (10x Pandas)
- +333% Triple Blue (3x Blue Legend)
- +12% Low Boys (10x under ID 1000)
- +34% Super Low Boys (10x under ID 100)
- +888% Full Gold (8x each with either gold foreground, background, or spot)
- +808% Rainbow (5x with every color, (BW, Blue, Red, Green, Gold) in every slot)
- +999% 21 Rare Club (21x, all rare)
- +555% Easy Being Green (5x each with either green foreground, background, or spot)
- +2500% Legendary Founder (1x under 10)
- +22% Old Boys (2x over ID 2000)
Collection Combo Bonuses (added to all staked bits in staker's account)
- +10% Double (2x unique collections)
- +20% Triple (3x unique collections)
- +50% Halfway (5x unique collections)
- +100% Almost (8x unique collections)
- +250% Perfectionist (10x unique collections)
Metaglitch bonus:
- +100% to Bits with an attached MetaGlitch
Decay
- -5%/day to unclaimed staking rewards.

### Phase 4: Autocatalysis
Biffy's contracts are all upgradeable (openzeppelin proxies). At this stage, Biffy will be acquired by a mission-aligned DAO that agrees to develop Biffy further in exchange for Love.


## Links
[Discord](https://discord.gg/2upQM7 "Discord")
[Website](https://biffy.ai/ "Biffy.ai")
