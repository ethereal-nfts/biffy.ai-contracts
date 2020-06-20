const { accounts, contract, web3 } = require("@openzeppelin/test-environment")
const { expectRevert, time, BN, ether } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")
const config = require("../config")

const BiffyLovePoints = contract.fromArtifact("BiffyLovePoints")
const BastetsExchange = contract.fromArtifact("BastetsExchange")


const ethereal = accounts[0] //admin
const whitelist = [
  accounts[1],
  accounts[2],
  accounts[3],
  accounts[4]
]
const traders = [
  accounts[5],
  accounts[6]
]
const nonWhitelist = accounts[7]

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
    })
  })
})
