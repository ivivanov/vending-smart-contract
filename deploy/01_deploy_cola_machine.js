const { utils } = require('ethers')
const { ethers } = require('hardhat')
const { shouldVerifyContract } = require('../utils/deploy')

module.exports = async (hre) => {
  const { deployer } = await hre.getNamedAccounts()
  const INITIAL_PRICE = utils.parseUnits('0.1', 'ether')
  const currentNonce = await ethers.provider.getTransactionCount(deployer)
  const spaceColaPrecalculatedAddress = utils.getContractAddress({ from: deployer, nonce: currentNonce + 1 })

  const contract = await hre.deployments.deploy('ColaMachine', {
    from: deployer,
    log: true,
    args: [spaceColaPrecalculatedAddress, INITIAL_PRICE],
    skipIfAlreadyDeployed: true,
  })

  if (hre.network.name !== 'hardhat' && (await shouldVerifyContract(contract))) {
    await hre.run('verify:verify', {
      address: contract.address,
      constructorArguments: [spaceColaPrecalculatedAddress, INITIAL_PRICE],
    });
  }
}

module.exports.tags = ['ColaMachine', 'Machine', 'Vending']
