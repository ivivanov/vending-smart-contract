//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Counters.sol';

/**
 * @title Operated
 * @dev Contract module which provides a basic access control mechanism, where
 * there is a list of operators that can be granted exclusive access to
 * specific functions.
 *
 * By default, the first operator account will be the one that deploys the contract. This
 * can later be changed with {addOperator} or {removeOperator}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to your functions to restrict their use to
 * the operators.
 */
abstract contract Operated {
  using Counters for Counters.Counter;

  Counters.Counter private _operatorsCount;
  uint8 private constant _MAX_OPERATORS = 3;
  mapping(address => bool) private _addressToOperator;

  event OperatorAdded(address newOperator);
  event OperatorRemoved(address oldOperator);

  /**
   * @dev Initializes the contract setting the deployer as the first operator.
   */
  constructor() {
    _addOperator(msg.sender);
  }

  /**
   * @dev Restricts a function so it can only be executed when caller's address has operator role. Throws if called by any account other than operator.
   */
  modifier onlyOperator() {
    require(_addressToOperator[msg.sender], 'Operator: caller is not operator');
    _;
  }

  /**
   * @dev Throws if new address is same as the caller.
   */
  modifier notSelf(address newAddress) {
    require(msg.sender != newAddress, 'Operator: new address can not be sender');
    _;
  }

  /**
   * @dev Add Operator adds new account to the list of operators.
   * Can only be called by operator.
   */
  function addOperator(address newOperator) public virtual onlyOperator {
    _addOperator(newOperator);
  }

  /**
   * @dev Add Operator adds new account to the list of operators.
   * Internal function without access restriction.
   */
  function _addOperator(address newOperator) internal virtual notSelf(newOperator) {
    require(_operatorsCount.current() < _MAX_OPERATORS, 'Operator: max operators reached');
    require(_addressToOperator[newOperator] == false, 'Operator: address already operator');

    _operatorsCount.increment();
    _addressToOperator[newOperator] = true;

    emit OperatorAdded(newOperator);
  }

  /**
   * @dev Remove Operator removes existing operator account from the list of operators.
   * Can only be called by operator.
   */
  function removeOperator(address oldOperator) public virtual onlyOperator {
    _removeOperator(oldOperator);
  }

  /**
   * @dev Remove Operator removes existing operator account from the list of operators.
   * Internal function without access restriction.
   */
  function _removeOperator(address oldOperator) internal virtual notSelf(oldOperator) {
    require(_addressToOperator[oldOperator] == true, 'Operator: address not operator');

    _operatorsCount.decrement();
    _addressToOperator[oldOperator] = false;

    emit OperatorRemoved(oldOperator);
  }
}
