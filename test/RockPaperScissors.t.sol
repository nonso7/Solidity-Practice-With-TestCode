// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RockPaperScissors} from "../src/RockPaperScissor.sol";

contract RockPaperScissorsTest is Test {
    RockPaperScissors rockPaperScissors;

    address player1 = address(0x123);
    address player2 = address(0x456);
    uint256 gameId;
    //uint256 minimumBet = 1 ether;

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
        rockPaperScissors.createGame{value: amount}(address(234));
    }

    function testCreateGame() public {
        // address player1 = address(0x123);
        // address player2 = address(0x456);
        // Prepare a participant address for the test

        uint256 initialBalance = 2 ether;
        vm.deal(player1, initialBalance); //funding player 1 with sufficient ether

        uint256 amount = 1 ether;
        vm.prank(player1);
        // Create the game, passing in the participant address and some ether
        rockPaperScissors.createGame{value: amount}(player2);

        // Now retrieve the game using the correct gameId (which should be 1 after the first creation)
        uint256 localId = rockPaperScissors.gameId() - 1; // This will get the current gameId, which will be 1 after the first creation.
        // Fetch the game with the last created gameId

        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) =
            rockPaperScissors.getGameById(localId);

        // Validate the retrieved game
        assertEq(id, localId);
        assertEq(minimumBet, 1 ether);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
        assertEq(uint256(state), uint256(RockPaperScissors.State.CREATED));
    }

    function test_GameIdIncreament() public {
        uint256 gameIdBefore = rockPaperScissors.gameId();

        // address player1 = address(0x123);
        // address player2 = address(0x456);
        // Prepare a participant address for the test

        uint256 initialBalance = 2 ether;
        vm.deal(player1, initialBalance); //funding player 1 with sufficient ether

        uint256 amount = 1 ether;
        vm.prank(player1);
        // Create the game, passing in the participant address and some ether
        rockPaperScissors.createGame{value: amount}(player2);

        // Now retrieve the game using the correct gameId (which should be 1 after the first creation)
        uint256 localId = rockPaperScissors.gameId() - 1; // This will get the current gameId, which will be 1 after the first creation.
        // Fetch the game with the last created gameId

        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) =
            rockPaperScissors.getGameById(localId);

        uint256 gameIdAfter = rockPaperScissors.gameId();

        // Validate the retrieved game
        assertEq(id, localId);
        assertEq(minimumBet, 1 ether);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
        assertEq(uint256(state), uint256(RockPaperScissors.State.CREATED));
        assertEq(gameIdAfter, gameIdBefore + 1);
    }

    //     function test_DebugGamePlayers() public {
    //     ( , , address[2] memory players, ) = rockPaperScissors.getGameById(0);
    //     console.log("Player 1: %s", players[0]);
    //     console.log("Player 2: %s", players[1]);
    // }

    // function test_DebugCreateGame() public {
    //     vm.prank(player1); // Simulate player1 as the sender
    //     rockPaperScissors.createGame{value: 1 ether}(player2);

    //     ( , , address[2] memory players, RockPaperScissors.State state) = rockPaperScissors.getGameById(0);

    //     assertEq(players[0], player1, "Player 1 is not set correctly");
    //     assertEq(players[1], player2, "Player 2 is not set correctly");
    //     assertEq(uint(state), uint(RockPaperScissors.State.CREATED), "Game state is not CREATED");
    // }

    function test_JoinGame() public {
        // Step 1: Fund player accounts
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);

        // Step 2: Player 1 creates a game
        vm.prank(player1); // Simulate player1 as the sender
        rockPaperScissors.createGame{value: 1 ether}(player2);

        // Step 3: Verify the game was created correctly
        (,, address[2] memory players, RockPaperScissors.State state) = rockPaperScissors.getGameById(0);
        assertEq(players[0], player1, "Player 1 is incorrect");
        assertEq(players[1], player2, "Player 2 is incorrect");
        assertEq(uint256(state), uint256(RockPaperScissors.State.CREATED), "Game state is not CREATED");

        // Step 4: Player 2 joins the game
        vm.prank(player2); // Simulate player2 as the sender
        rockPaperScissors.joinGame{value: 1 ether}(0);

        // Step 5: Verify game state after joining
        (,,, state) = rockPaperScissors.getGameById(0);
        assertEq(uint256(state), uint256(RockPaperScissors.State.JOINED), "Game state did not transition to JOINED");
    }

    function test_JoinGameWhenNotSecondPlayer() public {
        // Setup: Create the game first
        vm.deal(player1, 10 ether);
        // vm.deal(player2, 2 ether);

        vm.prank(player1);
        rockPaperScissors.createGame{value: 1 ether}(player2);

        // Step 1: Try to make Player 1 join (they should be the first player)
        // Player 1 is not allowed to join as they are the first player
        vm.prank(player1); // Use player1 to try joining
        vm.expectRevert("sender must be second player"); // Expect the revert message for Player 1
        rockPaperScissors.joinGame{value: 1 ether}(0); // Attempt to join the game
    }

    function test_JoinGameWhenSecondPlayer() public {
        // Setup: Create the game first
        vm.deal(player1, 10 ether);
        vm.deal(player2, 2 ether); // Player 2 has sufficient funds for the game

        vm.prank(player1);
        rockPaperScissors.createGame{value: 1 ether}(player2);

        vm.prank(player2); // Use player2 to join
        rockPaperScissors.joinGame{value: 1 ether}(0); // Player 2 should successfully join the game
    }

    function test_JoinGameWithInsufficientBalance() public {
        // Step 1: Fund player accounts
        vm.deal(player1, 10 ether);
        vm.deal(player2, 0.5 ether); // Insufficient balance for the game

        // Step 2: Player 1 creates a game
        vm.prank(player1); // Simulate player1 as the sender
        rockPaperScissors.createGame{value: 1 ether}(player2);

        // Step 3: Player 2 attempts to join with insufficient funds
        vm.prank(player2); // Simulate player2 as the sender
        vm.expectRevert("insufficient balance"); // Expect a revert with this error message
        rockPaperScissors.joinGame{value: 0.5 ether}(0);
    }

    function testJoinGame_WhenGameStateIsNotCreated() public {
        // Step 1: Fund player1 with enough Ether
        vm.deal(player1, 10 ether); // Ensure player1 has enough funds to create the game
        vm.deal(player2, 2 ether); // Ensure player2 has enough funds to join the game

        // Step 2: Player 1 creates a game
        vm.prank(player1); // Simulate player1 making the transaction
        rockPaperScissors.createGame{value: 1 ether}(player2); // Player1 creates a game, player2 is the second player

        // Step 3: Check the game state and ensure it is CREATED initially
        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) =
            rockPaperScissors.getGameById(gameId);
        assertEq(uint256(state), uint256(RockPaperScissors.State.CREATED)); // Verify game state is 'CREATED'

        // Step 4: Simulate Player 2 joining the game
        vm.prank(player2); // Simulate player2 joining the game
        rockPaperScissors.joinGame{value: 1 ether}(gameId); // Player 2 joins the game

        // Step 5: Check the game state again after Player 2 joins
        //this form of declaration(uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state)
        //can not be repeated here so that the error previous declaration wont be displayed
        (id, minimumBet, players, state) = rockPaperScissors.getGameById(gameId);
        assertEq(uint256(state), uint256(RockPaperScissors.State.JOINED)); // Game state should now be JOINED

        // Step 6: Try to join again when the game state is JOINED (should fail)
        vm.prank(player2); // Simulate player2 trying to join again
        vm.expectRevert("game must be created"); // Expect revert with error message
        rockPaperScissors.joinGame{value: 1 ether}(gameId); // Should revert because game state is no longer 'CREATED'
    }

    function test_ToRefundIfExcessEther() public {
        // Step 1: Fund player1 with enough Ether
        uint256 initialBalancePlayer2 = 100 ether;
        uint256 minBet = 10 ether;
        vm.deal(player1, 20 ether); // Ensure player1 has enough funds to create the game
        vm.deal(player2, initialBalancePlayer2); // Ensure player2 has enough funds to join the game

        // Step 2: Player 1 creates a game
        vm.prank(player1); // Simulate player1 making the transaction
        rockPaperScissors.createGame{value: minBet}(player2); // Player1 creates a game, player2 is the second player

        // Step 3: Check the game state and ensure it is CREATED initially
        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) =
            rockPaperScissors.getGameById(gameId);
        assertEq(uint256(state), uint256(RockPaperScissors.State.CREATED)); // Verify game state is 'CREATED'

        // Step 4: Simulate Player 2 joining the game
        uint256 overPaidPlayer2 = 90 ether;
        vm.prank(player2); // Simulate player2 joining the game
        rockPaperScissors.joinGame{value: overPaidPlayer2}(gameId); // Player 2 joins the game

        // Step 5: Check the game state again after Player 2 joins
        //this form of declaration(uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state)
        //can not be repeated here so that the error previous declaration wont be displayed
        (id, minimumBet, players, state) = rockPaperScissors.getGameById(gameId);
        assertEq(uint256(state), uint256(RockPaperScissors.State.JOINED)); // Game state should now be JOINED

        uint256 player2FinalBalance = player2.balance;
        uint256 refundAmount = overPaidPlayer2 - minBet;
        uint256 finalBalanceOfPlayer2 = initialBalancePlayer2 - minBet;
        assertEq(player2FinalBalance, finalBalanceOfPlayer2, "Refund mismatch");

        console.log(player2FinalBalance, refundAmount, finalBalanceOfPlayer2);
    }

    function test_IfPlayer1HashIsNotEqualsTo0() public {
        uint256 moveId = 1;
        uint256 salt;

        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);

        vm.prank(player1);
        rockPaperScissors.createGame{value: 10 ether}(player2);

        vm.prank(player2);
        rockPaperScissors.joinGame{value: 10 ether}(gameId);

        (uint256 id, uint256 minimumBet, address[2] memory players, RockPaperScissors.State state) = rockPaperScissors.getGameById(gameId);
        assertEq(uint256(state), uint256(RockPaperScissors.State.JOINED));

        vm.prank(player1);
        rockPaperScissors.commitMove(gameId, moveId, salt);

        (bytes32 hash1, uint256 value1) = rockPaperScissors.moves(gameId, player1);
        assertEq(hash1, keccak256(abi.encodePacked(moveId, salt)), "Player 1's move hash does not match");
        assertEq(value1, 0, "Player 1's move value should be 0 (not revealed)");
    }
}
