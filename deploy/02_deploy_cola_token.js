const { shouldVerifyContract } = require('../utils/deploy')

module.exports = async (hre) => {
  const { deployer } = await hre.getNamedAccounts()
  const colaMachine = await hre.deployments.get('ColaMachine')

  const contract = await hre.deployments.deploy('SpaceCola', {
    from: deployer,
    log: true,
    args: [colaMachine.address],
    skipIfAlreadyDeployed: true,
  })

  if (hre.network.name !== 'hardhat' && (await shouldVerifyContract(contract))) {
    await hre.run('verify:verify', {
      address: contract.address,
      constructorArguments: [colaMachine.address],
    })
  }
}

module.exports.tags = ['SpaceCola', 'Token', 'Bottle']
