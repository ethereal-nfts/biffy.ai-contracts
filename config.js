const { ether } = require("@openzeppelin/test-helpers")

let config = {}

config.InitializationBiffyLovePoints = {
  name:"BiffyLovePoints",
  symbol:"BLP",
  decimals:18
}

config.InitializationBiffyHearts = {
  name:"BiffyHearts",
  symbol:"BHRT"
}

config.InitializationLoveCycle = {
  startTime: new Date("June 4, 2020, 00:00:00 UTC").getTime()/1000
}

config.InitializationBitsForAiStaking = {
  rewardBase: ether("90000000"),
  rewardBpOfTotalBlp: 9,
  rewardDecayBP: 500
}

module.exports = config
