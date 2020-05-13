const { scripts, ConfigManager } = require('@openzeppelin/cli')
const { add, push, create } = scripts

async function deploy(options) {
  add({ contractsData: [{ name: 'BiffyHearts', alias: 'BiffyHearts' }] })
  await push(options);
  await create(Object.assign({ contractAlias: 'BiffyHearts' }, options))
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: accounts[0] })
    await deploy({ network, txParams })
  })
}
