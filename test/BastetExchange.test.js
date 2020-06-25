const { accounts, contract, web3 } = require("@openzeppelin/test-environment")
const { expectRevert, time, BN, ether, balance } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")
const config = require("../config")

const BiffyLovePoints = contract.fromArtifact("BiffyLovePoints")
const BastetsExchange = contract.fromArtifact("BastetsExchange")


const ethereal = accounts[0] //admin
const whitelist = [
  accounts[1],
  accounts[2],
  accounts[3],
  accounts[4],
  accounts[5]
]
const traders = [
  accounts[6],
  accounts[7]
]
const nonWhitelist = accounts[8]

function sqrt_b (bignum) {
  let z = new BN(0)
  let y = bignum
  if(y.gt(new BN(3))) {
    z = y
    let x = y.div(new BN(2)).add(new BN(1))
    while(x.lt(z)) {
      z = x
      x = (y.div(x).add(x)).div(new BN(2))
    }
  } else {
    z = new BN(1)
  }
  return z
}

describe("BastetsExchange",function() {
  before(async function () {

    const pLove = config.InitializationBiffyLovePoints
    this.biffyLovePoints = await BiffyLovePoints.new()
    await this.biffyLovePoints.initialize(pLove.name, pLove.symbol, pLove.decimals, [ethereal], [ethereal])

    const pBastet = config.InitalizationBastetsExchange
    this.bastetsExchange = await BastetsExchange.new()

    await this.biffyLovePoints.addMinter(this.bastetsExchange.address,{from: ethereal})

    await this.bastetsExchange.initialize(
      this.biffyLovePoints.address,
      pBastet.invokerMaxEtherOffering,
      pBastet.invocationLove,
      pBastet.invocationEndTime
    )
  })


  describe("State: Invocation",function(){
    before(async function(){
      await this.bastetsExchange.addMultipleWhitelisted(whitelist)
    })
    describe("#invokeBastet",function() {
      it("should revert if sender not whitelisted", async function () {
        await expectRevert(
          this.bastetsExchange.invokeBastet({from:nonWhitelist}),
          "WhitelistedRole: caller does not have the Whitelisted role"
        )
      })
      it("should revert if more eth sent than cap", async function () {
        await expectRevert(
          this.bastetsExchange.invokeBastet({from:whitelist[0], value:config.InitalizationBastetsExchange.invokerMaxEtherOffering+1}),
          "Maximum offering exceeded."
        )
      })
      it("should revert if 0 eth sent", async function () {
        await expectRevert(
          this.bastetsExchange.invokeBastet({from:whitelist[0], value:0}),
          "Must send at least 1 wei."
        )
      })
      it("should increase invokerOffering[sender] by value", async function () {
        let invoker = whitelist[0]
        await this.bastetsExchange.invokeBastet({from:invoker, value:ether("2")})
        const firstInvokerOfferingResult = await this.bastetsExchange.invokerOffering(invoker)
        expect(ether("2").toString())
          .to.equal(firstInvokerOfferingResult.toString())
        await this.bastetsExchange.invokeBastet({from:invoker, value:config.InitalizationBastetsExchange.invokerMaxEtherOffering-ether("2")})
        const secondInvokerOfferingResult = await this.bastetsExchange.invokerOffering(invoker)
        expect(config.InitalizationBastetsExchange.invokerMaxEtherOffering.toString())
          .to.equal(secondInvokerOfferingResult.toString())
      })
      it("should increase totalInvokerOffering by value", async function () {
        let invoker = whitelist[1]
        const intitialTotalInvocationOffering = await this.bastetsExchange.totalInvocationOffering()
        await this.bastetsExchange.invokeBastet({from:invoker, value:ether("1.1")})
        const firstTotalInvocationOffering = await this.bastetsExchange.totalInvocationOffering()
        expect((firstTotalInvocationOffering-ether("1.1")).toString())
          .to.equal(intitialTotalInvocationOffering.toString())
        await this.bastetsExchange.invokeBastet({from:invoker, value:ether("1.13")})
        const secondTotalInvocationOffering = await this.bastetsExchange.totalInvocationOffering()
        expect((firstTotalInvocationOffering.add(ether("1.13"))).toString())
          .to.equal(secondTotalInvocationOffering.toString())
      })
    })
    describe("#claimInvocationLove",function() {
      it("should revert if not whitelisted", async function () {
        await expectRevert(
          this.bastetsExchange.claimInvocationLove({from:nonWhitelist}),
          "WhitelistedRole: caller does not have the Whitelisted role"
        )
      })
      it("should revert if bastet not invoked", async function () {
        await expectRevert(
          this.bastetsExchange.claimInvocationLove({from:whitelist[0]}),
          "Bastets Invocation has not yet finished."
        )
      })
    })
    describe("#sacrificeWeiForLove",function() {
      it("should revert if bastet not invoked", async function () {
        await expectRevert(
          this.bastetsExchange.sacrificeWeiForLove(ether("1")),
          "Bastets Invocation has not yet finished."
        )
      })
    })
    describe("#sacrificeLoveForWei",function() {
      it("should revert if bastet not invoked", async function () {
        await expectRevert(
          this.bastetsExchange.sacrificeLoveForWei(ether("1")),
          "Bastets Invocation has not yet finished."
        )
      })
    })
    describe("#magicNumber",function(){
      it("should be `E/((2/3)x*sqrt(x))` times the divisor", async function () {
        const magicNumberDivisor = await this.bastetsExchange.magicNumberDivisor()
        const etherBal = await balance.current(this.bastetsExchange.address)
        const love = await this.biffyLovePoints.totalSupply()
        const contractMagicNumber = await this.bastetsExchange.magicNumber()
        const calcMagicNumber =
          etherBal.mul(magicNumberDivisor).div(
            love.mul(new BN(2)).mul((sqrt_b(love))).div(new BN(3))
          )
        expect(contractMagicNumber.toString())
          .to.not.equal((new BN(0)).toString())
        expect(contractMagicNumber.toString())
          .to.equal(calcMagicNumber.toString())
      })
    })
    describe("#getWeiPerLove",function() {
      it("should be `c*sqrt(x)`", async function () {
        const magicNumber = await this.bastetsExchange.magicNumber()
        const love = await this.biffyLovePoints.totalSupply()
        const calcRate = magicNumber.mul(sqrt_b(love)).div(ether("1"))
        const contractRate = await this.bastetsExchange.getWeiPerLove()
        expect(contractRate.toString())
          .to.not.equal((new BN(0)).toString())
        expect(contractRate.toString())
          .to.equal(calcRate.toString())
      })
    })
    describe("#sendLoveEarnWeiAmt",function() {
      it("should be `dE=(2/3)*c*x*sqrt(x)-(2/3)*c*x'*sqrt(x')`", async function () {
        const dx = ether("4")
        const magicNumber = await this.bastetsExchange.magicNumber()
        const magicNumberDivisor = await this.bastetsExchange.magicNumberDivisor()
        const love = await this.biffyLovePoints.totalSupply()
        const finalLove = love.sub(dx)
        const dEtherCalc =
          magicNumber.mul(new BN(2)).mul(
            love.mul(sqrt_b(love)).sub(
              finalLove.mul(sqrt_b(finalLove))
            )
          ).div(new BN(3)).div(magicNumberDivisor)

        const dEtherContract = await this.bastetsExchange.sendLoveEarnWeiAmt(dx)
        expect(dEtherContract.toString())
          .to.not.equal((new BN(0)).toString())
        expect(dEtherContract.toString())
          .to.equal(dEtherCalc.toString())
      })
    })
    describe("#sendWeiEarnLoveAmt",function() {
      it("dE=(2/3)*c*x'*sqrt(x')-(2/3)*c*x*sqrt(x)`", async function () {
        const dx = ether("4")
        const magicNumber = await this.bastetsExchange.magicNumber()
        const magicNumberDivisor = await this.bastetsExchange.magicNumberDivisor()
        const love = await this.biffyLovePoints.totalSupply()
        const finalLove = love.add(dx)
        const dEtherCalc =
          magicNumber.mul(new BN(2)).mul(
            finalLove.mul(sqrt_b(finalLove)).sub(
              love.mul(sqrt_b(love))
            )
          ).div(new BN(3)).div(magicNumberDivisor)
        const dEtherContract = await this.bastetsExchange.sendWeiEarnLoveAmt(dx)
        expect(dEtherContract.toString())
          .to.not.equal((new BN(0)).toString())
        expect(dEtherContract.toString())
          .to.equal(dEtherCalc.toString())
      })
    })
  })
  describe("State: Exchange",function(){
    before(async function(){
      await Promise.all([
        this.bastetsExchange.invokeBastet({from:whitelist[2], value:ether("1")}),
        this.bastetsExchange.invokeBastet({from:whitelist[3], value:17}),
      ])
      await time.advanceBlock()
      let latest = await time.latest()
      let dTime = config.InitalizationBastetsExchange.invocationEndTime + 1 - latest
      await time.increase(dTime)
      await time.advanceBlock()
    })
    describe("#invokeBastet", function () {
      it("should revert", async function () {
        await expectRevert(
          this.bastetsExchange.invokeBastet({from:whitelist[0]}),
          "Bastets Invocation is complete."
        )
      })
    })
    describe("#claimInvocationLove",function () {
      it("should revert if invoker not whitelisted", async function () {
        await expectRevert(
          this.bastetsExchange.claimInvocationLove({from:nonWhitelist}),
          "WhitelistedRole: caller does not have the Whitelisted role"
        )
      })
      it("should revert if invoker never sent Ether", async function () {
        await expectRevert(
          this.bastetsExchange.claimInvocationLove({from:whitelist[4]}),
          "Invoker has no Love claim remaining."
        )
      })
      it("should increase invoker's Love by ratio of ether sent", async function () {
        const invoker = whitelist[0]
        const invokerOffering = await this.bastetsExchange.invokerOffering(invoker)
        const totalOffering = await this.bastetsExchange.totalInvocationOffering()
        const calcLove = invokerOffering.mul(config.InitalizationBastetsExchange.invocationLove).div(totalOffering)
        await this.bastetsExchange.claimInvocationLove({from:invoker})
        const contractLove = await this.biffyLovePoints.balanceOf(invoker)
        expect(contractLove.toString()).to.not.equal("0")
        expect(contractLove.toString())
          .to.equal(calcLove.toString())
      })
      it("should revert if invoker previously claimed.", async function () {
        await expectRevert(
          this.bastetsExchange.claimInvocationLove({from:whitelist[0]}),
          "Invoker has no Love claim remaining."
        )
      })
      it("should allow all invokers to withdraw their Love.", async function () {
        for(let i=1; i<4; i++){
          await this.bastetsExchange.claimInvocationLove({from:whitelist[i]})
        }
        const bastetLoveBalance = await this.biffyLovePoints.balanceOf(this.bastetsExchange.address)
        console.log(bastetLoveBalance.toString())
        expect(bastetLoveBalance.toNumber()).to.be.below(whitelist.length)
      })
    })
    describe("#sacrificeWeiForLove",function () {
      it("should revert if 0 Love requested.", async function() {
        await expectRevert(
          this.bastetsExchange.sacrificeWeiForLove("0",{from:nonWhitelist,value:ether("0")}),
          "Love must be at least 1 wei."
        )
      })
      it("should revert if less Ether sent than required", async function() {
        const loveAmount = ether("1.3")
        const requiredWei = await this.bastetsExchange.sendWeiEarnLoveAmt(loveAmount)
        let sub = 1
        await expectRevert(
          this.bastetsExchange.sacrificeWeiForLove(loveAmount,{from:nonWhitelist,value:requiredWei.sub(new BN(sub))}),
          "Must sacrifice enough Ether."
        )
        await expectRevert(
          this.bastetsExchange.sacrificeWeiForLove(loveAmount,{from:nonWhitelist,value:"1"}),
          "Must sacrifice enough Ether."
        )
      })
      //need additional tests
    })
  })
})
