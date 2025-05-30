// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title ScopeTwoToken - ERC20 токен с голосованием и переменной ценой
/// @author Oleksandr Voronkov
/// @notice Этот контракт позволяет пользователям покупать и продавать токены, участвовать в голосовании за смену цены токена и управлении.
/// @dev Используется ERC20-совместимая реализация и модуль инициализации OpenZeppelin.
contract ScopeTwoToken is ERC20, Initializable {
  /// @notice Владелец токена
  address public _owner;

  /// @notice Текущая цена токена (в ETH * 100)
  uint256 private _currentPrice;

  /// @notice Процент комиссии (1 = 1%)
  uint8 private _feePercent = 1;

  /// @notice Количество токенов комиссии, которые должны быть сожжены
  uint256 private _feeTokensToBurn;

  /// @notice ETH, собранный как комиссия с продаж
  uint256 private _feesIncomeEth;

  /// @notice Голоса за начало голосования
  uint256 public votedFor;

  /// @notice Голоса против начала голосования
  uint256 public votedAgainst;

  /// @notice Мапа голосов за каждую цену
  mapping(uint256 => uint256) private _priceVotes;

  /// @notice Цены, за которые голосовали
  uint256[] private _prices;

  /// @notice Длительность голосования в секундах
  uint256 public timeToVote;

  /// @notice Время начала голосования
  uint256 public votingStartTime;

  /// @notice Номер текущего голосования
  uint256 public votingNumber;

  /// @notice Статус активности голосования
  bool public votingActive;

  /// @notice Отметка, голосовал ли пользователь за начало голосования
  mapping(address => bool) private _votedForChange;

  /// @notice Массив голосовавших за смену
  address[] private _votersForChange;

  /// @notice Отметка, голосовал ли пользователь за цену
  mapping(address => bool) private _votedForPrice;

  /// @notice Массив голосовавших за цену
  address[] private _votersForPrice;

  /// @notice Порог владения токенами для голосования за смену (% от общего количества токенов)
  uint256 private _changeVotingThreshold = 1_000; // 0.1%

  /// @notice Порог для голосования за цену (% от общего количества токенов)
  uint256 private _priceVotingThreshold = 500; // 0.05%

  /// @notice Лидирующая цена в процессе голосования
  uint256 public leadingPrice;

  /// @notice Инициализация токена
  /// @param _timeToVote Время голосования в секундах
  /// @param changeVotingThreshold Порог участия в голосовании за смену (в базисных пунктах)
  /// @param priceVotingThreshold Порог участия в голосовании за цену (в базисных пунктах)
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

  /// @notice Модификатор — проверка, может ли пользователь голосовать за смену
  modifier canVoteForChange() {
    require(!votingActive, "You cant vote for price voting as it is already going on.");
    require(!_votedForChange[msg.sender], "You have already voted for change.");
    require(
      _balances[msg.sender] * _changeVotingThreshold >= _totalSupply,
      "You cannot vote for change as you dont have enough tokens."
    );
    _;
  }

  /// @notice Модификатор — проверка, может ли пользователь голосовать за цену
  /// @param price Цена, за которую голосует пользователь
  modifier canVoteForPriceChangeAmount(uint256 price) {
    require(
      price > 0 && _currentPrice != price,
      "Price should be more than 0 and not be equal to the current one."
    );
    require(!_votedForPrice[msg.sender], "You have already voted for price.");
    require(_totalSupply > 0, "Total supply is zero. No voting allowed.");
    require(
      _balances[msg.sender] * _priceVotingThreshold >= _totalSupply,
      "You cannot vote for token price as you dont have enough tokens."
    );
    _;
  }

  /// @notice Модификатор — проверка времени окончания голосования
  modifier checkVotingTime() {
    require(votingActive, "Voting is not active.");
    require(block.timestamp >= votingStartTime + timeToVote, "Voting time is not over.");
    _;
  }

  /// @notice Модификатор — только владелец
  modifier onlyOwner() {
    require(msg.sender == _owner, "Function is only for owner.");
    _;
  }

  /// @notice Событие завершения голосования
  event VotingEnded(uint256 votingNumber);

  /// @notice Событие начала голосования
  event VotingStarted(uint256 votingNumber);

  /// @notice Голосование за смену (начало голосования за цену)
  /// @param forChange true — за смену, false — против
  function vote(bool forChange) external canVoteForChange {
    if (forChange) votedFor++;
    else votedAgainst++;

    _votedForChange[msg.sender] = true;
    _votersForChange.push(msg.sender);
  }

  /// @notice Голосование за новую цену токена
  /// @param price Предлагаемая цена
  function vote(uint256 price) external canVoteForPriceChangeAmount(price) {
    uint256 prevLeadingPrice = _priceVotes[leadingPrice];

    _priceVotes[price] += _balances[msg.sender];
    _votedForPrice[msg.sender] = true;
    _votersForPrice.push(msg.sender);

    if (_priceVotes[price] > prevLeadingPrice) {
      leadingPrice = price;
    }
  }

  /// @notice Начинает голосование за новую цену (после голосов за смену)
  function startVoting() external onlyOwner {
    require(!votingActive, "There`s already a pending voting going on.");
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

  /// @notice Завершает голосование и устанавливает новую цену
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

  /// @notice Установить процент комиссии
  /// @param newFee Новое значение комиссии (от 1 до 99)
  function setFeePercent(uint8 newFee) external onlyOwner {
    require(newFee > 0 && newFee < 100, "Fee cannot be less than 1 or more than 99");
    _feePercent = newFee;
  }

  /// @notice Установить изначальную цену токена
  /// @param price Цена (в ETH * 100)
  function setInitialPrice(uint256 price) external onlyOwner {
    require(_currentPrice == 0, "Price has already been set.");
    require(price > 0, "Invalid price");
    _currentPrice = price;
  }

  /// @dev Внутренняя функция выпуска токенов
  function _mint(address to, uint256 amount) private {
    _totalSupply += amount;
    _balances[to] += amount;
    emit Transfer(address(0), to, amount);
  }

  /// @dev Внутренняя функция сжигания токенов
  function _burn(address from, uint256 amount) private {
    require(_balances[from] >= amount, "Not enough tokens to burn");
    _balances[from] -= amount;
    _totalSupply -= amount;
    emit Transfer(from, address(0), amount);
  }

  /// @notice Покупка токенов за ETH
  function buy() external payable {
    require(
      !_votedForChange[msg.sender] && !_votedForPrice[msg.sender],
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

  /// @notice Продажа токенов за ETH
  /// @param tokensAmount Количество токенов для продажи
  function sell(uint256 tokensAmount) external {
    require(
      !_votedForChange[msg.sender] && !_votedForPrice[msg.sender],
      "You cannot sell as you participate in a voting."
    );
    require(_balances[msg.sender] >= tokensAmount, "Not enough tokens");
    require(_currentPrice > 0, "Token price not set");

    uint256 totalEth = (tokensAmount * _currentPrice) / 100;
    uint256 fee = (totalEth * _feePercent) / 100;
    uint256 ethToReturn = totalEth - fee;

    _feesIncomeEth += fee;

    _burn(msg.sender, tokensAmount);
    payable(msg.sender).transfer(ethToReturn);
  }

  /// @inheritdoc ERC20
  function transfer(address to, uint256 amount) public override returns (bool) {
    require(
      !_votedForChange[msg.sender] && !_votedForPrice[msg.sender],
      "You cannot transfer as you participate in a voting."
    );
    return super.transfer(to, amount);
  }

  /// @inheritdoc ERC20
  function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    require(
      !_votedForChange[from] && !_votedForPrice[from],
      "You cannot transfer as you participate in a voting."
    );
    return super.transferFrom(from, to, amount);
  }

  /// @notice Сжигает комиссионные токены со смарт-контракта
  function burnFeeTokens() external onlyOwner {
    _burn(address(this), _feeTokensToBurn);
    _feeTokensToBurn = 0;
  }
}
