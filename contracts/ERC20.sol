// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @title My erc20 realization
/// @author Oleksandr Voronkov
/// @notice Use this contract to create erc-20 based tokens
/// @dev dev
contract ERC20 is IERC20 {
  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowancesOwnerSpender;

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    require(_balances[msg.sender] >= amount, 'Insufficient balance');
    _balances[msg.sender] -= amount;
    _balances[to] += amount;
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowancesOwnerSpender[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _allowancesOwnerSpender[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    require(_balances[from] >= amount, 'Insufficient balance.');
    require(_allowancesOwnerSpender[from][msg.sender] >= amount, 'Not allowed to spend this much.');

    _balances[from] -= amount;
    _balances[to] += amount;
    _allowancesOwnerSpender[from][msg.sender] -= amount;

    emit Transfer(from, to, amount);

    return true;
  }
}
