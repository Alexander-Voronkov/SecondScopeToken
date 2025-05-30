// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC20 Token Implementation
/// @author Oleksandr Voronkov
/// @notice This contract implements a basic version of the ERC-20 token standard.
/// @dev For teaching or testing purposes. Not optimized for production.
contract ERC20 is IERC20 {
  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowancesOwnerSpender;

  /// @notice Returns the total number of tokens in circulation.
  /// @return The total supply of the token.
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Gets the balance of a specific account.
  /// @param account The address of the token holder.
  /// @return The number of tokens held by the given account.
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /// @notice Transfers tokens to a specified address.
  /// @dev Emits a `Transfer` event on success.
  /// @param to The address to transfer tokens to.
  /// @param amount The number of tokens to transfer.
  /// @return A boolean indicating whether the operation succeeded.
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    require(_balances[msg.sender] >= amount, "Insufficient balance");
    _balances[msg.sender] -= amount;
    _balances[to] += amount;
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  /// @notice Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
  /// @param owner The address which owns the funds.
  /// @param spender The address which will spend the funds.
  /// @return The remaining amount of tokens allowed to be spent.
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowancesOwnerSpender[owner][spender];
  }

  /// @notice Approves `spender` to spend `amount` tokens on behalf of the caller.
  /// @dev Emits an `Approval` event.
  /// @param spender The address which is approved to spend tokens.
  /// @param amount The number of tokens to be approved.
  /// @return A boolean indicating whether the operation succeeded.
  function approve(address spender, uint256 amount) public override returns (bool) {
    _allowancesOwnerSpender[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /// @notice Transfers tokens from one address to another using an allowance.
  /// @dev Emits a `Transfer` event. Caller must have sufficient allowance.
  /// @param from The address to send tokens from.
  /// @param to The address to send tokens to.
  /// @param amount The number of tokens to transfer.
  /// @return A boolean indicating whether the operation succeeded.
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    require(_balances[from] >= amount, "Insufficient balance.");
    require(_allowancesOwnerSpender[from][msg.sender] >= amount, "Not allowed to spend this much.");

    _balances[from] -= amount;
    _balances[to] += amount;
    _allowancesOwnerSpender[from][msg.sender] -= amount;

    emit Transfer(from, to, amount);
    return true;
  }
}
