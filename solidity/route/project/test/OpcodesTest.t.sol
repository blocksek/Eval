// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Tables, Deployer, Opcodes} from "src/Opcodes.sol";

contract OpcodesPublic is Opcodes {
    constructor(Tables memory tables) Opcodes(tables) {}

    function add8(uint8 a, uint8 b, bool carryIn) external view returns (uint8, bool) {
        return _add8(a, b, carryIn);
    }

    function add256(uint256 a, uint256 b) external view returns (uint256) {
        return _add256(a, b);
    }

    function sub8(uint8 a, uint8 b, bool borrowIn) external view returns (uint8, bool) {
        return _sub8(a, b, borrowIn);
    }

    function sub256(uint256 a, uint256 b) external view returns (uint256) {
        return _sub256(a, b);
    }

    function eq8(uint8 a, uint8 b) external view returns (bool) {
        return _eq8(a, b);
    }

    function eq256(uint256 a, uint256 b) external view returns (bool) {
        return _eq256(a, b);
    }

    function lt8(uint8 a, uint8 b) external view returns (bool) {
        return _lt8(a, b);
    }

    function lt256(uint256 a, uint256 b) external view returns (bool) {
        return _lt256(a, b);
    }

    function gte256(uint256 a, uint256 b) external view returns (bool) {
        return _gte256(a, b);
    }
}

contract OpcodesTest is Test {
    OpcodesPublic private opcodes;

    function setUp() public {
        Deployer deployer = new Deployer();
        opcodes = new OpcodesPublic(deployer.deployTables());
    }

    function test_add8(uint8 a, uint8 b, bool carryIn) public view {
        uint256 sum = uint256(a) + uint256(b) + (carryIn ? 1 : 0);
        uint8 expected_c = uint8(sum);
        bool expected_carryOut = sum > type(uint8).max;

        (uint256 c, bool carryOut) = opcodes.add8(a, b, carryIn);
        assertEq(c, expected_c);
        assertEq(carryOut, expected_carryOut);
    }

    function test_add256(uint256 a, uint256 b) public view {
        uint256 sum;
        unchecked {
            sum = a + b;
        }
        uint256 c = opcodes.add256(a, b);
        assertEq(c, sum);
    }

    function test_sub8(uint8 a, uint8 b, bool borrowIn) public view {
        uint8 expected_c;
        unchecked {
            expected_c = a - b - (borrowIn ? 1 : 0);
        }
        bool expected_borrowOut = a < uint256(b) + (borrowIn ? 1 : 0);

        (uint256 c, bool borrowOut) = opcodes.sub8(a, b, borrowIn);
        assertEq(c, expected_c);
        assertEq(borrowOut, expected_borrowOut);
    }

    function test_sub256(uint256 a, uint256 b) public view {
        uint256 expected_c;
        unchecked {
            expected_c = a - b;
        }
        uint256 c = opcodes.sub256(a, b);
        assertEq(c, expected_c);
    }

    function test_eq8(uint8 a, uint8 b) public view {
        bool expected = a == b;
        bool result = opcodes.eq8(a, b);
        assertEq(result, expected);
    }

    function test_eq256(uint256 a, uint256 b) public view {
        bool expected = a == b;
        bool result = opcodes.eq256(a, b);
        assertEq(result, expected);
    }

    function test_lt8(uint8 a, uint8 b) public view {
        bool expected = a < b;
        bool result = opcodes.lt8(a, b);
        assertEq(result, expected);
    }

    function test_lt256(uint256 a, uint256 b) public view {
        bool expected = a < b;
        bool result = opcodes.lt256(a, b);
        assertEq(result, expected);
    }

    function test_gte256(uint256 a, uint256 b) public view {
        bool expected = a >= b;
        bool result = opcodes.gte256(a, b);
        assertEq(result, expected);
    }
}
