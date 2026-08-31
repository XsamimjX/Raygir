// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { MarketResolutionManager } from "../../src/markets/MarketResolutionManager.sol";

contract MarketResolutionManagerTest is Test {
    address private constant ORACLE = address(0x0A1);
    address private constant TREASURY = address(0x7EA5);
    address private constant CHALLENGER = address(0xCA11);
    uint256 private constant BOND = 1 ether;
    bytes32 private constant MARKET = keccak256("market");
    MarketResolutionManager private manager;
    address[5] private members =
        [address(0x101), address(0x102), address(0x103), address(0x104), address(0x105)];

    function setUp() public {
        manager = new MarketResolutionManager(ORACLE, TREASURY, members, BOND);
        vm.deal(CHALLENGER, BOND * 2);
    }

    function testThreeOfFiveFinalizesAfterChallengePeriod() public {
        _propose();
        for (uint256 i; i < 3; ++i) {
            vm.prank(members[i]);
            manager.approve(MARKET);
        }
        vm.warp(block.timestamp + 48 hours);
        manager.finalize(MARKET);
        (,,,,, bool finalized,) = manager.proposals(MARKET);
        assertTrue(finalized);
    }

    function testChallengePreventsAutomaticFinalizationAndTimeoutInvalidates() public {
        _propose();
        for (uint256 i; i < 3; ++i) {
            vm.prank(members[i]);
            manager.approve(MARKET);
        }
        vm.prank(CHALLENGER);
        manager.challenge{ value: BOND }(MARKET, keccak256("reason"));
        vm.warp(block.timestamp + 48 hours);
        vm.expectRevert(MarketResolutionManager.NotFinalizable.selector);
        manager.finalize(MARKET);
        vm.warp(block.timestamp + 7 days);
        manager.invalidateTimedOut(MARKET);
        (,,,,,, bool invalid) = manager.proposals(MARKET);
        assertTrue(invalid);
        assertEq(manager.bondCredits(CHALLENGER), BOND);
    }

    function testChallengeRequiresExactBondAndThreeResolversCanUpholdIt() public {
        _propose();
        vm.prank(CHALLENGER);
        vm.expectRevert(MarketResolutionManager.InvalidBond.selector);
        manager.challenge(MARKET, keccak256("reason"));

        vm.prank(CHALLENGER);
        manager.challenge{ value: BOND }(MARKET, keccak256("reason"));
        for (uint256 i; i < 3; ++i) {
            vm.prank(members[i]);
            manager.reviewChallenge(MARKET, true, keccak256(abi.encode("upheld", i)));
        }

        (,,,,,, bool invalid) = manager.proposals(MARKET);
        assertTrue(invalid);
        assertEq(manager.bondCredits(CHALLENGER), BOND);

        uint256 before = CHALLENGER.balance;
        vm.prank(CHALLENGER);
        manager.withdrawBondCredit();
        assertEq(CHALLENGER.balance, before + BOND);
    }

    function testRejectedChallengeForfeitsBondAndAllowsFinalization() public {
        _propose();
        for (uint256 i; i < 3; ++i) {
            vm.prank(members[i]);
            manager.approve(MARKET);
        }
        vm.prank(CHALLENGER);
        manager.challenge{ value: BOND }(MARKET, keccak256("reason"));
        for (uint256 i; i < 3; ++i) {
            vm.prank(members[i]);
            manager.reviewChallenge(MARKET, false, keccak256(abi.encode("rejected", i)));
        }

        assertEq(manager.bondCredits(TREASURY), BOND);
        vm.warp(block.timestamp + 48 hours);
        manager.finalize(MARKET);
        (,,,,, bool finalized,) = manager.proposals(MARKET);
        assertTrue(finalized);
    }

    function testResolverCannotReviewAChallengeTwice() public {
        _propose();
        vm.prank(CHALLENGER);
        manager.challenge{ value: BOND }(MARKET, keccak256("reason"));
        vm.startPrank(members[0]);
        manager.reviewChallenge(MARKET, true, keccak256("first"));
        vm.expectRevert(MarketResolutionManager.DuplicateChallengeReview.selector);
        manager.reviewChallenge(MARKET, false, keccak256("second"));
        vm.stopPrank();
    }

    function testReportsAreNullifiedAndPauseAtAdaptiveThreshold() public {
        for (uint256 i; i < 5; ++i) {
            manager.report(MARKET, bytes32(i + 1), 20);
        }
        assertTrue(manager.paused(MARKET));
        vm.expectRevert(MarketResolutionManager.DuplicateReport.selector);
        manager.report(MARKET, bytes32(uint256(1)), 20);
    }

    function _propose() private {
        vm.prank(ORACLE);
        manager.propose(MARKET, keccak256("yes"), keccak256("evidence"));
    }
}
