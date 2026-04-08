// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Tables {
    address nibbleShift;
    address nibbleLow;
    address nibbleHigh;
    address addSum;
    address addCarry;
    address subRes;
    address subBorrow;
    address eq;
    address and;
    address lt;
}

contract Deployer {
    function deployTables() public returns (Tables memory) {
        bytes memory nibbleShift =
            hex"000102030405060708090a0b0c0d0e0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101112131415161718191a1b1c1d1e1f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202122232425262728292a2b2c2d2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000303132333435363738393a3b3c3d3e3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404142434445464748494a4b4c4d4e4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505152535455565758595a5b5c5d5e5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606162636465666768696a6b6c6d6e6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000707172737475767778797a7b7c7d7e7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808182838485868788898a8b8c8d8e8f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000909192939495969798999a9b9c9d9e9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a1a2a3a4a5a6a7a8a9aaabacadaeaf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b1b2b3b4b5b6b7b8b9babbbcbdbebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c1c2c3c4c5c6c7c8c9cacbcccdcecf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0d1d2d3d4d5d6d7d8d9dadbdcdddedf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0e1e2e3e4e5e6e7e8e9eaebecedeeef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory nibbleLow =
            hex"000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f00";
        bytes memory nibbleHigh =
            hex"000000000000000000000000000000000101010101010101010101010101010102020202020202020202020202020202030303030303030303030303030303030404040404040404040404040404040405050505050505050505050505050505060606060606060606060606060606060707070707070707070707070707070708080808080808080808080808080808090909090909090909090909090909090a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00";
        bytes memory addSum =
            hex"000102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0002030405060708090a0b0c0d0e0f0001030405060708090a0b0c0d0e0f0001020405060708090a0b0c0d0e0f0001020305060708090a0b0c0d0e0f0001020304060708090a0b0c0d0e0f0001020304050708090a0b0c0d0e0f0001020304050608090a0b0c0d0e0f0001020304050607090a0b0c0d0e0f0001020304050607080a0b0c0d0e0f000102030405060708090b0c0d0e0f000102030405060708090a0c0d0e0f000102030405060708090a0b0d0e0f000102030405060708090a0b0c0e0f000102030405060708090a0b0c0d0f000102030405060708090a0b0c0d0e0102030405060708090a0b0c0d0e0f0002030405060708090a0b0c0d0e0f0001030405060708090a0b0c0d0e0f0001020405060708090a0b0c0d0e0f0001020305060708090a0b0c0d0e0f0001020304060708090a0b0c0d0e0f0001020304050708090a0b0c0d0e0f0001020304050608090a0b0c0d0e0f0001020304050607090a0b0c0d0e0f0001020304050607080a0b0c0d0e0f000102030405060708090b0c0d0e0f000102030405060708090a0c0d0e0f000102030405060708090a0b0d0e0f000102030405060708090a0b0c0e0f000102030405060708090a0b0c0d0f000102030405060708090a0b0c0d0e000102030405060708090a0b0c0d0e0f00";
        bytes memory addCarry =
            hex"000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000101000000000000000000000000000101010000000000000000000000000101010100000000000000000000000101010101000000000000000000000101010101010000000000000000000101010101010100000000000000000101010101010101000000000000000101010101010101010000000000000101010101010101010100000000000101010101010101010101000000000101010101010101010101010000000101010101010101010101010100000101010101010101010101010101000101010101010101010101010101010000000000000000000000000000000100000000000000000000000000000101000000000000000000000000000101010000000000000000000000000101010100000000000000000000000101010101000000000000000000000101010101010000000000000000000101010101010100000000000000000101010101010101000000000000000101010101010101010000000000000101010101010101010100000000000101010101010101010101000000000101010101010101010101010000000101010101010101010101010100000101010101010101010101010101000101010101010101010101010101010101010101010101010101010101010100";
        bytes memory subRes =
            hex"000f0e0d0c0b0a09080706050403020101000f0e0d0c0b0a09080706050403020201000f0e0d0c0b0a09080706050403030201000f0e0d0c0b0a09080706050404030201000f0e0d0c0b0a09080706050504030201000f0e0d0c0b0a09080706060504030201000f0e0d0c0b0a09080707060504030201000f0e0d0c0b0a09080807060504030201000f0e0d0c0b0a09090807060504030201000f0e0d0c0b0a0a090807060504030201000f0e0d0c0b0b0a090807060504030201000f0e0d0c0c0b0a090807060504030201000f0e0d0d0c0b0a090807060504030201000f0e0e0d0c0b0a090807060504030201000f0f0e0d0c0b0a090807060504030201000f0e0d0c0b0a09080706050403020100000f0e0d0c0b0a09080706050403020101000f0e0d0c0b0a09080706050403020201000f0e0d0c0b0a09080706050403030201000f0e0d0c0b0a09080706050404030201000f0e0d0c0b0a09080706050504030201000f0e0d0c0b0a09080706060504030201000f0e0d0c0b0a09080707060504030201000f0e0d0c0b0a09080807060504030201000f0e0d0c0b0a09090807060504030201000f0e0d0c0b0a0a090807060504030201000f0e0d0c0b0b0a090807060504030201000f0e0d0c0c0b0a090807060504030201000f0e0d0d0c0b0a090807060504030201000f0e0e0d0c0b0a090807060504030201000f00";
        bytes memory subBorrow =
            hex"000101010101010101010101010101010000010101010101010101010101010100000001010101010101010101010101000000000101010101010101010101010000000000010101010101010101010100000000000001010101010101010101000000000000000101010101010101010000000000000000010101010101010100000000000000000001010101010101000000000000000000000101010101010000000000000000000000010101010100000000000000000000000001010101000000000000000000000000000101010000000000000000000000000000010100000000000000000000000000000001000000000000000000000000000000000101010101010101010101010101010100010101010101010101010101010101000001010101010101010101010101010000000101010101010101010101010100000000010101010101010101010101000000000001010101010101010101010000000000000101010101010101010100000000000000010101010101010101000000000000000001010101010101010000000000000000000101010101010100000000000000000000010101010101000000000000000000000001010101010000000000000000000000000101010100000000000000000000000000010101000000000000000000000000000001010000000000000000000000000000000100";
        bytes memory eq =
            hex"0100000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000100000000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000100";
        bytes memory and =
            hex"00000000000000000000000000000000000100010001000100010001000100010000020200000202000002020000020200010203000102030001020300010203000000000404040400000000040404040001000104050405000100010405040500000202040406060000020204040606000102030405060700010203040506070000000000000000080808080808080800010001000100010809080908090809000002020000020208080a0a08080a0a000102030001020308090a0b08090a0b0000000004040404080808080c0c0c0c0001000104050405080908090c0d0c0d000002020404060608080a0a0c0c0e0e000102030405060708090a0b0c0d0e0f00";
        bytes memory lt =
            hex"0201010101010101010101010101010100020101010101010101010101010101000002010101010101010101010101010000000201010101010101010101010100000000020101010101010101010101000000000002010101010101010101010000000000000201010101010101010100000000000000020101010101010101000000000000000002010101010101010000000000000000000201010101010100000000000000000000020101010101000000000000000000000002010101010000000000000000000000000201010100000000000000000000000000020101000000000000000000000000000002010000000000000000000000000000000200";

        return Tables({
            nibbleShift: _deployTable(nibbleShift),
            nibbleLow: _deployTable(nibbleLow),
            nibbleHigh: _deployTable(nibbleHigh),
            addSum: _deployTable(addSum),
            addCarry: _deployTable(addCarry),
            subRes: _deployTable(subRes),
            subBorrow: _deployTable(subBorrow),
            eq: _deployTable(eq),
            and: _deployTable(and),
            lt: _deployTable(lt)
        });
    }

    function _deployTable(bytes memory table) internal returns (address addr) {
        bytes memory initcode = bytes.concat(hex"61", bytes2(uint16(table.length)), hex"3d81600a3d39f3", table);
        assembly {
            addr := create2(0, add(initcode, 0x20), mload(initcode), 0)
        }
        require(addr != address(0), "Create failed");
    }
}

contract Opcodes {
    address private immutable NIBBLE_SHIFT;
    address private immutable NIBBLE_LOW;
    address private immutable NIBBLE_HIGH;
    address private immutable ADD_SUM;
    address private immutable ADD_CARRY;
    address private immutable SUB_RES;
    address private immutable SUB_BORROW;
    address private immutable EQ;
    address private immutable AND;
    address private immutable LT;

    constructor(Tables memory tables) {
        NIBBLE_SHIFT = tables.nibbleShift;
        NIBBLE_LOW = tables.nibbleLow;
        NIBBLE_HIGH = tables.nibbleHigh;
        ADD_SUM = tables.addSum;
        ADD_CARRY = tables.addCarry;
        SUB_RES = tables.subRes;
        SUB_BORROW = tables.subBorrow;
        EQ = tables.eq;
        AND = tables.and;
        LT = tables.lt;
    }

    // ----- ADD -----

    function _add8(uint8 a, uint8 b, bool carryIn) internal view returns (uint8 c, bool carryOut) {
        address nibbleShift = NIBBLE_SHIFT;
        address nibbleLow = NIBBLE_LOW;
        address nibbleHigh = NIBBLE_HIGH;
        address addSum = ADD_SUM;
        address addCarry = ADD_CARRY;

        // Note: The upper bits of a, b, carryIn MUST be clean
        assembly {
            // Zero out used space
            mstore(0x00, 0x00)
            mstore(0x20, 0x00)

            // Add low nibbles with carry-in 0
            extcodecopy(nibbleLow, 0x1e, a, 0x01)
            extcodecopy(nibbleLow, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_low || b_low
            mstore8(0x1e, carryIn) // carry-in
            extcodecopy(addSum, 0x3f, mload(0x00), 0x01) // sum_low
            extcodecopy(addCarry, 0x20, mload(0x00), 0x01) // carry_low

            // Add high nibbles with carry_low
            extcodecopy(nibbleHigh, 0x1e, a, 0x01)
            extcodecopy(nibbleHigh, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_high || b_high
            mstore8(0x1e, mload(0x01)) // carry_low
            extcodecopy(addSum, 0x3e, mload(0x00), 0x01) // sum_high
            extcodecopy(addCarry, 0x20, mload(0x00), 0x01) // carry_high

            // Get final result
            mstore(0x00, 0x00) // zero out upper bytes of carry
            carryOut := mload(0x01)
            mstore(0x1e, 0x00) // zero out upper bytes at 0x20
            extcodecopy(nibbleShift, 0x1f, mload(0x20), 0x01) // sum_high || sum_low
            c := mload(0x00)
        }
    }

    function _add256(uint256 a, uint256 b) internal view returns (uint256 c) {
        uint8 a_byte;
        uint8 b_byte;
        uint8 c_byte;
        bool carry = false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x20))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x20))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3f, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1f))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3e, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1e))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3d, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1d))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3c, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1c))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3b, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1b))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x3a, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1a))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x39, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x19))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x19))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x38, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x18))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x18))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x37, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x17))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x17))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x36, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x16))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x16))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x35, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x15))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x15))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x34, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x14))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x14))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x33, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x13))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x13))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x32, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x12))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x12))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x31, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x11))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x11))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x30, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x10))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x10))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2f, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0f))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2e, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0e))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2d, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0d))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2c, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0c))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2b, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0b))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x2a, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0a))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x29, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x09))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x09))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x28, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x08))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x08))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x27, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x07))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x07))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x26, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x06))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x06))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x25, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x05))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x05))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x24, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x04))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x04))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x23, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x03))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x03))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x22, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x02))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x02))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x21, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x01))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x01))
            b_byte := mload(0x00)
        }
        (c_byte, carry) = _add8(a_byte, b_byte, carry);
        assembly {
            mstore(0x20, c)
            mstore8(0x20, c_byte)
            c := mload(0x20)
        }
    }

    // ----- SUB -----

    function _sub8(uint8 a, uint8 b, bool borrowIn) internal view returns (uint8 c, bool borrowOut) {
        address nibbleShift = NIBBLE_SHIFT;
        address nibbleLow = NIBBLE_LOW;
        address nibbleHigh = NIBBLE_HIGH;
        address subRes = SUB_RES;
        address subBorrow = SUB_BORROW;

        // Note: The upper bits of a, b, borrowIn MUST be clean
        assembly {
            // Zero out used space
            mstore(0x00, 0x00)
            mstore(0x20, 0x00)

            // Subtract low nibbles with borrow-in
            extcodecopy(nibbleLow, 0x1e, a, 0x01)
            extcodecopy(nibbleLow, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_low || b_low
            mstore8(0x1e, borrowIn) // borrow-in
            extcodecopy(subRes, 0x3f, mload(0x00), 0x01) // diff_low
            extcodecopy(subBorrow, 0x20, mload(0x00), 0x01) // borrow_low

            // Subtract high nibbles with borrow_low
            extcodecopy(nibbleHigh, 0x1e, a, 0x01)
            extcodecopy(nibbleHigh, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_high || b_high
            mstore8(0x1e, mload(0x01)) // borrow_low
            extcodecopy(subRes, 0x3e, mload(0x00), 0x01) // diff_high
            extcodecopy(subBorrow, 0x20, mload(0x00), 0x01) // borrow_high

            // Get final result
            mstore(0x00, 0x00) // zero out upper bytes of borrow
            borrowOut := mload(0x01)
            mstore(0x1e, 0x00) // zero out upper bytes at 0x20
            extcodecopy(nibbleShift, 0x1f, mload(0x20), 0x01) // diff_high || diff_low
            c := mload(0x00)
        }
    }

    function _sub256(uint256 a, uint256 b) internal view returns (uint256 c) {
        uint8 a_byte;
        uint8 b_byte;
        uint8 c_byte;
        bool borrow = false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x20))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x20))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3f, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1f))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3e, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1e))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3d, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1d))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3c, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1c))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3b, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1b))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x3a, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1a))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x39, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x19))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x19))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x38, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x18))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x18))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x37, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x17))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x17))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x36, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x16))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x16))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x35, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x15))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x15))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x34, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x14))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x14))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x33, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x13))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x13))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x32, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x12))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x12))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x31, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x11))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x11))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x30, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x10))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x10))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2f, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0f))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2e, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0e))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2d, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0d))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2c, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0c))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2b, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0b))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x2a, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0a))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x29, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x09))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x09))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x28, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x08))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x08))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x27, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x07))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x07))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x26, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x06))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x06))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x25, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x05))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x05))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x24, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x04))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x04))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x23, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x03))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x03))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x22, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x02))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x02))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x21, c_byte)
            c := mload(0x20)
        }

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x01))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x01))
            b_byte := mload(0x00)
        }
        (c_byte, borrow) = _sub8(a_byte, b_byte, borrow);
        assembly {
            mstore(0x20, c)
            mstore8(0x20, c_byte)
            c := mload(0x20)
        }
    }

    // ----- EQ -----

    function _eq8(uint8 a, uint8 b) internal view returns (bool r) {
        address nibbleShift = NIBBLE_SHIFT;
        address nibbleLow = NIBBLE_LOW;
        address nibbleHigh = NIBBLE_HIGH;
        address eqTable = EQ;
        address andTable = AND;

        // Note: The upper bits of a, b MUST be clean
        assembly {
            // Zero out used space
            mstore(0x00, 0x00)
            mstore(0x20, 0x00)

            // Compare low nibbles
            extcodecopy(nibbleLow, 0x1e, a, 0x01)
            extcodecopy(nibbleLow, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_low || b_low
            mstore8(0x1e, 0x00)
            extcodecopy(eqTable, 0x3f, mload(0x00), 0x01) // a_eq: a_low == b_low

            // Compare high nibbles
            extcodecopy(nibbleHigh, 0x1e, a, 0x01)
            extcodecopy(nibbleHigh, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x1f, mload(0x00), 0x01) // a_high || b_high
            mstore8(0x1e, 0x00)
            extcodecopy(eqTable, 0x3e, mload(0x00), 0x01) // b_eq: a_high == b_high

            // Combine comparison results
            extcodecopy(nibbleShift, 0x3f, mload(0x20), 0x01) // a_eq || b_eq
            mstore8(0x3e, 0x00)
            extcodecopy(andTable, 0x3f, mload(0x20), 0x01) // a_eq & b_eq

            // Get final result
            r := mload(0x20)
        }
    }

    function _eq256(uint256 a, uint256 b) internal view returns (bool) {
        uint8 a_byte;
        uint8 b_byte;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x20))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x20))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1f))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1e))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1d))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1c))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1b))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x1a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x1a))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x19))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x19))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x18))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x18))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x17))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x17))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x16))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x16))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x15))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x15))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x14))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x14))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x13))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x13))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x12))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x12))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x11))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x11))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x10))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x10))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0f))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0f))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0e))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0e))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0d))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0d))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0c))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0c))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0b))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0b))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x0a))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x0a))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x09))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x09))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x08))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x08))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x07))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x07))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x06))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x06))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x05))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x05))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x04))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x04))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x03))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x03))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x02))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x02))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            mstore(0x20, a)
            mstore8(0x1f, mload(0x01))
            a_byte := mload(0x00)

            mstore(0x20, b)
            mstore8(0x1f, mload(0x01))
            b_byte := mload(0x00)
        }
        if (!_eq8(a_byte, b_byte)) return false;

        return true;
    }

    // ----- LT -----

    function _lt8(uint8 a, uint8 b) internal view returns (bool) {
        address nibbleShift = NIBBLE_SHIFT;
        address nibbleLow = NIBBLE_LOW;
        address nibbleHigh = NIBBLE_HIGH;
        address ltTable = LT;

        // Note: The upper bits of a, b MUST be clean
        uint8 r;
        assembly {
            // Zero out used space
            mstore(0x00, 0x00)

            // Compare high nibbles
            extcodecopy(nibbleHigh, 0x1e, a, 0x01)
            extcodecopy(nibbleHigh, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x3f, mload(0x00), 0x01) // a_high || b_high
            extcodecopy(ltTable, 0x3f, mload(0x20), 0x01) // a_high < b_high
            r := mload(0x20)
        }

        // Return early if high nibbles are not equal
        if (_eq8(r, 0)) return false;
        if (_eq8(r, 1)) return true;

        assembly {
            // Compare low nibbles
            extcodecopy(nibbleLow, 0x1e, a, 0x01)
            extcodecopy(nibbleLow, 0x1f, b, 0x01)
            extcodecopy(nibbleShift, 0x3f, mload(0x00), 0x01) // a_low || b_low
            extcodecopy(ltTable, 0x3f, mload(0x20), 0x01) // a_low < b_low
            r := mload(0x20)
        }

        return _eq8(r, 1);
    }

    function _lt256(uint256 a, uint256 b) internal view returns (bool) {
        uint8 a_byte;
        uint8 b_byte;

        assembly {
            a_byte := byte(0, a)
            b_byte := byte(0, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(1, a)
            b_byte := byte(1, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(2, a)
            b_byte := byte(2, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(3, a)
            b_byte := byte(3, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(4, a)
            b_byte := byte(4, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(5, a)
            b_byte := byte(5, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(6, a)
            b_byte := byte(6, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(7, a)
            b_byte := byte(7, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(8, a)
            b_byte := byte(8, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(9, a)
            b_byte := byte(9, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(10, a)
            b_byte := byte(10, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(11, a)
            b_byte := byte(11, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(12, a)
            b_byte := byte(12, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(13, a)
            b_byte := byte(13, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(14, a)
            b_byte := byte(14, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(15, a)
            b_byte := byte(15, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(16, a)
            b_byte := byte(16, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(17, a)
            b_byte := byte(17, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(18, a)
            b_byte := byte(18, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(19, a)
            b_byte := byte(19, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(20, a)
            b_byte := byte(20, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(21, a)
            b_byte := byte(21, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(22, a)
            b_byte := byte(22, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(23, a)
            b_byte := byte(23, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(24, a)
            b_byte := byte(24, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(25, a)
            b_byte := byte(25, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(26, a)
            b_byte := byte(26, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(27, a)
            b_byte := byte(27, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(28, a)
            b_byte := byte(28, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(29, a)
            b_byte := byte(29, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(30, a)
            b_byte := byte(30, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        assembly {
            a_byte := byte(31, a)
            b_byte := byte(31, b)
        }
        if (_lt8(a_byte, b_byte)) return true;
        if (!_eq8(a_byte, b_byte)) return false;

        return false;
    }

    // ----- GTE -----

    function _gte256(uint256 a, uint256 b) internal view returns (bool) {
        return !_lt256(a, b);
    }
}
