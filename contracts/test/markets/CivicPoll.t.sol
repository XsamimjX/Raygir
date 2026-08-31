// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CivicPoll } from "../../src/markets/CivicPoll.sol";
import { PollFactory } from "../../src/markets/PollFactory.sol";

contract CivicPollTest is Test {
    address private constant RELAY = address(0xBEEF);
    bytes32 private constant POLL_ID = keccak256("poll-1");
    bytes32 private constant MANIFEST = keccak256("bilingual-manifest");
    bytes32 private constant SALT = keccak256("salt");
    bytes32 private constant FIRST_SALT = keccak256("one");
    bytes32 private constant SECOND_SALT = keccak256("two");
    bytes32 private constant WRONG_SALT = keccak256("wrong");

    PollFactory private factory;
    CivicPoll private poll;

    function setUp() public {
        factory = new PollFactory(RELAY);
        poll = factory.createCivicPoll(
            POLL_ID,
            MANIFEST,
            uint64(block.timestamp + 10),
            uint64(block.timestamp + 100),
            uint64(block.timestamp + 150),
            3,
            2
        );
    }

    function testFactoryBindsImmutableManifestAndRules() public view {
        assertEq(factory.pollFor(POLL_ID), address(poll));
        assertEq(poll.pollId(), POLL_ID);
        assertEq(poll.manifestHash(), MANIFEST);
        assertEq(poll.optionCount(), 3);
        assertEq(poll.creditLimit(), 2);
    }

    function testEligibleRelayCanCommitCreditsOnce() public {
        vm.warp(block.timestamp + 10);
        bytes32 nullifier = keccak256("nullifier");
        uint32[] memory allocations = _allocations(1, 1, 0);

        vm.prank(RELAY);
        poll.commitBallot(nullifier, _commitment(nullifier, allocations, SALT), 2);

        assertTrue(poll.nullifierUsed(nullifier));
        assertEq(poll.committedCredits(), 2);

        vm.expectRevert(abi.encodeWithSelector(CivicPoll.NullifierAlreadyUsed.selector, nullifier));
        vm.prank(RELAY);
        poll.commitBallot(nullifier, keccak256("another-choice"), 1);
    }

    function testRejectsUnauthorizedOverLimitAndClosedBallots() public {
        vm.warp(block.timestamp + 10);
        vm.expectRevert(abi.encodeWithSelector(CivicPoll.UnauthorizedRelay.selector, address(this)));
        poll.commitBallot(keccak256("n1"), keccak256("c1"), 1);

        vm.expectRevert(CivicPoll.InvalidBallot.selector);
        vm.prank(RELAY);
        poll.commitBallot(keccak256("n2"), keccak256("c2"), 3);

        vm.warp(block.timestamp + 90);
        vm.expectRevert(abi.encodeWithSelector(CivicPoll.PollNotOpen.selector, block.timestamp));
        vm.prank(RELAY);
        poll.commitBallot(keccak256("n3"), keccak256("c3"), 1);
    }

    function testCannotReusePollId() public {
        vm.expectRevert(abi.encodeWithSelector(PollFactory.DuplicatePoll.selector, POLL_ID));
        factory.createCivicPoll(POLL_ID, MANIFEST, 1, 2, 3, 2, 1);
    }

    function testRevealAllocatesCreditsAndFinalizationConservesTallies() public {
        bytes32 firstNullifier = keccak256("first");
        bytes32 secondNullifier = keccak256("second");
        uint32[] memory first = _allocations(0, 2, 0);
        uint32[] memory second = _allocations(0, 1, 0);

        vm.warp(block.timestamp + 10);
        vm.startPrank(RELAY);
        poll.commitBallot(firstNullifier, _commitment(firstNullifier, first, FIRST_SALT), 2);
        poll.commitBallot(secondNullifier, _commitment(secondNullifier, second, SECOND_SALT), 1);

        vm.warp(block.timestamp + 90);
        poll.revealBallot(firstNullifier, first, FIRST_SALT);
        poll.revealBallot(secondNullifier, second, SECOND_SALT);
        vm.stopPrank();

        assertEq(poll.committedCredits(), 3);
        assertEq(poll.revealedCredits(), 3);
        assertEq(poll.optionCredits(1), 3);

        vm.warp(block.timestamp + 50);
        poll.finalize();
        assertTrue(poll.finalized());
        assertFalse(poll.tied());
        assertEq(poll.winningOption(), 1);
    }

    function testRejectsForgedDuplicateAndLateReveals() public {
        bytes32 nullifier = keccak256("reveal-nullifier");
        uint32[] memory allocations = _allocations(1, 0, 0);

        vm.warp(block.timestamp + 10);
        vm.prank(RELAY);
        poll.commitBallot(nullifier, _commitment(nullifier, allocations, SALT), 1);

        vm.warp(block.timestamp + 90);
        vm.expectRevert(CivicPoll.InvalidReveal.selector);
        vm.prank(RELAY);
        poll.revealBallot(nullifier, allocations, WRONG_SALT);

        vm.prank(RELAY);
        poll.revealBallot(nullifier, allocations, SALT);
        vm.expectRevert(abi.encodeWithSelector(CivicPoll.BallotAlreadyRevealed.selector, nullifier));
        vm.prank(RELAY);
        poll.revealBallot(nullifier, allocations, SALT);

        vm.warp(block.timestamp + 50);
        vm.expectRevert(abi.encodeWithSelector(CivicPoll.RevealNotOpen.selector, block.timestamp));
        vm.prank(RELAY);
        poll.revealBallot(keccak256("unknown"), allocations, SALT);
    }

    function testNoRevealsFinalizesWithoutAWinnerOrRunoff() public {
        vm.warp(poll.revealClosesAt());
        poll.finalize();

        assertTrue(poll.noWinner());
        assertFalse(poll.tied());
        assertEq(poll.revealedCredits(), 0);
    }

    function _commitment(bytes32 nullifier, uint32[] memory allocations, bytes32 salt)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(POLL_ID, nullifier, allocations, salt));
    }

    function _allocations(uint32 first, uint32 second, uint32 third)
        private
        pure
        returns (uint32[] memory values)
    {
        values = new uint32[](3);
        values[0] = first;
        values[1] = second;
        values[2] = third;
    }
}
