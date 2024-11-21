// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RockPapperScissors} from "../src/RockPapperScissor.sol";

contract RockPapperScissorsTest is Test {
    RockPapperScissors rockPapperScissors;

    // Set up function
    function setUp() public {
        rockPapperScissors = new RockPapperScissors();
    }

    // Test gameId initialization
    function test_gameId() public {
        assertEq(rockPapperScissors.gameId(), 0);
    }

    // function test_OnePlayer() public {

    // }

    function test_CreateGame() public {
        
    }
}



