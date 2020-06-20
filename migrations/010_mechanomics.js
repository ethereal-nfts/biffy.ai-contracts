const { scripts, ConfigManager } = require("@openzeppelin/cli")
const { add, push, create } = scripts

const config = require("../config")

const BiffyLovePoints = artifacts.require("BiffyLovePoints")
const BastetsExchange = artifacts.require("BastetsExchange")

async function deploy(options) {
  add({ contractsData: [{ name: "BiffyLovePoints", alias: "BiffyLovePoints" },{ name: "BastetsExchange", alias: "BastetsExchange" }] })
  await push(options)
  await create(Object.assign({ contractAlias: "BiffyLovePoints" }, options))
  await create(Object.assign({ contractAlias: "BastetsExchange" }, options))
}

async function initialize(accounts) {
  const loveParams = config.InitializationBiffyLovePoints
  const biffyLovePoints = await BiffyLovePoints.deployed()
  await biffyLovePoints.initialize(
    loveParams.name,
    loveParams.symbol,
    loveParams.decimals,
    loveParams.minters.map((index)=>accounts[index]),
    loveParams.pausers.map((index)=>accounts[index])
  )

  const bastetParams = config.InitalizationBastetsExchange
  const bastetsExchange = await BastetsExchange.deployed()

  await biffyLovePoints.addMinter(bastetsExchange.address)

  await bastetsExchange.initialize(
    biffyLovePoints.address,
    bastetParams.invokerMaxEtherOffering,
    bastetParams.invocationLove,
    bastetParams.invocationEndTime
  )


}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams })
    await initialize(accounts)
  })
}
