const BiffyHearts = artifacts.require("BiffyHearts")
const config = require('../config')

module.exports = async function(deployer, networkName, accounts) {
  const p = config.InitializationBiffyHearts

  const biffyHearts = await BiffyHearts.deployed()
  await biffyHearts.initialize(
    accounts[p.sender],
    p.name,
    p.symbol,
    p.minters.map((index)=>accounts[index])
  )
}
