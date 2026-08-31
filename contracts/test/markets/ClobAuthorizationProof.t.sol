// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { HonkVerifier } from "../../src/generated/ClobAuthorizationVerifier.sol";
import { INoirVerifier } from "../../src/markets/INoirVerifier.sol";
import { NoirClobBatchVerifier } from "../../src/markets/NoirClobBatchVerifier.sol";
import { ShieldedClobBatchSettlement } from "../../src/markets/ShieldedClobBatchSettlement.sol";

contract ClobAuthorizationProofTest is Test {
    function testGeneratedVerifierAcceptsPinnedAuthorizationProof() public {
        vm.warp(900);
        HonkVerifier generatedVerifier = new HonkVerifier();
        NoirClobBatchVerifier adapter =
            new NoirClobBatchVerifier(INoirVerifier(address(generatedVerifier)));
        bytes memory proof = vm.readFileBinary("test/fixtures/ClobAuthorization.proof");

        assertTrue(
            adapter.verify(
                proof,
                hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
                hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a",
                7,
                hex"0f9416d5b665fce42f83697b286b8cfe530cf160e0459f76cb77af7b3287a897",
                0,
                900,
                2
            )
        );

        assertFalse(
            adapter.verify(
                proof,
                hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
                hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a",
                8,
                hex"0f9416d5b665fce42f83697b286b8cfe530cf160e0459f76cb77af7b3287a897",
                0,
                900,
                2
            )
        );
        assertFalse(
            adapter.verify(
                proof,
                hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
                hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a",
                7,
                hex"0f9416d5b665fce42f83697b286b8cfe530cf160e0459f76cb77af7b3287a897",
                0,
                900,
                1
            )
        );
        assertFalse(
            adapter.verify(
                proof,
                hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
                hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a",
                7,
                hex"0f9416d5b665fce42f83697b286b8cfe530cf160e0459f76cb77af7b3287a897",
                0,
                899,
                2
            )
        );

        ShieldedClobBatchSettlement settlement =
            new ShieldedClobBatchSettlement(
                adapter,
                address(this),
                hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
                7
            );
        settlement.settle(
            proof,
            hex"2a8a30c5e8b74da38321419ba21f51e995771eabf748b63fe5878390cc413457",
            hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a",
            7,
            hex"0f9416d5b665fce42f83697b286b8cfe530cf160e0459f76cb77af7b3287a897",
            0,
            2
        );
        assertEq(
            settlement.currentRoot(),
            hex"18df1ea58e8441a8427086eae68b1cf140d0c2f57c6517709338469ef16cb82a"
        );
    }
}
