//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

/**
 * @dev Space Cola is an ERC20 token which has 0 decimal precision.
 * One token represents one bottle of Space Cola.
 */
contract SpaceCola is ERC20, ERC20Burnable, Ownable {
  /**
   * @dev Sets the values for {name} and {symbol}. See {ERC20-constructor}.
   * Transfers the ownership to {owner}.
   */
  constructor(address newOwner) ERC20('Space Cola', 'SPC') {
    transferOwnership(newOwner);
  }

  /**
   * @dev Mints new tokens
   * Only the owner of the contract can mint new tokens.
   */
  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev Zero decimal precision ensures bottles are not divisible.
   */
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }
}
