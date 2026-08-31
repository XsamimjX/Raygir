// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @notice Poll-scoped nullifier and anonymous commitment ledger for eligibility proofs.
contract CivicPoll {
    bytes32 public immutable pollId;
    bytes32 public immutable manifestHash;
    address public immutable proofRelay;
    uint64 public immutable opensAt;
    uint64 public immutable closesAt;
    uint64 public immutable revealClosesAt;
    uint32 public immutable optionCount;
    uint32 public immutable creditLimit;
    bool public immutable replacementAllowed;
    bool public immutable tieRequiresRunoff;

    mapping(bytes32 nullifier => bool used) public nullifierUsed;
    mapping(bytes32 nullifier => bytes32 commitment) public ballotCommitment;
    mapping(bytes32 nullifier => uint32 credits) public ballotCredits;
    mapping(bytes32 nullifier => bool revealed) public ballotRevealed;
    mapping(bytes32 nullifier => bytes32 voterTag) public voterTagForNullifier;
    mapping(bytes32 voterTag => bool used) public voterTagUsed;
    mapping(bytes32 voterTag => uint8 revision) public latestRevision;
    mapping(bytes32 voterTag => bytes32 nullifier) public activeNullifier;
    mapping(uint32 option => uint256 credits) public optionCredits;
    uint256 public committedCredits;
    uint256 public revealedCredits;
    bool public finalized;
    bool public tied;
    bool public noWinner;
    uint32 public winningOption;

    error InvalidConfiguration();
    error UnauthorizedRelay(address caller);
    error PollNotOpen(uint256 timestamp);
    error RevealNotOpen(uint256 timestamp);
    error InvalidBallot();
    error NullifierAlreadyUsed(bytes32 nullifier);
    error BallotAlreadyRevealed(bytes32 nullifier);
    error InvalidReveal();
    error InvalidRevision();
    error FinalizationNotReady();

    event BallotCommitted(
        bytes32 indexed nullifier,
        bytes32 indexed choiceCommitment,
        uint32 credits,
        bytes32 indexed voterTag,
        uint8 revision
    );
    event BallotRevealed(bytes32 indexed nullifier, uint32[] optionCredits);
    event PollFinalized(uint32 winningOption, bool tied, uint256 revealedCredits);

    constructor(
        bytes32 initialPollId,
        bytes32 initialManifestHash,
        address initialProofRelay,
        uint64 initialOpensAt,
        uint64 initialClosesAt,
        uint64 initialRevealClosesAt,
        uint32 initialOptionCount,
        uint32 initialCreditLimit,
        bool initialReplacementAllowed,
        bool initialTieRequiresRunoff
    ) {
        if (
            initialPollId == bytes32(0) || initialManifestHash == bytes32(0)
                || initialProofRelay == address(0) || initialOpensAt >= initialClosesAt
                || initialClosesAt >= initialRevealClosesAt || initialOptionCount < 2
                || initialCreditLimit == 0
        ) {
            revert InvalidConfiguration();
        }

        pollId = initialPollId;
        manifestHash = initialManifestHash;
        proofRelay = initialProofRelay;
        opensAt = initialOpensAt;
        closesAt = initialClosesAt;
        revealClosesAt = initialRevealClosesAt;
        optionCount = initialOptionCount;
        creditLimit = initialCreditLimit;
        replacementAllowed = initialReplacementAllowed;
        tieRequiresRunoff = initialTieRequiresRunoff;
    }

    function commitBallot(bytes32 nullifier, bytes32 choiceCommitment, uint32 credits) external {
        _commitBallot(nullifier, nullifier, 0, choiceCommitment, credits);
    }

    function commitBallotRevision(
        bytes32 voterTag,
        uint8 revision,
        bytes32 nullifier,
        bytes32 choiceCommitment,
        uint32 credits
    ) external {
        _commitBallot(nullifier, voterTag, revision, choiceCommitment, credits);
    }

    function _commitBallot(
        bytes32 nullifier,
        bytes32 voterTag,
        uint8 revision,
        bytes32 choiceCommitment,
        uint32 credits
    ) private {
        if (msg.sender != proofRelay) {
            revert UnauthorizedRelay(msg.sender);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < opensAt || block.timestamp >= closesAt) {
            revert PollNotOpen(block.timestamp);
        }
        if (
            nullifier == bytes32(0) || voterTag == bytes32(0) || choiceCommitment == bytes32(0)
                || credits == 0 || credits > creditLimit
        ) {
            revert InvalidBallot();
        }
        if (nullifierUsed[nullifier]) {
            revert NullifierAlreadyUsed(nullifier);
        }
        if (
            (!voterTagUsed[voterTag] && revision != 0)
                || (voterTagUsed[voterTag]
                    && (!replacementAllowed || revision != 1 || latestRevision[voterTag] != 0))
        ) {
            revert InvalidRevision();
        }

        if (voterTagUsed[voterTag]) {
            committedCredits -= ballotCredits[activeNullifier[voterTag]];
        }

        nullifierUsed[nullifier] = true;
        ballotCommitment[nullifier] = choiceCommitment;
        ballotCredits[nullifier] = credits;
        voterTagForNullifier[nullifier] = voterTag;
        voterTagUsed[voterTag] = true;
        latestRevision[voterTag] = revision;
        activeNullifier[voterTag] = nullifier;
        committedCredits += credits;
        emit BallotCommitted(nullifier, choiceCommitment, credits, voterTag, revision);
    }

    function revealBallot(bytes32 nullifier, uint32[] calldata allocations, bytes32 salt) external {
        if (msg.sender != proofRelay) {
            revert UnauthorizedRelay(msg.sender);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < closesAt || block.timestamp >= revealClosesAt) {
            revert RevealNotOpen(block.timestamp);
        }
        if (
            !nullifierUsed[nullifier] || ballotRevealed[nullifier]
                || activeNullifier[voterTagForNullifier[nullifier]] != nullifier
                || allocations.length != optionCount
        ) {
            if (ballotRevealed[nullifier]) {
                revert BallotAlreadyRevealed(nullifier);
            }
            revert InvalidReveal();
        }

        uint256 total;
        for (uint32 option; option < optionCount; ++option) {
            total += allocations[option];
        }
        if (
            total != ballotCredits[nullifier]
                || keccak256(abi.encode(pollId, nullifier, allocations, salt))
                    != ballotCommitment[nullifier]
        ) {
            revert InvalidReveal();
        }

        ballotRevealed[nullifier] = true;
        revealedCredits += total;
        for (uint32 option; option < optionCount; ++option) {
            optionCredits[option] += allocations[option];
        }
        emit BallotRevealed(nullifier, allocations);
    }

    function finalize() external {
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < revealClosesAt || finalized) {
            revert FinalizationNotReady();
        }

        uint256 highest;
        uint32 winner;
        bool hasTie;
        for (uint32 option; option < optionCount; ++option) {
            uint256 tally = optionCredits[option];
            if (tally > highest) {
                highest = tally;
                winner = option;
                hasTie = false;
            } else if (tally == highest) {
                hasTie = true;
            }
        }

        finalized = true;
        noWinner = highest == 0;
        tied = !noWinner && hasTie && tieRequiresRunoff;
        winningOption = winner;
        emit PollFinalized(winner, tied, revealedCredits);
    }
}
