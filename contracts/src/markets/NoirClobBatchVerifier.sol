// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IClobBatchVerifier } from "./IClobBatchVerifier.sol";
import { INoirVerifier } from "./INoirVerifier.sol";

/// @notice Adapts the pinned Noir CLOB authorization circuit public-input order.
contract NoirClobBatchVerifier is IClobBatchVerifier {
    INoirVerifier public immutable noirVerifier;

    error InvalidConfiguration();

    constructor(INoirVerifier initialNoirVerifier) {
        if (address(initialNoirVerifier) == address(0)) {
            revert InvalidConfiguration();
        }
        noirVerifier = initialNoirVerifier;
    }

    function verify(
        bytes calldata proof,
        bytes32 previousRoot,
        bytes32 nextRoot,
        uint64 sequence,
        bytes32 batchDigest,
        uint128 publicFee,
        uint64 settlementTime,
        uint8 matchCount
    ) external view returns (bool) {
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = previousRoot;
        publicInputs[1] = bytes32(uint256(sequence));
        publicInputs[2] = bytes32(uint256(publicFee));
        publicInputs[3] = bytes32(uint256(settlementTime));
        publicInputs[4] = bytes32(uint256(matchCount));
        publicInputs[5] = batchDigest;
        publicInputs[6] = nextRoot;

        try noirVerifier.verify(proof, publicInputs) returns (bool valid) {
            return valid;
        } catch {
            return false;
        }
    }
}
