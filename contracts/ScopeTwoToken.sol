// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ERC20.sol";

contract ScopeTwoToken is ERC20 {
    address public _owner;

    uint256 private _currentPrice;

    uint8 private _feePercent;
    uint256 private _feeTokensToBurn;
    uint256 private _feesIncomeEth;

    uint256 public votedFor;
    uint256 public votedAgainst;
    mapping(uint256 => uint256) private _priceVotes;
    uint256[] private _prices;

    uint256 public timeToVote;
    uint256 public votingStartTime;
    uint256 public votingNumber;
    bool public votingActive;

    mapping(address => bool) private _votedForChange;
    address[] private _votersForChange;
    mapping(address => bool) private _votedForPrice;
    address[] private _votersForPrice;

    uint256 private _changeVotingThreshold = 1_000;
    uint256 private _priceVotingThreshold = 500;

    uint256 public leadingPrice;

    function initialize(uint256 _timeToVote, uint256 changeVotingThreshold, uint256 priceVotingThreshold) public {
        timeToVote = _timeToVote;
        _changeVotingThreshold = changeVotingThreshold;
        _priceVotingThreshold = priceVotingThreshold;
        _owner = msg.sender;
    }

    modifier canVoteForChange() {
        require(votingActive == false, "You cant vote for price voting as it is already going on.");
        require(_votedForChange[msg.sender] == false, "You have already voted for change.");
        require(_balances[msg.sender] * _changeVotingThreshold >= _totalSupply, "You cannot vote for change as you dont have enough tokens.");
        _;
    }

    modifier canVoteForPriceChangeAmount(uint256 price) {
        require(price > 0 && _currentPrice != price, "Price should be more than 0 and not be equal to the current one.");
        require(_votedForPrice[msg.sender] == false, "You have already voted for price.");
        require(_totalSupply > 0, "Total supply is zero. No voting allowed.");
        require(_balances[msg.sender] * _priceVotingThreshold >= _totalSupply, "You cannot vote for token price as you dont have enough tokens.");
        _;
    }

    modifier checkVotingTime() {
        require(votingActive == true, "Voting is not active.");
        require(block.timestamp >= votingStartTime + timeToVote, "Voting time is not over.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Function is only for owner.");
        _;
    }

    event VotingEnded(uint256 votingNumber);
    event VotingStarted(uint256 votingNumber);

    function vote(bool forChange) external canVoteForChange() {
        if (forChange) {
            votedFor++;
        }
        else {
            votedAgainst++;
        }

        _votedForChange[msg.sender] = true;
        _votersForChange.push(msg.sender);
    }

    function vote(uint256 price) external canVoteForPriceChangeAmount(price) {
        uint256 prevLeadingPrice = _priceVotes[leadingPrice];

        _priceVotes[price] += _balances[msg.sender];
        _votedForPrice[msg.sender] = true;
        _votersForPrice.push(msg.sender);

        if(_priceVotes[price] > prevLeadingPrice) {
            leadingPrice = price;
        }
    }

    function startVoting() external onlyOwner() {
        require(votingActive == false, "There`s already a pending voting going on.");
        require(votedFor > votedAgainst && (votedFor + votedAgainst) > 1, "Voting cannot be started as there`s insufficient voted for count.");

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

    function endVoting() external checkVotingTime() {

        _currentPrice = leadingPrice;

        leadingPrice = 0;

        votingActive = false;

        for (uint256 i = 0; i < _votersForPrice.length; i++) {
            _votedForPrice[_votersForPrice[i]] = false;
        }

        delete _votersForPrice;

        emit VotingEnded(votingNumber);
    }

    function setFeePercent(uint8 newFee) external onlyOwner() {
        require(newFee < 100 && newFee > 0, "Fee cannot be less than 1 or more than 99");
        _feePercent = newFee;
    }

    function setInitialPrice(uint256 price) external onlyOwner() {
        require(_currentPrice == 0, "Price has already been set.");
        require(price > 0, "Invalid price");
        _currentPrice = price;
    }

    function _mint(address to, uint256 amount) public override {
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) public override {
        require(_balances[from] >= amount, "Not enough tokens to burn");
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function buy() external payable {
        require(_votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false, "You cannot buy as you participate in a voting.");
        require(_currentPrice > 0, "Token price has not been set yet.");
        require(msg.value > 0, "Send eth to buy tokens.");

        uint256 tokensToMint = (msg.value * 100) / _currentPrice;
        uint256 feeTokens = (tokensToMint * _feePercent) / 100;
        uint256 tokensAfterFee = tokensToMint - feeTokens;

        _mint(msg.sender, tokensAfterFee);
        _mint(address(this), feeTokens);

        _feeTokensToBurn += feeTokens;
    }

    function sell(uint256 tokensAmount) external {
        require(_votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false, "You cannot sell as you participate in a voting.");
        require(_balances[msg.sender] >= tokensAmount, "Not enough tokens");
        require(_currentPrice > 0, "Token price not set");

        uint256 totalEth = (tokensAmount * _currentPrice) / 100;
        uint256 fee = (totalEth * _feePercent) / 100;
        uint256 ethToReturn = totalEth - fee;

        _feesIncomeEth += fee;
        
        _burn(msg.sender, tokensAmount);
        payable(msg.sender).transfer(ethToReturn);
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
        require(_votedForChange[msg.sender] == false && _votedForPrice[msg.sender] == false, "You cannot transfer as you participate in a voting.");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        require(_votedForChange[from] == false && _votedForPrice[from] == false, "You cannot transfer as you participate in a voting.");
        return super.transferFrom(from, to, amount);
    }

    function burnFeeTokens() external onlyOwner() {
        _burn(address(this), _feeTokensToBurn);
        _feeTokensToBurn = 0;
    }
}