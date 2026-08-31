// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library PariMutuelPayout {
    uint256 internal constant SCALE = 1e18;
    uint16 internal constant CREATOR_REWARD_BPS = 1_000;
    uint16 internal constant MAX_BOOST_BPS = 500;
    uint16 internal constant BPS = 10_000;

    error InvalidWindow();
    error InvalidBoost(uint16 boostBps);
    error InvalidCommitmentTime(uint64 committedAt);
    error InvalidCumulativeWeight();

    function creatorReward(uint256 totalPot) internal pure returns (uint256) {
        return Math.mulDiv(totalPot, CREATOR_REWARD_BPS, BPS);
    }

    function winnerPool(uint256 totalPot) internal pure returns (uint256) {
        return totalPot - creatorReward(totalPot);
    }

    function weightedStake(
        uint256 stake,
        uint64 opensAt,
        uint64 closesAt,
        uint64 committedAt,
        uint16 boostBps
    ) internal pure returns (uint256) {
        if (opensAt >= closesAt) {
            revert InvalidWindow();
        }
        if (boostBps > MAX_BOOST_BPS) {
            revert InvalidBoost(boostBps);
        }
        if (committedAt < opensAt || committedAt > closesAt) {
            revert InvalidCommitmentTime(committedAt);
        }

        uint256 remaining = closesAt - committedAt;
        uint256 duration = closesAt - opensAt;
        uint256 boost = Math.mulDiv(uint256(boostBps) * SCALE, remaining, duration * BPS);
        return Math.mulDiv(stake, SCALE + boost, SCALE);
    }

    function payoutSlice(
        uint256 distributablePool,
        uint256 previousCumulativeWeight,
        uint256 cumulativeWeight,
        uint256 totalWeight
    ) internal pure returns (uint256) {
        if (
            totalWeight == 0 || previousCumulativeWeight > cumulativeWeight
                || cumulativeWeight > totalWeight
        ) {
            revert InvalidCumulativeWeight();
        }

        return Math.mulDiv(distributablePool, cumulativeWeight, totalWeight)
            - Math.mulDiv(distributablePool, previousCumulativeWeight, totalWeight);
    }
}

