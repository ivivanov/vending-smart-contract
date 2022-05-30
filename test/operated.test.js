const { expect, assert } = require('chai')
const { ethers } = require('hardhat')
const { utils, constants } = require('ethers')
const evm = require('./utils/evm.js')

const FORK_BLOCK_NUMBER = 12314633

describe('Operated abstract contract', function () {
  const INITIAL_PRICE = utils.parseUnits('0.1', 'ether')
  const MAX_OPERATORS = 3
  const AddressZero = constants.AddressZero

  let snapshotId

  // signers
  let deployer
  let rn1

  // contracts
  let colaMachine

  before(async () => {
    // forking ropsten
    await evm.reset({
      jsonRpcUrl: process.env.RPC_ROPSTEN,
      blockNumber: FORK_BLOCK_NUMBER,
    })

    // getting signers with ETH
    ;[deployer, rn1, rn2, rn3] = await ethers.getSigners()

    // deploy contracts
    const colaMachineFactory = await ethers.getContractFactory('ColaMachine', deployer)
    colaMachine = await colaMachineFactory.deploy(AddressZero, AddressZero, INITIAL_PRICE)

    // snapshot
    snapshotId = await evm.snapshot.take()
  })

  beforeEach(async () => {
    await evm.snapshot.revert(snapshotId)
  })

  /**
   * Tests
   * - Success cases
   *  - Emit event tests
   *  - Function result tests
   * - Ensure fail cases
   * - Test for common vulnerabilities
   */

  // * addOperator tests
  // Emit event tests
  it('should emit OperatorAdded when adding new operator', async () => {
    await expect(colaMachine.addOperator(rn1.address)).to.emit(colaMachine, 'OperatorAdded').withArgs(rn1.address)
  })

  // Function result tests
  it('should increase operators counter when adding new operator', async () => {
    assert.equal(await colaMachine.getOperatorsCount(), 1)

    await colaMachine.addOperator(rn1.address)

    expect(await colaMachine.getOperatorsCount()).to.be.eq(2)
  })

  // Ensure fail cases
  it('should revert when adding new operator with senders address', async () => {
    await expect(colaMachine.addOperator(deployer.address)).to.be.revertedWith('Operated: new address can not be sender')
  })

  it('should revert when adding new operator and max number of operators is reached', async () => {
    await colaMachine.addOperator(rn1.address)
    await colaMachine.addOperator(rn2.address)
    assert.equal(await colaMachine.getOperatorsCount(), MAX_OPERATORS)

    await expect(colaMachine.addOperator(rn3.address)).to.be.revertedWith('Operated: max operators reached')
  })

  // * removeOperator tests
})
