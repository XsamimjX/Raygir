// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CivicPoll } from "../../src/markets/CivicPoll.sol";
import { GovernmentElection } from "../../src/markets/GovernmentElection.sol";
import { GovernmentElectionFactory } from "../../src/markets/GovernmentElectionFactory.sol";

contract GovernmentElectionTest is Test {
    address private constant RELAY = address(0xBEEF);
    bytes32 private constant VOTER_TAG = keccak256("anonymous-replacement-tag");
    bytes32 private constant FIRST_NULLIFIER = keccak256("revision-zero");
    bytes32 private constant SECOND_NULLIFIER = keccak256("revision-one");
    bytes32 private constant FIRST_SALT = keccak256("first-salt");
    bytes32 private constant SECOND_SALT = keccak256("second-salt");

    uint256[5] private authorityKeys = [uint256(11), 12, 13, 14, 15];
    GovernmentElectionFactory private factory;

    function setUp() public {
        address[5] memory authorities;
        for (uint256 i; i < authorities.length; ++i) {
            authorities[i] = vm.addr(authorityKeys[i]);
        }
        factory = new GovernmentElectionFactory(RELAY, authorities);
    }

    function testRequiresThreeDistinctAuthoritySignatures() public {
        GovernmentElectionFactory.ElectionConfig memory config = _config(keccak256("official"));
        bytes32 digest = factory.manifestDigest(config);
        bytes[] memory signatures = new bytes[](3);
        signatures[0] = _sign(authorityKeys[0], digest);
        signatures[1] = _sign(authorityKeys[1], digest);
        signatures[2] = _sign(authorityKeys[1], digest);

        vm.expectRevert(GovernmentElectionFactory.InvalidManifestSignatures.selector);
        factory.createElection(config, signatures);

        signatures[2] = _sign(authorityKeys[2], digest);
        GovernmentElection election = factory.createElection(config, signatures);
        assertEq(factory.electionFor(config.pollId), address(election));
        assertFalse(election.GOVERNMENT_CERTIFIED());
        assertFalse(election.COERCION_RESISTANT());
    }

    function testManifestSignaturesCannotAuthorizeChangedTerms() public {
        GovernmentElectionFactory.ElectionConfig memory config = _config(keccak256("original"));
        bytes[] memory signatures = _thresholdSignatures(factory.manifestDigest(config));
        config.optionCount = 3;

        vm.expectRevert(GovernmentElectionFactory.InvalidManifestSignatures.selector);
        factory.createElection(config, signatures);
    }

    function testOnlyRevisionOneReplacesRevisionZeroAndOnlyLatestReveals() public {
        GovernmentElection election = _createElection(keccak256("replacement"));
        uint32[] memory first = _allocations(1, 0);
        uint32[] memory second = _allocations(0, 1);

        vm.warp(block.timestamp + 10);
        vm.startPrank(RELAY);
        election.commitBallotRevision(
            VOTER_TAG,
            0,
            FIRST_NULLIFIER,
            _commitment(election.pollId(), FIRST_NULLIFIER, first, FIRST_SALT),
            1
        );
        election.commitBallotRevision(
            VOTER_TAG,
            1,
            SECOND_NULLIFIER,
            _commitment(election.pollId(), SECOND_NULLIFIER, second, SECOND_SALT),
            1
        );

        vm.expectRevert(CivicPoll.InvalidRevision.selector);
        election.commitBallotRevision(
            VOTER_TAG, 1, keccak256("third"), keccak256("third-commitment"), 1
        );
        assertEq(election.committedCredits(), 1);

        vm.warp(block.timestamp + 90);
        vm.expectRevert(CivicPoll.InvalidReveal.selector);
        election.revealBallot(FIRST_NULLIFIER, first, FIRST_SALT);
        election.revealBallot(SECOND_NULLIFIER, second, SECOND_SALT);
        vm.stopPrank();

        assertEq(election.revealedCredits(), 1);
        assertEq(election.optionCredits(0), 0);
        assertEq(election.optionCredits(1), 1);
    }

    function testTieRequiresRunoffAndUnrevealedCreditsDoNotEnterTallies() public {
        GovernmentElection election = _createElection(keccak256("runoff"));
        uint32[] memory split = _allocations(1, 1);
        bytes32 commitment = _commitment(election.pollId(), FIRST_NULLIFIER, split, FIRST_SALT);

        vm.warp(block.timestamp + 10);
        vm.prank(RELAY);
        election.commitBallot(FIRST_NULLIFIER, commitment, 2);

        vm.warp(block.timestamp + 90);
        vm.prank(RELAY);
        election.revealBallot(FIRST_NULLIFIER, split, FIRST_SALT);
        vm.warp(block.timestamp + 50);
        election.finalize();

        assertTrue(election.tied());
        assertEq(election.revealedCredits(), 2);
        assertEq(election.committedCredits(), 2);
    }

    function _createElection(bytes32 pollId) private returns (GovernmentElection) {
        GovernmentElectionFactory.ElectionConfig memory config = _config(pollId);

        return factory.createElection(config, _thresholdSignatures(factory.manifestDigest(config)));
    }

    function _config(bytes32 pollId)
        private
        view
        returns (GovernmentElectionFactory.ElectionConfig memory)
    {
        return GovernmentElectionFactory.ElectionConfig({
            pollId: pollId,
            manifestHash: keccak256(abi.encode("bilingual-official-manifest", pollId)),
            opensAt: uint64(block.timestamp + 10),
            closesAt: uint64(block.timestamp + 100),
            revealClosesAt: uint64(block.timestamp + 150),
            optionCount: 2,
            creditLimit: 2
        });
    }

    function _thresholdSignatures(bytes32 digest) private view returns (bytes[] memory signatures) {
        signatures = new bytes[](3);
        for (uint256 i; i < signatures.length; ++i) {
            signatures[i] = _sign(authorityKeys[i], digest);
        }
    }

    function _sign(uint256 key, bytes32 digest) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);

        return abi.encodePacked(r, s, v);
    }

    function _commitment(
        bytes32 pollId,
        bytes32 nullifier,
        uint32[] memory allocations,
        bytes32 salt
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(pollId, nullifier, allocations, salt));
    }

    function _allocations(uint32 first, uint32 second)
        private
        pure
        returns (uint32[] memory values)
    {
        values = new uint32[](2);
        values[0] = first;
        values[1] = second;
    }
}
