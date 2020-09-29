const { ether, BN } = require("@openzeppelin/test-helpers");

let config = {};

config.timer = {
  startTime: 1598543940,
  hardCapTimer: 172800,
  softCap: ether("500"),
};

config.redeemer = {
  redeemBP: 200,
  redeemInterval: 3600,
  bonusRangeStart: [
    ether("0"),
    ether("20"),
    ether("60"),
    ether("140"),
    ether("300"),
    ether("620"),
    ether("1260"),
    ether("2540")
  ],
  bonusRangeBP: [
    5000,
    4000,
    3000,
    2000,
    1000,
    500,
    250,
    0
  ],
};

config.presale = {
  maxBuyPerAddress: ether("25"),
  maxBuyWithoutWhitelisting: ether("25"),
  uniswapEthBP: 7500,
  lidEthBP: 500,
  referralBP: 250,
  hardcap: ether("3322"),
  token: "0xBa21Ef4c9f433Ede00badEFcC2754B8E74bd538A",
  uniswapRouter: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  lidFund: "0xb63c4F8eCBd1ab926Ed9Cb90c936dffC0eb02cE2",
  uniswapTokenBP: 2500,
  presaleTokenBP: 3800,
  tokenDistributionBP: {
    team: 700,
    dev: 1300,
    staking: 1300,
    marketing: 1300,
  },
};

module.exports = config;
