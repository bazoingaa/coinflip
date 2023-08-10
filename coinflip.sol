// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoinFlipGame is VRFConsumerBase {
    address public owner;
    uint256 public feePercentage = 5; // Fee percentage
    uint256 public gameId = 1;
    
    // Mapping from game ID to game data
    mapping(uint256 => Game) public games;
    
    enum GameStatus { Created, Played, Finished }
    enum CoinSide { Heads, Tails }
    
    struct Game {
        address player1;
        address player2;
        CoinSide choicePlayer1;
        CoinSide choicePlayer2;
        GameStatus status;
        uint256 betAmount;
        uint256 randomNumber; // Chainlink VRF random number
    }
    
    IERC20 public usdcToken; // USDC token contract address
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        address _usdcToken
    )
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        owner = msg.sender;
        usdcToken = IERC20(_usdcToken);
        
        // Set Chainlink VRF configurations
        keyHash = bytes32("YOUR_KEY_HASH");
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    function createGame(uint256 _betAmount) external {
        require(_betAmount > 0, "Bet amount must be greater than 0");
        require(usdcToken.transferFrom(msg.sender, address(this), _betAmount), "Transfer failed");

        Game storage newGame = games[gameId];
        newGame.player1 = msg.sender;
        newGame.betAmount = _betAmount;
        newGame.status = GameStatus.Created;

        gameId++;
    }
    
    function joinGame(uint256 _gameId, CoinSide _choice) external {
        Game storage game = games[_gameId];
        require(game.status == GameStatus.Created, "Game is not available for joining");
        require(game.player1 != address(0) && game.player1 != msg.sender, "Invalid game or player");
        
        require(usdcToken.transferFrom(msg.sender, address(this), game.betAmount), "Transfer failed");
        
        game.player2 = msg.sender;
        game.choicePlayer2 = _choice;
        game.status = GameStatus.Played;
        
        // Request randomness from Chainlink VRF
        requestRandomness(keyHash, fee);
    }
    
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        uint256 gameId = uint256(_requestId);
        Game storage game = games[gameId];
        require(game.status == GameStatus.Played, "Game is not in playable state");

        game.randomNumber = _randomNumber;
        
        // Determine the winner
        CoinSide actualOutcome = CoinSide(uint256(_randomNumber) % 2 == 0 ? 0 : 1);
        address winner = actualOutcome == game.choicePlayer1 ? game.player1 : game.player2;
        uint256 prizeAmount = game.betAmount * 2;
        uint256 feeAmount = prizeAmount * feePercentage / 100;
        uint256 winnerAmount = prizeAmount - feeAmount;
        
        // Transfer winnings to the winner
        usdcToken.transfer(winner, winnerAmount);
        
        // Set the game status to finished
        game.status = GameStatus.Finished;
    }
}
