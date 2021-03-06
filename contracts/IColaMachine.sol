//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of {ColaMachine}.
 */
interface IColaMachine {
  /**
   * @dev Emitted when user buys a bottle.
   */
  event BottleBought(address payee, uint8 amount);

  /**
   * @dev Emitted when user returns a bottle.
   */
  event BottleReturned(address payee);

  /**
   * @dev Emitted when operator mints new bottle tokens.
   */
  event Restocked();

  /**
   * @dev Emitted when operator changes price per bottle.
   */
  event PriceChanged(uint256 newPrice);

  /**
   * @dev Emitted when operator initiates withdrawal of the {ColaMachine} balance.
   */
  event ReadyToWithdraw(address dest, uint256 amount);

  /**
   * Used when ERC20 transfer return success = false
   */
  error FailedTransfer();

  /**
   * @dev Buys 1 bottle for a specific price in ETH. The equivalent amount of tokens are transferred to the sender.
   *
   * Emits a {BottleBought} event.
   */
  function buyBottle() external payable;

  /**
   * @dev Buys 1 bottle for a specific price in DAI. The equivalent amount of tokens are transferred to the sender.
   *
   * Emits a {BottleBought} event.
   */
  function buyBottleDAI(uint256 amount) external;

  /**
   * @dev Buys 5 bottle for a specific price in ETH. The equivalent amount of tokens are transferred to the sender.
   *
   * Emits a {BottleBought} event.
   */
  function buy5Bottles() external payable;

  /**
   * @dev Return 1 bottle. User should approve the contract to spend 1 bottle token. Increases the user returned bottles balance.
   *
   * Emits a {BottleReturned} event.
   */
  function returnBottle() external;

  /**
   * @dev Returns the total sold bottles.
   *
   * NOTE: Consider restricting the access.
   */
  function getTotalSold() external view returns (uint256);

  /**
   * @dev Mints new bottle tokens on the contract address.
   *
   * NOTE: Consider restricting the access.
   */
  function restock(uint8 amount) external;

  /**
   * @dev Sets new bottle price.
   *
   * NOTE: Consider restricting the access.
   */
  function setPrice(uint256 newPrice) external;

  /**
   * @dev Reserves all the contract ballance for the sender's address.
   *
   * NOTE: Consider restricting the access.
   */
  function prepareWithdrawal() external;

  /**
   * @dev Withdraw all the contract DAI ballance to the sender's address.
   *
   * NOTE: Consider restricting the access.
   */
  function withdrawDAI() external;
}
