// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { CivicPoll } from "./CivicPoll.sol";

/// @notice Deploys immutable CivicPoll versions from reviewed bilingual manifest hashes.
contract PollFactory {
    address public immutable proofRelay;
    mapping(bytes32 pollId => address poll) public pollFor;

    error InvalidConfiguration();
    error DuplicatePoll(bytes32 pollId);

    event CivicPollCreated(bytes32 indexed pollId, address indexed poll, bytes32 manifestHash);

    constructor(address initialProofRelay) {
        if (initialProofRelay == address(0)) {
            revert InvalidConfiguration();
        }

        proofRelay = initialProofRelay;
    }

    function createCivicPoll(
        bytes32 pollId,
        bytes32 manifestHash,
        uint64 opensAt,
        uint64 closesAt,
        uint64 revealClosesAt,
        uint32 optionCount,
        uint32 creditLimit
    ) external returns (CivicPoll poll) {
        if (pollFor[pollId] != address(0)) {
            revert DuplicatePoll(pollId);
        }

        poll = new CivicPoll{ salt: pollId }(
            pollId,
            manifestHash,
            proofRelay,
            opensAt,
            closesAt,
            revealClosesAt,
            optionCount,
            creditLimit,
            false,
            true
        );
        pollFor[pollId] = address(poll);
        emit CivicPollCreated(pollId, address(poll), manifestHash);
    }
}
