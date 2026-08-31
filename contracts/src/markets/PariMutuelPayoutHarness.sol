// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { PariMutuelPayout } from "./PariMutuelPayout.sol";

/// @notice Stateless public surface used by protocol contracts and deterministic clients.
contract PariMutuelPayoutHarness {
    function creatorReward(uint256 totalPot) external pure returns (uint256) {
        return PariMutuelPayout.creatorReward(totalPot);
    }

    function winnerPool(uint256 totalPot) external pure returns (uint256) {
        return PariMutuelPayout.winnerPool(totalPot);
    }

    function weightedStake(
        uint256 stake,
        uint64 opensAt,
        uint64 closesAt,
        uint64 committedAt,
        uint16 boostBps
    ) external pure returns (uint256) {
        return PariMutuelPayout.weightedStake(stake, opensAt, closesAt, committedAt, boostBps);
    }

    function payoutSlice(
        uint256 distributablePool,
        uint256 previousCumulativeWeight,
        uint256 cumulativeWeight,
        uint256 totalWeight
    ) external pure returns (uint256) {
        return PariMutuelPayout.payoutSlice(
            distributablePool, previousCumulativeWeight, cumulativeWeight, totalWeight
        );
    }
}

