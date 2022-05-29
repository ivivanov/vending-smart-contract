//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/PullPayment.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './IVendingMachine.sol';
import './Operated.sol';

contract VendingMachine is ERC20, Operated, PullPayment, ReentrancyGuard, IVendingMachine {
  using SafeMath for uint256;

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
   * @dev Sets the values for {name} and {symbol} of ERC20 token, the initial minted bottle tokens and the initial price per bottle.
   */
  constructor(
    uint256 initialStock,
    uint256 initialPrice,
    string memory name,
    string memory symbol
  ) ERC20(name, symbol) {
    require(MAX_CAPACITY >= initialStock, 'Vending: init with bad initial stock amount');
    _mint(address(this), initialStock);
    price = initialPrice;
  }

  /**
   * @dev Restricts a function so it can only be executed when there is enough stock available.
   */
  modifier minStock(uint8 amount) {
    require(_currentStock() >= amount, 'Vending: not enough stock');
    _;
  }

  /**
   * @dev Zero decimal precision ensures bottles are not divisible.
   */
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  /**
   * @dev See {IVendingMachine-buyBottle}.
   *
   * Will do {RETURN_BOTTLE_DISCOUNT} when the buyer has returned bottles. Throws if sent ETH does not match exactly the price with or without discount.
   */
  function buyBottle() external payable override nonReentrant minStock(1) {
    (uint256 actualPrice, bool isDiscounted) = _calc1BottlePrice();
    require(msg.value == actualPrice, 'Vending: eth does not match the price');

    if (isDiscounted) {
      addressToBottlesReturned[msg.sender]--;
    }

    transfer(msg.sender, ONE_BOTTLE);
    _incrementTotalSold(ONE_BOTTLE);

    emit BottleBought(msg.sender, ONE_BOTTLE);
  }

  /**
   * @dev See {IVendingMachine-buy5Bottles}.
   *
   * Will do {BULK_ORDER_DISCOUNT} discount. Throws if sent ETH does not match exactly the price.
   */
  function buy5Bottles() external payable override nonReentrant minStock(5) {
    require(msg.value == _calc5BottlesPrice(), 'Vending: eth does not match the price');

    transfer(msg.sender, FIVE_BOTTLES);
    _incrementTotalSold(FIVE_BOTTLES);

    emit BottleBought(msg.sender, FIVE_BOTTLES);
  }

  /**
   * @dev See {IVendingMachine-returnBottle}.
   *
   * Returned bottle tokens are burned.
   */
  function returnBottle() external override {
    ERC20Burnable(address(this)).burnFrom(msg.sender, ONE_BOTTLE);
    addressToBottlesReturned[msg.sender]++;

    emit BottleReturned(msg.sender);
  }

  /**
   * @dev See {IVendingMachine-getTotalSold}.
   *
   * Returns all bottles sold. Access is restricted to operators only.
   */
  function getTotalSold() external view override onlyOperator returns (uint256) {
    return _totalSold;
  }

  /**
   * @dev See {IVendingMachine-restock}.
   *
   * Access is restricted to operators only.
   */
  function restock(uint8 amount) external override onlyOperator nonReentrant {
    require(MAX_CAPACITY >= _currentStock() + amount, 'VMAdmin: restock amount above max');

    _mint(address(this), amount);

    emit Restocked();
  }

  /**
   * @dev See {IVendingMachine-setPrice}.
   *
   * Access is restricted to operators only.
   */
  function setPrice(uint256 newPrice) external override onlyOperator nonReentrant {
    require(_currentStock() == 0, 'VMAdmin: setting price when stock is not 0');

    price = newPrice;

    emit PriceChanged(newPrice);
  }

  /**
   * @dev See {IVendingMachine-prepareWithdrawal}.
   *
   * Refer to {PullPayment} from openZeppelin's contracts. To finalize the withdrawal {withdrawPayments} should be called after the {prepareWithdrawal}.
   *
   * Access is restricted to operators only.
   */
  function prepareWithdrawal() external override onlyOperator nonReentrant {
    _asyncTransfer(msg.sender, address(this).balance);

    emit ReadyToWithdraw(msg.sender, address(this).balance);
  }

  function _calc5BottlesPrice() private view returns (uint256) {
    return price.mul(FIVE_BOTTLES).div(PERCENT_BASE).mul(BULK_ORDER_DISCOUNT);
  }

  function _calc1BottlePrice() private view returns (uint256 newPrice, bool isDiscounted) {
    isDiscounted = addressToBottlesReturned[msg.sender] > 0;
    newPrice = isDiscounted ? price.div(PERCENT_BASE).mul(RETURN_BOTTLE_DISCOUNT) : price;

    return (newPrice, isDiscounted);
  }

  function _currentStock() internal view returns (uint256) {
    return balanceOf(address(this));
  }

  function _incrementTotalSold(uint256 amount) internal {
    _totalSold += amount;
  }
}
