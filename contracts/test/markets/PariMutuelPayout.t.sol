// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { PariMutuelPayout } from "../../src/markets/PariMutuelPayout.sol";
import { PariMutuelPayoutHarness } from "../../src/markets/PariMutuelPayoutHarness.sol";

contract PariMutuelPayoutTest is Test {
    PariMutuelPayoutHarness private payout;

    function setUp() public {
        payout = new PariMutuelPayoutHarness();
    }

    function testCreatorGetsTenPercentOfWholePot() public view {
        assertEq(payout.creatorReward(1_000 ether), 100 ether);
        assertEq(payout.winnerPool(1_000 ether), 900 ether);
    }

    function testEarlyCommitmentGetsConfiguredMaximumBoost() public view {
        assertEq(payout.weightedStake(100 ether, 100, 200, 100, 100), 101 ether);
        assertEq(payout.weightedStake(100 ether, 100, 200, 200, 100), 100 ether);
        assertEq(payout.weightedStake(100 ether, 100, 200, 150, 100), 100.5 ether);
    }

    function testSplittingAStakeAtTheSameTimeDoesNotIncreaseWeight() public view {
        uint256 whole = payout.weightedStake(100 ether, 100, 200, 125, 100);
        uint256 first = payout.weightedStake(40 ether, 100, 200, 125, 100);
        uint256 second = payout.weightedStake(60 ether, 100, 200, 125, 100);

        assertEq(first + second, whole);
    }

    function testRoundingAssignsEveryUnitExactlyOnce() public view {
        uint256 pool = 17;
        uint256 first = payout.payoutSlice(pool, 0, 1, 6);
        uint256 second = payout.payoutSlice(pool, 1, 3, 6);
        uint256 third = payout.payoutSlice(pool, 3, 6, 6);

        assertEq(first + second + third, pool);
    }

    function testFuzzCumulativePayoutConservesWinnerPool(
        uint128 totalPot,
        uint64 firstWeight,
        uint64 secondWeight,
        uint64 thirdWeight
    ) public view {
        firstWeight = uint64(bound(firstWeight, 1, type(uint32).max));
        secondWeight = uint64(bound(secondWeight, 1, type(uint32).max));
        thirdWeight = uint64(bound(thirdWeight, 1, type(uint32).max));

        uint256 totalWeight = uint256(firstWeight) + secondWeight + thirdWeight;
        uint256 pool = payout.winnerPool(totalPot);
        uint256 first = payout.payoutSlice(pool, 0, firstWeight, totalWeight);
        uint256 second =
            payout.payoutSlice(pool, firstWeight, firstWeight + secondWeight, totalWeight);
        uint256 third =
            payout.payoutSlice(pool, firstWeight + secondWeight, totalWeight, totalWeight);

        assertEq(payout.creatorReward(totalPot) + first + second + third, totalPot);
    }

    function testRejectsBoostAboveFivePercent() public {
        vm.expectRevert(abi.encodeWithSelector(PariMutuelPayout.InvalidBoost.selector, 501));
        payout.weightedStake(100 ether, 100, 200, 100, 501);
    }
}
