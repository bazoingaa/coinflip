// Instantiate Web3 and connect to Ethereum network
const web3 = new Web3(Web3.givenProvider || 'http://localhost:8545');

// Replace with your contract's address and ABI
const contractAddress = 'YOUR_CONTRACT_ADDRESS';
const contractABI = [...]; // Your contract's ABI

const coinFlipContract = new web3.eth.Contract(contractABI, contractAddress);

async function createGame() {
  const betAmount = document.getElementById('betAmount').value;

  const accounts = await web3.eth.getAccounts();
  const sender = accounts[0];

  await coinFlipContract.methods.createGame(betAmount).send({ from: sender });

  alert('Game created successfully!');
}

async function joinGame() {
  const gameId = document.getElementById('gameId').value;
  const choice = document.getElementById('choice').value;

  const accounts = await web3.eth.getAccounts();
  const sender = accounts[0];

  await coinFlipContract.methods.joinGame(gameId, choice).send({ from: sender });

  alert('Joined the game successfully!');
}

async function updateGameInfo() {
  const gameId = parseInt(document.getElementById('infoGameId').textContent);
  const gameInfo = await coinFlipContract.methods.games(gameId).call();

  document.getElementById('infoStatus').textContent = gameInfo.status;
  document.getElementById('infoWinner').textContent = gameInfo.winner;
}

// Call this function whenever you want to update game information on the UI
updateGameInfo();
