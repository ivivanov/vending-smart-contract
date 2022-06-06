const { expect, assert } = require('chai')
const { ethers } = require('hardhat')
const { utils, BigNumber } = require('ethers')
const evm = require('./utils/evm.js')
const daiAbi = require('./abi/dai.json')

const FORK_BLOCK_NUMBER = 12314633

describe('ColaMachine contract', function () {
  const INITIAL_PRICE = utils.parseUnits('0.1', 'ether')
  const INITIAL_STOCK = 5

  let snapshotId

  // signers
  let deployer
  let randomUser

  // contracts
  let colaMachine
  let spaceCola
  let daiToken

  before(async () => {
    // forking ropsten
    await evm.reset({
      jsonRpcUrl: process.env.RPC_ROPSTEN,
      blockNumber: FORK_BLOCK_NUMBER,
    })

    // getting signers with ETH
    ;[deployer, randomUser] = await ethers.getSigners()

    // DAI contract on Ropsten
    daiToken = new ethers.Contract(process.env.DAI_TOKEN_ROPSTEN, daiAbi, deployer)

    // deploy contracts
    // precalculating SpaceCola's contract address as both ColaMachine contract and SpaceCola contract depend on one another
    const currentNonce = await ethers.provider.getTransactionCount(deployer.address)
    const spaceColaPrecalculatedAddress = utils.getContractAddress({ from: deployer.address, nonce: currentNonce + 1 })

    const colaMachineFactory = await ethers.getContractFactory('ColaMachine', deployer)
    colaMachine = await colaMachineFactory.deploy(spaceColaPrecalculatedAddress, process.env.DAI_TOKEN_ROPSTEN, INITIAL_PRICE)

    const spaceColaFactory = await ethers.getContractFactory('SpaceCola', deployer)
    spaceCola = await spaceColaFactory.deploy(colaMachine.address)

    // set initial stock of space cola tokens
    await colaMachine.restock(INITIAL_STOCK)

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
   * - Edge cases
   * - Test for common vulnerabilities
   */

  // * buyBottle tests
  // Emit event tests
  it('should emit BottleBought when buying bottle', async () => {
    await expect(colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE }))
      .to.emit(colaMachine, 'BottleBought')
      .withArgs(randomUser.address, 1)
  })

  // Function result tests
  it('should get SPC token when buying bottle', async () => {
    await colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE })
    expect(await spaceCola.balanceOf(randomUser.address)).to.be.eq(1)
  })

  it('should get SPC token when buying bottle on discounted price', async () => {
    await colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE })
    await spaceCola.connect(randomUser).increaseAllowance(colaMachine.address, 1)
    await colaMachine.connect(randomUser).returnBottle()

    const discount = await colaMachine.RETURN_BOTTLE_DISCOUNT()
    const price = calculateDiscount(discount, INITIAL_PRICE)
    await colaMachine.connect(randomUser).buyBottle({ value: price })

    expect(await spaceCola.balanceOf(randomUser.address)).to.be.eq(1)
  })

  // Ensure fail cases
  it('should revert for not enough stock when buying bottle', async () => {
    const discount = await colaMachine.BULK_ORDER_DISCOUNT()
    const price = calculateDiscount(discount, INITIAL_PRICE.mul(5))
    await colaMachine.connect(randomUser).buy5Bottles({ value: price })

    await expect(colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE })).to.be.revertedWith('ColaM: not enough stock')
  })

  it('should revert for not price mismatch when buying bottle', async () => {
    await expect(colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE.add(1) })).to.be.revertedWith(
      'ColaM: eth does not match the price'
    )
  })

  // * buy5Bottles tests
  // * returnBottle tests
  // * restock tests

  // ... etc

  // * prepareWithdrawal tests
  // Emit event tests
  it('should emit ReadyToWithdraw when preparing withdrawal', async () => {
    await expect(colaMachine.prepareWithdrawal()).to.emit(colaMachine, 'ReadyToWithdraw').withArgs(deployer.address, 0)
  })

  // Function result tests
  it('should be able to withdraw all contract balance', async () => {
    colaMachine.connect(randomUser).buyBottle({ value: INITIAL_PRICE })
    assert.isTrue((await ethers.provider.getBalance(colaMachine.address)).eq(INITIAL_PRICE))

    await colaMachine.prepareWithdrawal()
    const tx = await colaMachine.withdrawPayments(deployer.address)
    const rcpt = await tx.wait()
    const eventAbi = ['event Withdrawn(address indexed payee, uint256 weiAmount)']
    const iface = new hre.ethers.utils.Interface(eventAbi)

    expect(iface.parseLog(rcpt.events[0]).args.payee).to.be.eq(deployer.address)
    expect(iface.parseLog(rcpt.events[0]).args.weiAmount).to.be.eq(INITIAL_PRICE)
  })

  // Ensure fail cases
  // ...

  // * buyBottleDAI tests - just for POC
  it('should get SPC token when buying bottle with DAI', async () => {
    const priceDAI = await colaMachine.priceDAI()
    assert.isAbove(await daiToken.balanceOf(deployer.address), priceDAI)
    assert(await daiToken.balanceOf(colaMachine.address), 0)

    await daiToken.approve(colaMachine.address, priceDAI)
    await colaMachine.buyBottleDAI(priceDAI)

    expect(await spaceCola.balanceOf(deployer.address)).to.be.eq(1)
    expect(await daiToken.balanceOf(colaMachine.address)).to.be.eq(priceDAI)
  })

  // ...

  // * withdrawDAI tests - just for POC
  it('should withdraw all DAI tokens from the contract', async () => {
    const priceDAI = await colaMachine.priceDAI()
    const initialBalance = await daiToken.balanceOf(deployer.address)

    await daiToken.approve(colaMachine.address, priceDAI)
    await colaMachine.buyBottleDAI(priceDAI)

    assert(await daiToken.balanceOf(colaMachine.address), priceDAI)
    assert(await daiToken.balanceOf(deployer.address), initialBalance.add(priceDAI.mul(-1)))

    await colaMachine.withdrawDAI()
    expect(await daiToken.balanceOf(deployer.address)).to.be.eq(initialBalance)
  })

  // ...
})

const calculateDiscount = (discount, price) => {
  const percentBaseBn = BigNumber.from(100)
  return BigNumber.from(price).div(percentBaseBn).mul(BigNumber.from(discount))
}
