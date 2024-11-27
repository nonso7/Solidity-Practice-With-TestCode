// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

//
contract RockPaperScissors {
    enum State {
        CREATED,
        JOINED,
        COMMITED,
        REVEALED
    }

    // enum GameObject {
    //     Rock,
    //     Scissors,
    //     Paper
    // }

    struct Game {
        uint256 id;
        uint256 minimumBet;
        address[2] players;
        State state;
    }

    struct Move {
        bytes32 hash;
        uint256 value; // 1, 2, or 3 ?
    }

    mapping(uint256 => Game) public games;
    mapping(uint256 => mapping(address => Move)) public moves;
    mapping(uint256 => uint256) public winningMoves;
    uint256 public gameId;

    error shouldBeOnePlayer();

    constructor() {
        winningMoves[1] = 3;
        winningMoves[2] = 1;
        winningMoves[3] = 2;
    }

    // just an idea to use a private function
    // function winningMove(
    //     GameObject move1,
    //     GameObject move2
    // ) private pure returns (uint8) {
    //     // Rock > Scissors
    //     // Paper > Rock
    //     // Scissors > Paper
    //     if (
    //         (move1 == GameObject.Rock && move2 == GameObject.Scissors) ||
    //         (move1 == GameObject.Paper && move2 == GameObject.Rock) ||
    //         (move1 == GameObject.Scissors && move2 == GameObject.Paper)
    //     ) {
    //         return 1;
    //     }

    //     return 2;
    // }

    // function onePlayer(uint _gameId) public view {
    //     Game storage game = games[_gameId];
    //     if (msg.sender == game.players[0] || msg.sender == game.players[1]) {
    //         revert("should only be called by one player");
    //     }
    // }

    // First player creates the game
    function getGameById(uint256 id) external view returns (uint256, uint256, address[2] memory, State) {
        Game storage game = games[id];
        return (game.id, game.minimumBet, game.players, game.state);
    }

    function createGame(address participant) public payable {
        require(msg.value > 0, "need some ether for minimumBet");

        address[2] memory players;

        players[0] = msg.sender;
        players[1] = participant;

        games[gameId] = Game(gameId, msg.value, players, State.CREATED);

        gameId++;
    }

    function joinGame(uint256 _gameId) public payable {
        Game storage game = games[_gameId];

        require(msg.sender == game.players[1], "sender must be second player");

        require(msg.value >= game.minimumBet, "insufficient balance");

        require(game.state == State.CREATED, "game must be created");

        if (msg.value > game.minimumBet) {
            payable(msg.sender).transfer(msg.value - game.minimumBet);
        }

        game.state = State.JOINED;
    }

    // the msg.sender is trying to make a move
    //
    function commitMove(uint256 _gameId, uint256 moveId, uint256 salt) external {
        Game storage game = games[_gameId];

        if (moves[_gameId][msg.sender].hash != 0) {
            revert("You have already played");
        }

        require(game.state == State.JOINED, "Game must be joined");
        //require(msg.sender == game.players[0] || msg.sender == game.players[1], "should must be one of the player");
        require(moves[moveId][msg.sender].hash == 0, "Move already committed");
        require(moveId == 1 || moveId == 2 || moveId == 3, "Move Id must be minimumBetween 1 and 3");

        //the salt is to prevent dictionary attack
        moves[_gameId][msg.sender] = Move({hash: keccak256(abi.encodePacked(moveId, salt)), value: 0});

        // if both player have played...
        if (moves[_gameId][game.players[0]].hash != 0 && moves[_gameId][game.players[1]].hash != 0) {
            game.state = State.COMMITED;
        }
    }

    function revealMove(uint256 _gameId, uint256 moveId, uint256 salt) external payable {
        Game storage game = games[_gameId];

        require(game.state == State.COMMITED, "game must be in COMMITED state");

        Move storage move1 = moves[moveId][game.players[0]];
        Move storage move2 = moves[moveId][game.players[1]];

        require(move1.value != 0 && move2.value != 0, "Both Players should have played");

        // check that msg.sender is either player0 or player1?

        Move storage moveSender = moves[_gameId][msg.sender];

        require(moveSender.hash == keccak256(abi.encodePacked(moveId, salt)), "moveId does not match commitment");

        moveSender.value = moveId;

        if (move1.value == move2.value) {
            // case of TIE

            payable(game.players[0]).transfer(game.minimumBet);
            payable(game.players[1]).transfer(game.minimumBet);
            game.state = State.REVEALED;

            return;
        }

        address winner;

        winner = winningMoves[move1.value] == move2.value ? game.players[0] : game.players[1];

        payable(winner).transfer(2 * game.minimumBet);

        game.state = State.REVEALED;
    }
}
