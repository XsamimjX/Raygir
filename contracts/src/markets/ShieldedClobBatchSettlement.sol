// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IClobBatchVerifier } from "./IClobBatchVerifier.sol";

/// @notice Replay-safe shielded CLOB state-root transitions authorized by a batch proof.
contract ShieldedClobBatchSettlement {
    IClobBatchVerifier public immutable verifier;
    address public immutable matcher;
    bytes32 public currentRoot;
    uint64 public nextSequence;
    mapping(bytes32 batchDigest => bool settled) public batchSettled;

    error InvalidConfiguration();
    error Unauthorized(address caller);
    error InvalidTransition();
    error InvalidProof();

    event BatchSettled(
        uint64 indexed sequence,
        bytes32 indexed batchDigest,
        bytes32 previousRoot,
        bytes32 nextRoot,
        uint128 publicFee,
        uint64 settlementTime,
        uint8 matchCount
    );

    constructor(
        IClobBatchVerifier initialVerifier,
        address initialMatcher,
        bytes32 initialRoot,
        uint64 initialSequence
    ) {
        if (address(initialVerifier) == address(0) || initialMatcher == address(0)) {
            revert InvalidConfiguration();
        }
        verifier = initialVerifier;
        matcher = initialMatcher;
        currentRoot = initialRoot;
        nextSequence = initialSequence;
    }

    function settle(
        bytes calldata proof,
        bytes32 previousRoot,
        bytes32 nextRoot,
        uint64 sequence,
        bytes32 batchDigest,
        uint128 publicFee,
        uint8 matchCount
    ) external {
        if (msg.sender != matcher) {
            revert Unauthorized(msg.sender);
        }
        if (
            previousRoot != currentRoot || nextRoot == bytes32(0) || sequence != nextSequence
                || batchDigest == bytes32(0) || batchSettled[batchDigest] || matchCount == 0
                || matchCount > 2
        ) {
            revert InvalidTransition();
        }
        uint64 settlementTime = uint64(block.timestamp);
        if (!verifier.verify(
                proof,
                previousRoot,
                nextRoot,
                sequence,
                batchDigest,
                publicFee,
                settlementTime,
                matchCount
            )) {
            revert InvalidProof();
        }

        batchSettled[batchDigest] = true;
        currentRoot = nextRoot;
        nextSequence = sequence + 1;
        emit BatchSettled(
            sequence, batchDigest, previousRoot, nextRoot, publicFee, settlementTime, matchCount
        );
    }
}
