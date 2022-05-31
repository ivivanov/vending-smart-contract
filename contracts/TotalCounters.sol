//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title TotalCounters
 * @dev Contract module which provides increment only counters.
 *
 * This module is used through inheritance.
 */
abstract contract TotalCounters {
  uint256 private _total;
  mapping(address => uint256) private _addressToTotal;

  /**
   * @dev Increment total counter and counter per address.
   * The sum of counters per address is equal to the total counter.
   *
   * Internal function without access restriction.
   */
  function _incrementCounters(uint256 amount) internal virtual {
    _total += amount;
    _addressToTotal[msg.sender] += amount;
  }

  /**
   * @dev Returns the total counter.
   *
   * Internal function without access restriction.
   */
  function _getTotal() internal view returns (uint256) {
    return _total;
  }

  /**
   * @dev Returns total for {_address}.
   *
   * Internal function without access restriction.
   */
  function _getAddressTotal(address _address) internal view returns (uint256) {
    return _getAddressTotal(_address);
  }
}
