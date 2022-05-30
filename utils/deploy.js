const { ethers } = require('hardhat')

module.exports = {
  shouldVerifyContract: async (deploy) => {
    if (process.env.FORK || process.env.TEST) return false
    if (!deploy.newlyDeployed) return false

    const txReceipt = await ethers.provider.getTransaction(deploy.receipt.transactionHash)
    await txReceipt.wait(5)

    return true
  },
}
