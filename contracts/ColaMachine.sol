//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/PullPayment.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './IColaMachine.sol';
import './Operated.sol';
import './SpaceCola.sol';

/**
 * @dev Cola Machine is a contract that implements the {IColaMachine} interface.
 */
contract ColaMachine is Operated, PullPayment, ReentrancyGuard, IColaMachine {
  using SafeMath for uint256;

  address public immutable spaceCola;

  uint8 public constant MAX_CAPACITY = 20; // Max amount of bottles tokens held in the contract
  uint8 public constant PERCENT_BASE = 100; // Divisor when calculating the discount %
  uint8 public constant RETURN_BOTTLE_DISCOUNT = 50; // 50%
  uint8 public constant BULK_ORDER_DISCOUNT = 15; // 15%
  uint8 public constant ONE_BOTTLE = 1; // Token equivalent of 1 bottle
  uint8 public constant FIVE_BOTTLES = ONE_BOTTLE * 5; // Token equivalent of 5 bottles

  mapping(address => uint256) public addressToBottlesBought;
  mapping(address => uint256) public addressToBottlesReturned;

  uint256 public price; // Bottle price in ETH

  uint256 private _totalSold;

  /**
   * @dev Sets the values for space cola address and initial price of the {SpaceCola} token.
   * See {SpaceCola-constructor}.
   */
  constructor(address _spaceCola, uint256 initialPrice) {
    spaceCola = _spaceCola;
    price = initialPrice;
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
   *
   * Will do {RETURN_BOTTLE_DISCOUNT} when the buyer has returned bottles. Throws if sent ETH does not match exactly the price with or without discount.
   */
  function buyBottle() external payable override nonReentrant minStock(1) {
    (uint256 actualPrice, bool isDiscounted) = _calc1BottlePrice();
    require(msg.value == actualPrice, 'ColaM: eth does not match the price');

    if (isDiscounted) {
      addressToBottlesReturned[msg.sender]--;
    }

    SpaceCola(spaceCola).transfer(msg.sender, ONE_BOTTLE);
    _incrementSoldCounters(ONE_BOTTLE);

    emit BottleBought(msg.sender, ONE_BOTTLE);
  }

  /**
   * @dev See {IColaMachine-buy5Bottles}.
   *
   * Will do {BULK_ORDER_DISCOUNT} discount. Throws if sent ETH does not match exactly the price.
   */
  function buy5Bottles() external payable override nonReentrant minStock(5) {
    require(msg.value == _calc5BottlesPrice(), 'ColaM: eth does not match the price');

    SpaceCola(spaceCola).transfer(msg.sender, FIVE_BOTTLES);
    _incrementSoldCounters(FIVE_BOTTLES);

    emit BottleBought(msg.sender, FIVE_BOTTLES);
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
    return _totalSold;
  }

  /**
   * @dev See {IColaMachine-restock}.
   *
   * Access is restricted to operators only. Throws if the new capacity is greater then the allowed max capacity.
   */
  function restock(uint8 amount) external override onlyOperator nonReentrant {
    require(MAX_CAPACITY >= _currentStock() + amount, 'ColaMAdmin:: restock amount above max');

    SpaceCola(spaceCola).mint(_myAddress(), amount);

    emit Restocked();
  }

  /**
   * @dev See {IColaMachine-setPrice}.
   *
   * Access is restricted to operators only. Throws if the current stock is not 0.
   */
  function setPrice(uint256 newPrice) external override onlyOperator nonReentrant {
    require(_currentStock() == 0, 'ColaMAdmin:: setting price when stock is not 0');

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

  function _calc5BottlesPrice() private view returns (uint256) {
    return price.mul(FIVE_BOTTLES).div(PERCENT_BASE).mul(BULK_ORDER_DISCOUNT);
  }

  function _calc1BottlePrice() private view returns (uint256 newPrice, bool isDiscounted) {
    isDiscounted = addressToBottlesReturned[msg.sender] > 0;
    newPrice = isDiscounted ? price.div(PERCENT_BASE).mul(RETURN_BOTTLE_DISCOUNT) : price;

    return (newPrice, isDiscounted);
  }

  function _currentStock() private view returns (uint256) {
    return SpaceCola(spaceCola).balanceOf(_myAddress());
  }

  function _incrementSoldCounters(uint256 amount) private {
    _totalSold += amount;
    addressToBottlesBought[msg.sender] += amount;
  }

  function _myAddress() private view returns (address) {
    return address(this);
  }
}
