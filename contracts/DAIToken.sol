//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @dev DAI is an ERC20 token. It is used only for testing purposes.
 */
contract DAIToken is ERC20 {
  constructor() ERC20('DAI Token', 'DAI') {}

  /**
   * @dev Expose internal mint as external func. See {ERC20-_mint}.
   */
  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }
}
