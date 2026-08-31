// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface IClobBatchVerifier {
    function verify(
        bytes calldata proof,
        bytes32 previousRoot,
        bytes32 nextRoot,
        uint64 sequence,
        bytes32 batchDigest,
        uint128 publicFee,
        uint64 settlementTime,
        uint8 matchCount
    ) external view returns (bool);
}
