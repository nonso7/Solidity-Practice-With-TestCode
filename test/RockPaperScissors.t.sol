// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RockPaperScissors} from "../src/RockPaperScissor.sol";

contract RockPaperScissorsTest is Test {
    RockPaperScissors rockPaperScissors;

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

function test_OnePlayer() public {
    uint gameId = 0; // Assuming no games created yet
    address payable[] memory players = new address payable[](2); // Correct array declaration
    players[0] = payable(address(0x123)); // Assigning an address
    players[1] = payable(address(0x456)); // Assigning another address

    // Modify the game struct using a storage reference
     rockPaperScissors.games(gameId).id = gameId;
    rockPaperScissors.games(gameId).bet = 1 ether;
    rockPaperScissors.games(gameId).players = players;
    rockPaperScissors.games(gameId).state = RockPaperScissors.State.CREATED;

    // Test the onePlayer function with player1
    vm.prank(address(0x123)); // Impersonate player1
    vm.expectRevert("should only be called by one player");
    rockPaperScissors.onePlayer(gameId);

    // Test the onePlayer function with player2
    vm.prank(address(0x456)); // Impersonate player2
    vm.expectRevert("should only be called by one player");
    rockPaperScissors.onePlayer(gameId);

    // Test the onePlayer function with a non-player
    vm.prank(address(0x789)); // Impersonate a non-player
    rockPaperScissors.onePlayer(gameId); // Should not revert
}


}
