const { network } = require('hardhat')

const reset = async (forking) => {
  const params = forking ? [{ forking }] : []
  await network.provider.request({
    method: 'hardhat_reset',
    params,
  })
}

class SnapshotManager {
  snapshots = {}

  async take() {
    const id = await this.takeSnapshot()
    this.snapshots[id] = id
    return id
  }

  async revert(id) {
    await this.revertSnapshot(this.snapshots[id])
    this.snapshots[id] = await this.takeSnapshot()
  }

  async takeSnapshot() {
    return await network.provider.request({
      method: 'evm_snapshot',
      params: [],
    })
  }

  async revertSnapshot(id) {
    await network.provider.request({
      method: 'evm_revert',
      params: [id],
    })
  }
}

module.exports = {
  snapshot: new SnapshotManager(),
  reset,
}
