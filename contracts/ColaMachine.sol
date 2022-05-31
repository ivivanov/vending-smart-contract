//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/PullPayment.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './IColaMachine.sol';
import './Operated.sol';
import './SpaceCola.sol';
import './TotalCounters.sol';

/**
 * @dev Cola Machine is a contract that implements the {IColaMachine} interface.
 */
contract ColaMachine is Operated, TotalCounters, PullPayment, ReentrancyGuard, IColaMachine {
  using SafeMath for uint256;

  uint8 public constant MAX_CAPACITY = 20; // Max amount of bottles tokens held in the contract
  uint8 public constant PERCENT_BASE = 100; // Divisor when calculating the discount %
  uint8 public constant RETURN_BOTTLE_DISCOUNT = 50; // 50%
  uint8 public constant BULK_ORDER_DISCOUNT = 15; // 15%
  uint8 public constant ONE_BOTTLE = 1; // Token equivalent of 1 bottle
  uint8 public constant FIVE_BOTTLES = ONE_BOTTLE * 5; // Token equivalent of 5 bottles

  address public immutable spaceCola;
  address public immutable daiToken;

  uint256 public price; // Bottle price in ETH
  uint256 public priceDAI; // Bottle price in DAI

  mapping(address => uint256) public addressToBottlesReturned;

  /**
   * @dev Sets the values for space cola address and initial price of the {SpaceCola} token.
   * See {SpaceCola-constructor}.
   */
  constructor(
    address _spaceCola,
    address _daiToken,
    uint256 initialPrice
  ) {
    require(_spaceCola != address(0), 'ColaM: spaceCola is the zero address');
    require(_daiToken != address(0), 'ColaM: daiToken is the zero address');

    spaceCola = _spaceCola;
    daiToken = _daiToken;
    price = initialPrice;
    priceDAI = 18 ether; // Random number just for POC
  }

  /**
   * @dev Restricts a function so it can only be executed when there is enough stock available.
   */
  modifier minStock(uint8 amount) {
    require(_currentStock() >= amount, 'ColaM: not enough stock');
    _;
  }

  /**
   * @dev See {IColaMachine-buyBottle}.
   * Will do {RETURN_BOTTLE_DISCOUNT} when the buyer has returned bottles.
   * Throws if sent ETH does not match exactly the price with/without discount.
   */
  function buyBottle() external payable override nonReentrant minStock(ONE_BOTTLE) {
    require(msg.value == _calc1BottlePrice(price), 'ColaM: eth does not match the price');

    _finalizeBuy(ONE_BOTTLE);
  }

  /**
   * @dev See {IColaMachine-buyBottleDAI}.
   * Will do {RETURN_BOTTLE_DISCOUNT} when the buyer has returned bottles.
   * Throws if sent ETH does not match exactly the price with/without discount.
   */
  function buyBottleDAI(uint256 amount) external override nonReentrant minStock(ONE_BOTTLE) {
    uint256 actualPrice = _calc1BottlePrice(priceDAI);
    require(amount == actualPrice, 'ColaM: DAI amount does not match the price');

    bool success = IERC20(daiToken).transferFrom(msg.sender, _myAddress(), actualPrice);
    if (!success) revert FailedTransfer();

    _finalizeBuy(ONE_BOTTLE);
  }

  /**
   * @dev See {IColaMachine-buy5Bottles}.
   *
   * Will apply always {BULK_ORDER_DISCOUNT} discount.
   *
   * Throws if sent ETH does not match exactly the price.
   */
  function buy5Bottles() external payable override nonReentrant minStock(FIVE_BOTTLES) {
    require(msg.value == _calc5BottlesPrice(), 'ColaM: eth does not match the price');

    _finalizeBuy(FIVE_BOTTLES);
  }

  /**
   * @dev See {IColaMachine-returnBottle}.
   *
   * Returned bottle tokens are burned.
   */
  function returnBottle() external override {
    SpaceCola(spaceCola).burnFrom(msg.sender, ONE_BOTTLE);
    addressToBottlesReturned[msg.sender]++;

    emit BottleReturned(msg.sender);
  }

  /**
   * @dev See {IColaMachine-getTotalSold}.
   *
   * Returns all bottles sold. Access is restricted to operators only.
   */
  function getTotalSold() external view override onlyOperator returns (uint256) {
    return _getTotal();
  }

  /**
   * @dev See {IColaMachine-restock}.
   *
   * Access is restricted to operators only. Throws if the new capacity is greater then the allowed max capacity.
   */
  function restock(uint8 amount) external override onlyOperator nonReentrant {
    require(MAX_CAPACITY >= _currentStock() + amount, 'ColaMAdmin: restock amount above max');

    SpaceCola(spaceCola).mint(_myAddress(), amount);

    emit Restocked();
  }

  /**
   * @dev See {IColaMachine-setPrice}.
   *
   * Access is restricted to operators only. Throws if the current stock is not 0.
   */
  function setPrice(uint256 newPrice) external override onlyOperator nonReentrant {
    require(_currentStock() == 0, 'ColaMAdmin: setting price when stock is not 0');

    price = newPrice;

    emit PriceChanged(newPrice);
  }

  /**
   * @dev See {IColaMachine-prepareWithdrawal}.
   *
   * Refer to {PullPayment} from openZeppelin's contracts. To finalize the withdrawal {withdrawPayments} should be called after the {prepareWithdrawal}.
   *
   * Access is restricted to operators only.
   */
  function prepareWithdrawal() external override onlyOperator nonReentrant {
    _asyncTransfer(msg.sender, _myAddress().balance);

    emit ReadyToWithdraw(msg.sender, _myAddress().balance);
  }

  /**
   * @dev Transfer all DAI from this contract to address of the caller.
   *
   * Emits Transfer event. See {ERC20-_transfer}
   *
   * Access is restricted to operators only.
   */
  function withdrawDAI() external override onlyOperator nonReentrant {
    IERC20 daiContract = IERC20(daiToken);
    bool success = daiContract.transfer(msg.sender, daiContract.balanceOf(_myAddress()));
    if (!success) revert FailedTransfer();
  }

  /**
   * @dev Sends Cola tokens to the payee.
   *
   * Emits BottleBought event if successful.
   */
  function _finalizeBuy(uint8 amount) private {
    require(amount > 0, 'ColaM: buying zero amount');

    if (amount == ONE_BOTTLE && _hasReturnedBottles()) {
      addressToBottlesReturned[msg.sender]--;
    }

    bool success = SpaceCola(spaceCola).transfer(msg.sender, amount);
    if (!success) revert FailedTransfer();

    _incrementCounters(amount);

    emit BottleBought(msg.sender, amount);
  }

  function _calc5BottlesPrice() private view returns (uint256) {
    return _calcPrice(price, FIVE_BOTTLES, BULK_ORDER_DISCOUNT);
  }

  function _calc1BottlePrice(uint256 basePrice) private view returns (uint256) {
    return _hasReturnedBottles() ? _calcPrice(basePrice, ONE_BOTTLE, RETURN_BOTTLE_DISCOUNT) : basePrice;
  }

  function _calcPrice(
    uint256 _price,
    uint8 amount,
    uint8 discount
  ) private pure returns (uint256) {
    return discount == 0 ? _price.mul(amount) : _price.mul(amount).mul(discount).div(PERCENT_BASE);
  }

  function _hasReturnedBottles() private view returns (bool) {
    return addressToBottlesReturned[msg.sender] > 0;
  }

  function _currentStock() private view returns (uint256) {
    return SpaceCola(spaceCola).balanceOf(_myAddress());
  }

  function _myAddress() private view returns (address) {
    return address(this);
  }
}
