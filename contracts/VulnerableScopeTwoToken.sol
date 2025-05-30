// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VulnerableScopeTwoToken
 * @dev An ERC20 token contract with voting mechanisms for price changes and governance.
 * @notice This contract includes features for token buying/selling with fees, voting systems,
 * and owner-controlled functions. It's initialized using OpenZeppelin's Initializable pattern.
 */
contract VulnerableScopeTwoToken is ERC20, Initializable, ReentrancyGuard {
  /// @notice Address of the contract owner
  address public _owner;

  /// @dev Current price of the token (private)
  uint256 private _currentPrice;

  /// @dev Fee percentage applied to transactions (private)
  uint8 private _feePercent = 1;
  /// @dev Accumulated fee tokens waiting to be burned (private)
  uint256 private _feeTokensToBurn;
  /// @dev Accumulated ETH from fees (private)
  uint256 private _feesIncomeEth;

  /// @notice Total votes in favor of changes
  uint256 public votedFor;
  /// @notice Total votes against changes
  uint256 public votedAgainst;
  /// @dev Mapping of prices to their vote counts (private)
  mapping(uint256 => uint256) private _priceVotes;
  /// @dev Array of proposed prices (private)
  uint256[] private _prices;

  /// @notice Duration of voting period in seconds
  uint256 public timeToVote;
  /// @notice Timestamp when current voting started
  uint256 public votingStartTime;
  /// @notice Current voting session number
  uint256 public votingNumber;
  /// @notice Flag indicating if voting is currently active
  bool public votingActive;

  /// @dev Mapping of addresses that voted for change (private)
  mapping(address => bool) private _votedForChange;
  /// @dev Array of addresses that voted for change (private)
  address[] private _votersForChange;
  /// @dev Mapping of addresses that voted for price (private)
  mapping(address => bool) private _votedForPrice;
  /// @dev Array of addresses that voted for price (private)
  address[] private _votersForPrice;

  /// @dev Minimum token percentage needed to vote for change (private)
  uint256 private _changeVotingThreshold = 1_000;
  /// @dev Minimum token percentage needed to vote for price (private)
  uint256 private _priceVotingThreshold = 500;

  /// @notice Current leading price proposal
  uint256 public leadingPrice;

  /**
   * @dev Initializes the contract with voting parameters
   * @param _timeToVote Duration of voting period in seconds
   * @param changeVotingThreshold Minimum token percentage needed to vote for change (in basis points)
   * @param priceVotingThreshold Minimum token percentage needed to vote for price (in basis points)
   * @notice This function can only be called once as part of the proxy initialization
   */
  function initialize(
    uint256 _timeToVote,
    uint256 changeVotingThreshold,
    uint256 priceVotingThreshold
  ) public initializer {
    timeToVote = _timeToVote;
    _changeVotingThreshold = changeVotingThreshold;
    _priceVotingThreshold = priceVotingThreshold;
    _owner = msg.sender;
  }

  /// @dev Modifier to check if address can vote for change
  modifier canVoteForChange() {
    require(votingActive == false, "You cant vote for price voting as it is already going on.");
    require(_votedForChange[msg.sender] == false, "You have already voted for change.");
    require(
      _balances[msg.sender] * _changeVotingThreshold >= _totalSupply,
      "You cannot vote for change as you dont have enough tokens."
    );
    _;
  }

  /// @dev Modifier to check if address can vote for price change
  modifier canVoteForPriceChangeAmount(uint256 price) {
    require(
      price > 0 && _currentPrice != price,
      "Price should be more than 0 and not be equal to the current one."
    );
    require(_votedForPrice[msg.sender] == false, "You have already voted for price.");
    require(_totalSupply > 0, "Total supply is zero. No voting allowed.");
    require(
      _balances[msg.sender] * _priceVotingThreshold >= _totalSupply,
      "You cannot vote for token price as you dont have enough tokens."
    );
    _;
  }

  /// @dev Modifier to check voting time constraints
  modifier checkVotingTime() {
    require(votingActive == true, "Voting is not active.");
    require(block.timestamp >= votingStartTime + timeToVote, "Voting time is not over.");
    _;
  }

  /// @dev Modifier to check if caller is owner
  modifier onlyOwner() {
    require(msg.sender == _owner, "Function is only for owner.");
    _;
  }

  /// @notice Emitted when voting ends
  event VotingEnded(uint256 votingNumber);
  /// @notice Emitted when voting starts
  event VotingStarted(uint256 votingNumber);
  /// @notice Emitted when a vulnerable transfer occurs
  event VulnerableTransfer(uint256 vulnerableAmount);

  /**
   * @dev Vote for or against a governance change
   * @param forChange Boolean indicating vote direction (true = for, false = against)
   * @notice Requires caller to meet voting requirements
   */
  function vote(bool forChange) external canVoteForChange {
    if (forChange) {
      votedFor++;
    } else {
      votedAgainst++;
    }

    _votedForChange[msg.sender] = true;
    _votersForChange.push(msg.sender);
  }

  /**
   * @dev Vote for a new token price
   * @param price The proposed new price
   * @notice Requires caller to meet voting requirements and provide valid price
   */
  function vote(uint256 price) external canVoteForPriceChangeAmount(price) {
    uint256 prevLeadingPrice = _priceVotes[leadingPrice];

    _priceVotes[price] += _balances[msg.sender];
    _votedForPrice[msg.sender] = true;
    _votersForPrice.push(msg.sender);

    if (_priceVotes[price] > prevLeadingPrice) {
      leadingPrice = price;
    }
  }

  /**
   * @dev Starts a new voting session
   * @notice Only callable by owner when no voting is active and with sufficient votes
   */
  function startVoting() external onlyOwner {
    require(votingActive == false, "There`s already a pending voting going on.");
    require(
      votedFor > votedAgainst && (votedFor + votedAgainst) > 1,
      "Voting cannot be started as there`s insufficient voted for count."
    );

    for (uint256 i = 0; i < _votersForChange.length; i++) {
      _votedForChange[_votersForChange[i]] = false;
    }

    delete _votersForChange;

    votedFor = 0;
    votedAgainst = 0;

    votingActive = true;
    votingStartTime = block.timestamp;
    votingNumber++;

    emit VotingStarted(votingNumber);
  }

  /**
   * @dev Ends the current voting session and updates price
   * @notice Can only be called after voting period has ended
   */
  function endVoting() external checkVotingTime {
    _currentPrice = leadingPrice;

    leadingPrice = 0;

    votingActive = false;

    for (uint256 i = 0; i < _votersForPrice.length; i++) {
      _votedForPrice[_votersForPrice[i]] = false;
    }

    delete _votersForPrice;

    emit VotingEnded(votingNumber);
  }

  /**
   * @dev Sets the transaction fee percentage
   * @param newFee New fee percentage (1-99)
   * @notice Only callable by owner
   */
  function setFeePercent(uint8 newFee) external onlyOwner {
    require(newFee < 100 && newFee > 0, "Fee cannot be less than 1 or more than 99");
    _feePercent = newFee;
  }

  /**
   * @dev Sets the initial token price
   * @param price Initial price to set
   * @notice Only callable by owner before price is set
   */
  function setInitialPrice(uint256 price) external onlyOwner {
    require(_currentPrice == 0, "Price has already been set.");
    require(price > 0, "Invalid price");
    _currentPrice = price;
  }

  /**
   * @dev Internal function to mint new tokens
   * @param to Address to receive minted tokens
   * @param amount Amount of tokens to mint
   */
  function _mint(address to, uint256 amount) private {
    _totalSupply += amount;
    _balances[to] += amount;
    emit Transfer(address(0), to, amount);
  }

  /**
   * @dev Internal function to burn tokens
   * @param from Address whose tokens will be burned
   * @param amount Amount of tokens to burn
   */
  function _burn(address from, uint256 amount) private {
    //require(_balances[from] >= amount, "Not enough tokens to burn"); // commented to make reentancy possible
    _balances[from] -= amount;
    _totalSupply -= amount;
    emit Transfer(from, address(0), amount);
  }

  /**
   * @dev Buy tokens with ETH
   * @notice Applies fee to purchase and mints tokens to sender
   */
  function buy() external payable {
    require(
      _votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false,
      "You cannot buy as you participate in a voting."
    );
    require(_currentPrice > 0, "Token price has not been set yet.");
    require(msg.value > 0, "Send eth to buy tokens.");

    uint256 tokensToMint = (msg.value * 100) / _currentPrice;
    uint256 feeTokens = (tokensToMint * _feePercent) / 100;
    uint256 tokensAfterFee = tokensToMint - feeTokens;

    _mint(msg.sender, tokensAfterFee);
    _mint(address(this), feeTokens);

    _feeTokensToBurn += feeTokens;
  }

  /**
   * @dev Sell tokens for ETH
   * @param tokensAmount Amount of tokens to sell
   * @notice Applies fee to sale and transfers ETH to sender
   */
  function sell(uint256 tokensAmount) external {
    require(
      _votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false,
      "You cannot sell as you participate in a voting."
    );
    require(_balances[msg.sender] >= tokensAmount, "Not enough tokens");
    require(_currentPrice > 0, "Token price not set");

    uint256 totalEth = (tokensAmount * _currentPrice) / 100;
    uint256 fee = (totalEth * _feePercent) / 100;
    uint256 ethToReturn = totalEth - fee;

    _feesIncomeEth += fee;

    emit VulnerableTransfer(ethToReturn);
    (bool success, ) = msg.sender.call{ value: ethToReturn }("");
    require(success, "ETH transfer failed");
    _burn(msg.sender, tokensAmount);
  }

  /**
   * @dev Overrides ERC20 transfer with voting participation check
   * @param to Recipient address
   * @param amount Amount to transfer
   * @return bool Success indicator
   */
  function transfer(address to, uint256 amount) public override returns (bool) {
    require(
      _votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false,
      "You cannot transfer as you participate in a voting."
    );
    return super.transfer(to, amount);
  }

  /**
   * @dev Overrides ERC20 transferFrom with voting participation check
   * @param from Sender address
   * @param to Recipient address
   * @param amount Amount to transfer
   * @return bool Success indicator
   */
  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    require(
      _votedForChange[from] == false && _votedForPrice[from] == false,
      "You cannot transfer as you participate in a voting."
    );
    return super.transferFrom(from, to, amount);
  }

  /**
   * @dev Burns accumulated fee tokens
   * @notice Only callable by owner
   */
  function burnFeeTokens() external onlyOwner {
    _burn(address(this), _feeTokensToBurn);
    _feeTokensToBurn = 0;
  }
}
