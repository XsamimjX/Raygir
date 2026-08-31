// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { CivicPoll } from "./CivicPoll.sol";

/// @notice Experimental governmental profile with one anonymous replacement ballot.
contract GovernmentElection is CivicPoll {
    bool public constant GOVERNMENT_CERTIFIED = false;
    bool public constant COERCION_RESISTANT = false;

    constructor(
        bytes32 initialPollId,
        bytes32 initialManifestHash,
        address initialProofRelay,
        uint64 initialOpensAt,
        uint64 initialClosesAt,
        uint64 initialRevealClosesAt,
        uint32 initialOptionCount,
        uint32 initialCreditLimit
    )
        CivicPoll(
            initialPollId,
            initialManifestHash,
            initialProofRelay,
            initialOpensAt,
            initialClosesAt,
            initialRevealClosesAt,
            initialOptionCount,
            initialCreditLimit,
            true,
            true
        )
    { }
}
