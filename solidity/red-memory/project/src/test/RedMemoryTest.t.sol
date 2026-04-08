// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "src/RedMemory.sol";
import "src/Challenge.sol";


contract RedMemoryTest is Test {
    Challenge _challenge;
    RedMemory _redMemory;
    Remembrance _remembrance;
    address player = makeAddr("player");

    function setUp() public {
        _challenge = new Challenge(player);
        _redMemory = _challenge.redMemory();
        _remembrance = new Remembrance();
    }

    function testSolveRedMemory() external {
        vm.prank(player);
        _redMemory.cast(address(_remembrance));
        assertEq(_challenge.isSolved(), true);
    }
}

contract Remembrance {
    fallback() external {
        assembly {
            mstore(0x00, 0x00a00101200800a00400a00503800800e00201a0020300010240070000000000)
            return(0x00, 0x20)
        }
    } 
}
