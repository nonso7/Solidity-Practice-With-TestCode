// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24; 

contract RockPapperScissors{
    enum State {
        CREATED,
        JOINED,
        COMMITED,
        REVEALED
    }

    struct Game {
        uint id;
        uint bet;
        address payable[] players;
        State state;
    }
    struct Move {
        bytes32 hash;
        uint value;
    }

    mapping(uint => Game) public games;
    mapping(uint => mapping(address => Move)) public moves;
    mapping(uint => uint) public winningMoves;
    uint public gameId;

    error shouldBeOnePlayer();

    constructor() {
        winningMoves[1] = 3;
        winningMoves[2] = 1;
        winningMoves[3] = 2;
    }

    function onePlayer(uint _gameId) external view {
        Game storage game = games[_gameId];
        if (msg.sender == game.players[0] || msg.sender == game.players[1]) {
        revert ('should only be called by one player');
    }
}


    function createGame(address payable participant) external payable {
        require(msg.value > 0, "need some ether");
        address payable[] memory players = new address payable[](2);
        players[0] = payable(msg.sender);
        players[1] = participant;

        games[gameId] = Game( gameId, msg.value, players, State.CREATED);

        gameId++;
    }

    function joinGame(uint _gameId) public payable {
        Game storage game = games[_gameId];
        require(msg.sender == game.players[1], 'sender must be second player');
        require(msg.value >= game.bet, "insufficient balance");
        require(game.state == State.CREATED, "game must be created");
        if(msg.value > game.bet) {
            payable(msg.sender).transfer(msg.value - game.bet);
           
        } 
        game.state = State.JOINED;
    }

    function commitMove(uint _gameId, uint moveId, uint salt) external {
        Game storage game = games[_gameId];
        onePlayer(_gameId);
        require(game.state == State.JOINED, "Game must be joined");
        //require(msg.sender == game.players[0] || msg.sender == game.players[1], "should must be one of the player");
        require(moves[moveId][msg.sender].hash == 0, "Move already committed");
        require(moveId == 1 || moveId == 2 || moveId == 3,"Move Id must be between 1 and 3");
        //the salt is to prevent dictionary attack
        moves[_gameId][msg.sender] = Move(keccak256(abi.encodePacked(moveId, salt)), 0);

        if(moves[_gameId][game.players[0]].hash != 0 && moves[_gameId][game.players[1]].hash != 0) {
            game.state = State.COMMITED;
        }
    }

    function revealMove(uint _gameId, uint moveId, uint salt) external {
        Game storage game = games[_gameId];
        Move storage move1 = moves[moveId][game.players[0]]; 
        Move storage move2 = moves[moveId][game.players[1]];
        Move storage moveSender = moves[_gameId][msg.sender];
        require(game.state == State.COMMITED, 'game must be in COMMITED state');
        onePlayer(_gameId);
        require(moveSender.hash == keccak256(abi.encodePacked(moveId, salt)), 'moveId does not match commitment');
        moveSender.value = moveId;
        
        if(move1.value != 0 && move2.value != 0) {
            if(move1.value == move2.value) {
                game.players[0].transfer(game.bet);
                game.players[1].transfer(game.bet);
                game.state = State.REVEALED;
                return;
            }
            address payable winner;
            winner = winningMoves[move1.value] == move2.value ? game.players[0] : game.players[1];
            winner.transfer(2* game.bet);
            game.state = State.REVEALED;
        }  
  
    }
}