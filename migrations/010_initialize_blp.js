const BiffyLovePoints = artifacts.require("BiffyLovePoints")
const config = require('../config')

module.exports = async function(deployer, networkName, accounts) {
  const p = config.InitializationBiffyLovePoints
  const biffyLovePoints = await BiffyLovePoints.deployed()
  await biffyLovePoints.initialize(
    p.name,
    p.symbol,
    p.decimals,
    p.minters.map((index)=>accounts[index]),
    p.pausers.map((index)=>accounts[index])
  )
}
