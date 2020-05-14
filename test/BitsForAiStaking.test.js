const { accounts, contract, web3 } = require("@openzeppelin/test-environment")
const { expectRevert, time, BN } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")
const config = require("../config")

const SECONDS_PER_DAY = 86400
const daysCount = 10

const ethereal = accounts[0] //admin
const stakers = [
  accounts[1],
  accounts[2],
  accounts[3],
  accounts[4]
]
const approvedOperator = accounts[5]
const unauthorizerOperator = accounts[6]
const bitsForAiTokenIdMocks = [
  [stakers[0],0],
  [stakers[0],1],
  [stakers[0],2],
  [stakers[1],3],
  [stakers[2],4],
  [stakers[3],5],
  [stakers[0],6],
  [stakers[1],7],
  [stakers[2],8],
  [stakers[3],9],
  [stakers[1],10],
  [stakers[2],11],
  [stakers[3],12],
  [stakers[1],13],
  [stakers[2],14],
  [stakers[3],15],
  [stakers[1],16],
  [stakers[0],17]
]

const BiffyLovePoints = contract.fromArtifact("BiffyLovePoints")
const BitsForAi = contract.fromArtifact("MockBitsForAi")
const LoveCycle = contract.fromArtifact("LoveCycle")

const BitsForAiStaking = contract.fromArtifact("BitsForAiStaking")


describe("BitsForAiStaking",function() {
  before(async function () {
    await Promise.all([
      (async () => {
        const p = config.InitializationBiffyLovePoints
        this.biffyLovePoints = await BiffyLovePoints.new()
        await this.biffyLovePoints.initialize(p.name,p.symbol,p.decimals, [ethereal], [ethereal])
      })(),
      (async () => {
        this.bitsForAi = await BitsForAi.new()
        await this.bitsForAi.initialize("BitsForAi", "BFA", [ethereal], [ethereal])
        await Promise.all(
          bitsForAiTokenIdMocks.map(
            tokenMock => this.bitsForAi.mintWithTokenURI(tokenMock[0],tokenMock[1],"",{from: ethereal})
          )
        )
      })(),
      (async () => {
        await time.advanceBlock()
        let latest = await time.latest()
        this.startTime = (30-daysCount)*SECONDS_PER_DAY + latest.toNumber()
        this.loveCycle = await LoveCycle.new()
        await this.loveCycle.initialize(this.startTime)
      })()
    ])

    const p = config.InitializationBitsForAiStaking
    this.bitsForAiStaking = await BitsForAiStaking.new({from: ethereal})
    await this.bitsForAiStaking.initialize(
      this.biffyLovePoints.address,
      this.bitsForAi.address,
      this.loveCycle.address,
      p.rewardBase,
      p.rewardBpOfTotalBlp,
      p.rewardDecayBP,
      {from: ethereal}
    )

    await this.biffyLovePoints.addMinter(this.bitsForAiStaking.address,{from: ethereal})
  })
  describe("State: Cycle 0",function() {
    it("should exist",function() {
      expect(this.bitsForAiStaking).to.not.equal(undefined)
    })
    describe("#totalStakingShares",function() {
      it("should be 0", async function () {
        let totalStakingShares = (await this.bitsForAiStaking.totalStakingShares()).toNumber()
        expect(totalStakingShares).to.equal(0)
      })
    })
    describe("#totalStakingNew",function() {
      it("should be 0", async function () {
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(0)
      })
    })
    describe("#totalStaking",function() {
      it("should be 0", async function () {
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(0)
      })
    })
    describe("#stakeForBiffysCollection",function() {
      it("should revert with an unowned token id", async function () {
        await expectRevert(
          this.bitsForAiStaking.stakeForBiffysCollection([16],{from: stakers[0]}),
          "Bits not owned by sender."
        )
      })
      it("should revert with any unowned token ids", async function () {
        await expectRevert(
          this.bitsForAiStaking.stakeForBiffysCollection([0,1,2,3],{from: stakers[0]}),
          "Bits not owned by sender."
        )
      })
      it("should succeed when owned token ids sent from staker", async function () {
        await this.bitsForAiStaking.stakeForBiffysCollection([0,1,2,6],{from: stakers[0]})
      })
    })
    describe("#claimBiffysLove",function() {
      it("should revert when no Bits by anyone are staked in last cycle.", async function () {
        await expectRevert(
          this.bitsForAiStaking.claimBiffysLove([0,1,2],{from: stakers[0]}),
          "Must have at least 1 Bits eligible to calculate rewards."
        )
      })
    })
    describe("#unstake",function() {
      it("should revert if any are not owned", async function () {
        await expectRevert(
          this.bitsForAiStaking.unstake([[1,14]],{from:stakers[0]}),
          "Sender can only unstake own staked Bits."
        )
      })
      it("should revert if any are not staked", async function () {
        await expectRevert(
          this.bitsForAiStaking.unstake([[1,17]],{from:stakers[0]}),
          "Sender can only unstake own staked Bits."
        )
      })
      it("should successfully unstake owned Bits current staked", async function () {
        await this.bitsForAiStaking.unstake([1],{from:stakers[0]})
      })
    })
    describe("#stakingPoolSize",function() {
      it("should be rewardBase ("+config.InitializationBitsForAiStaking.rewardBase.toString()+") when no BLP minted", async function () {
        let stakingPoolSize = await this.bitsForAiStaking.stakingPoolSize()
        expect(stakingPoolSize.toString()).to.equal(config.InitializationBitsForAiStaking.rewardBase.toString())

      })
    })
    describe("#stakingRewardPerBits",function() {
      it("should revert", async function () {
        await expectRevert(
          this.bitsForAiStaking.stakingRewardPerBits(),
          "Must have at least 1 Bits eligible to calculate rewards."
        )
      })
    })
    describe("#checkIfRewardAvailable",function() {
      it("should return false when LoveCycle has not started.", async function () {
        let isRewardAvailable = await this.bitsForAiStaking.checkIfRewardAvailable(0)
        expect(isRewardAvailable).to.equal(false)
      })
    })
    describe("#unstakeTransferred",function() {
      it("should revert on unstaked token.", async function () {
        expectRevert(
          this.bitsForAiStaking.unstakeTransferred([5]),
          "The token must not be currently staked."
        )
      })
      it("should revert for held staked token", async function () {
        await expectRevert(
          this.bitsForAiStaking.unstakeTransferred([2]),
          "The staker has not broken their promise and still holds the Bits."
        )
      })
      it("should revert for transferred staked token if other tokens are not transferred.", async function () {
        await this.bitsForAi.safeTransferFrom(stakers[0],stakers[1],2,{from: stakers[0]})
        expectRevert(
          this.bitsForAiStaking.unstakeTransferred([0,2]),
          "The staker has not broken their promise and still holds the Bits."
        )
      })
      it("should succeed for transferred token.", async function () {
        await this.bitsForAiStaking.unstakeTransferred([2])
      })
    })
    describe("#totalStakingNew: Post new add",function() {
      it("should be 2", async function () {
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(2)
      })
    })
  })
  describe("State: Cycle 1, day 0",function() {
    before(async function () {
      await time.advanceBlock()
      let latest = await time.latest()
      await time.increase(
        this.startTime - latest + 1
      )
      await time.advanceBlock()
    })
    describe("#updateTotalStakingPreviousCycles",function() {
      it("should succeed", async function () {
        await this.bitsForAiStaking.updateTotalStakingPreviousCycles()
      })
    })
    describe("#totalStakingNew",function() {
      it("should be 0", async function () {
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(0)
      })
    })
    describe("#totalStakingShares",function() {
      it("should be 2", async function () {
        let totalStakingShares = (await this.bitsForAiStaking.totalStakingShares()).toNumber()
        expect(totalStakingShares).to.equal(2)
      })
    })
    describe("#stakeForBiffysCollection",function() {
      it("should increase totalStakingNew by one and leave totalstaking unchanged when adding new token", async function () {
        await this.bitsForAiStaking.stakeForBiffysCollection([3],{from:stakers[1]})
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(2)
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(1)
      })
      it("should not change totalStakingNew and leave totalstaking unchanged when restaking newly staked token", async function () {
        await this.bitsForAiStaking.stakeForBiffysCollection([3],{from:stakers[1]})
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(2)
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(1)
      })
      it("should increment totalStakingNew and reduce totalstaking by one when restaking old staked token", async function () {
        let cycleStarted = (await this.bitsForAiStaking.bfaCycleStakingStarted(6)).toNumber()
        expect(cycleStarted).to.equal(0)
        await this.bitsForAiStaking.stakeForBiffysCollection([6],{from:stakers[0]})
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(1)
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(2)
      })
      it("should increment totalStakingNew and leave totalstaking unchanged by one when staking new tokens", async function () {
        await this.bitsForAiStaking.stakeForBiffysCollection([4,8,11,14],{from:stakers[2]})
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(1)
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(6)
      })
      it("should allow staking unstaked token from unstakedTransferred", async function () {
        await this.bitsForAiStaking.stakeForBiffysCollection([2],{from:stakers[1]})
        let totalStaking = (await this.bitsForAiStaking.totalStaking()).toNumber()
        expect(totalStaking).to.equal(1)
        let totalStakingNew = (await this.bitsForAiStaking.totalStakingNew()).toNumber()
        expect(totalStakingNew).to.equal(7)
      })
    })
    describe("#stakingRewardPerBits",function() {
      it("should return rewardBase/2 when 2 bit shares staked and no BLP issued.", async function () {
        let stakingRewardPerBits = await this.bitsForAiStaking.stakingRewardPerBits()
        expect(stakingRewardPerBits.toString()).to.equal(config.InitializationBitsForAiStaking.rewardBase.div(new BN(2)).toString())
      })
    })
    describe("#checkIfRewardAvailable",function() {
      it("should return false for token that was never staked", async function () {
        let isRewardAvailable = await this.bitsForAiStaking.checkIfRewardAvailable(15)
        expect(isRewardAvailable).to.equal(false)
      })
      it("should return false for token that was unstaked", async function () {
        let isRewardAvailable = await this.bitsForAiStaking.checkIfRewardAvailable(2)
        expect(isRewardAvailable).to.equal(false)
      })
      it("should return false for token that was restaked", async function () {
        let isRewardAvailable = await this.bitsForAiStaking.checkIfRewardAvailable(6)
        expect(isRewardAvailable).to.equal(false)
      })
      it("should return true for token that was staked and has not been claimed", async function () {
        let isRewardAvailable = await this.bitsForAiStaking.checkIfRewardAvailable(0)
        expect(isRewardAvailable).to.equal(true)
      })
    })
    describe("#claimBiffysLove",function() {
      it("should revert when claiming newly staked token", async function () {
        await expectRevert(
          this.bitsForAiStaking.claimBiffysLove([6],{from: stakers[0]}),
          "Bits must have an unclaimed Love reward."
        )
      })
      it("should revert for staked token not owned by sender", async function () {
        await expectRevert(
          this.bitsForAiStaking.claimBiffysLove([3],{from: stakers[0]}),
          "Bits not staked by sender."
        )
      })
      it("should increase stakers account by stakingRewardPerBits", async function () {
        await this.bitsForAiStaking.claimBiffysLove([0],{from: stakers[0]})
        let stakingRewardPerBits = await this.bitsForAiStaking.stakingRewardPerBits()
        let blpHeld = await this.biffyLovePoints.balanceOf(stakers[0])
        expect(blpHeld.toString()).to.equal(stakingRewardPerBits.toString())
      })
      it("should revert once staking reward is claimed.", async function () {
        await expectRevert(
          this.bitsForAiStaking.claimBiffysLove([0],{from: stakers[0]}),
          "Bits must have an unclaimed Love reward."
        )
      })
    })
  })
})
