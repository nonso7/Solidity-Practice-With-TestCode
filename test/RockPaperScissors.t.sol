// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RockPaperScissors} from "../src/RockPaperScissor.sol";

contract RockPaperScissorsTest is Test {
    RockPaperScissors rockPaperScissors;

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

    function testCreateGame() public {
        address player1 = address(0x123);
        address player2 = address(0x456);
    // Prepare a participant address for the test

        uint256 initialBalance = 2 ether;
        vm.deal(player1, initialBalance);//funding player 1 with sufficient ether

        uint256 amount = 1 ether;
        vm.prank(player1);
        // Create the game, passing in the participant address and some ether
        rockPaperScissors.createGame{value: amount}(player2);

        // Now retrieve the game using the correct gameId (which should be 1 after the first creation)
        uint localId = rockPaperScissors.gameId() - 1; // This will get the current gameId, which will be 1 after the first creation. 
        // Fetch the game with the last created gameId

        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) = rockPaperScissors.getGameById(localId);
        
         // Validate the retrieved game
        assertEq(id, localId);
        assertEq(minimumBet, 1 ether);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
        assertEq(uint(state), uint(RockPaperScissors.State.CREATED));
    }

    function test_GameIdIncreament() public {
        uint gameIdBefore = rockPaperScissors.gameId();

        address player1 = address(0x123);
        address player2 = address(0x456);
    // Prepare a participant address for the test

        uint256 initialBalance = 2 ether;
        vm.deal(player1, initialBalance);//funding player 1 with sufficient ether

        uint256 amount = 1 ether;
        vm.prank(player1);
        // Create the game, passing in the participant address and some ether
        rockPaperScissors.createGame{value: amount}(player2);

        // Now retrieve the game using the correct gameId (which should be 1 after the first creation)
        uint localId = rockPaperScissors.gameId() - 1; // This will get the current gameId, which will be 1 after the first creation. 
        // Fetch the game with the last created gameId

        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) = rockPaperScissors.getGameById(localId);

        uint gameIdAfter = rockPaperScissors.gameId();
        
         // Validate the retrieved game
        assertEq(id, localId);
        assertEq(minimumBet, 1 ether);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
        assertEq(uint(state), uint(RockPaperScissors.State.CREATED));
        assertEq(gameIdAfter, gameIdBefore + 1);
    }


    function test_CheckIfAPlayer1HasJoinedGame() public {
        address player1 = address(0x123);
        // uint256 amount = 2 ether;
    
        vm.prank(player1);
        vm.expectRevert("sender must be second player");
    
        rockPaperScissors.joinGame(gameId);
    }

}
