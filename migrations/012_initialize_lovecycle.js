const LoveCycle = artifacts.require("LoveCycle")
const config = require('../config')

module.exports = async function(deployer, networkName, accounts) {
  const p = config.InitializationLoveCycle

  console.log(p.startTime);

  const loveCycle = await LoveCycle.deployed()
  await loveCycle.initialize(p.startTime)
}
