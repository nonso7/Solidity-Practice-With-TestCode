// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RockPaperScissors} from "../src/RockPaperScissor.sol";

contract RockPaperScissorsTest is Test {
    RockPaperScissors rockPaperScissors;

    address payable player1 = payable(address(0x123));
    address payable player2 = payable(address(0x456));
    uint256 gameId;

    // Set up function
    function setUp() public {
        rockPaperScissors = new RockPaperScissors();
    }

    // Test gameId initialization
    function test_gameId() public view {
        assertEq(rockPaperScissors.gameId(), 0);
    }

    function test_Constructor_Initialization() public view {
        assertEq(rockPaperScissors.winningMoves(1), 3, "Rock shuts the mouth of scissors");
        assertEq(rockPaperScissors.winningMoves(2), 1, "Paper wraps rock");
        assertEq(rockPaperScissors.winningMoves(3), 2, "Scissors cuts paper");
    }
    
    function testBet_RevertsWithZeroEther() public {
        vm.expectRevert("need some ether for minimumBet");
        rockPaperScissors.createGame{value: 0}(address(123));
    }

    function testBet_PassWhenSomeEtherIsSent() public {
        uint256 amount = 1 ether;
        rockPaperScissors.createGame{value: amount}(address (234));
    }

    // function test_GameCreated() public {
    //     // Call createGame to initialize a struct
    //     uint amount = 1 ether;
    //      rockPaperScissors.createGame{value: amount}(address(234));

    //     uint gameId = rockPaperScissors.gameId();

    //     // Fetch the created game
    //     // (uint id, uint bet, address[] memory players, RockPaperScissors.State state) = rockPaperScissors.games(0);
    //     RockPaperScissors.Game memory game = rockPaperScissors.games(gameId - 1);

    //     uint id = game.id;
    //     uint minimumBet = game.minimumBet;
    //     address[2] memory players = game.players;
    //     RockPaperScissors.State state = game.state;

    //     // Assert that the struct's fields are correctly set
    //     assertEq(id, 0);
    //     assertEq(minimumBet, 1 ether);
    //     assertEq(players[0], address(this));
    //     assertEq(players[1], address(234));
    //     assertEq(uint(state), uint(RockPaperScissors.State.CREATED));
    // }

    function testCreateGame() public {
    // Prepare a participant address for the test
        address participant = address(0x123);

        // Create the game, passing in the participant address and some ether
        rockPaperScissors.createGame{value: 1 ether}(participant);

        // Now retrieve the game using the correct gameId (which should be 1 after the first creation)
        uint localId = rockPaperScissors.gameId(); // This will get the current gameId, which will be 1 after the first creation. 
        // Fetch the game with the last created gameId
        RockPaperScissors.Game memory game = rockPaperScissors.games(localId); // Fetch the game with gameId 0
        
        // Access the fields of the game individually
        uint id = game.id;
        uint minimumBet = game.minimumBet;
        address[2] memory players = game.players;
        RockPaperScissors.State state = game.state;

        // Now assert the struct's fields are correctly set
        assertEq(id, 0); // The first game created should have id 0
        assertEq(minimumBet, 1 ether); // The bet is 1 ether
        assertEq(players[0], address(this)); // The creator should be the sender
        assertEq(players[1], participant); // The participant should be the passed address
        // Assert that the state is 'CREATED'. Enum value for 'CREATED' is 0.
        assertEq(uint(state), uint(RockPaperScissors.State.CREATED)); // State should be CREATED (which is 0 in the enum)
    }

}
