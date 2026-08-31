// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @notice Fixed 3-of-5 resolver approvals, bonded challenges, and timeout invalidation.
contract MarketResolutionManager {
    uint64 public constant CHALLENGE_PERIOD = 48 hours;
    uint64 public constant QUORUM_TIMEOUT = 7 days;
    uint8 public constant QUORUM = 3;

    struct Proposal {
        bytes32 outcome;
        bytes32 evidenceHash;
        uint64 proposedAt;
        uint8 approvals;
        bool challenged;
        bool finalized;
        bool invalid;
    }

    struct Challenge {
        address challenger;
        bytes32 reasonHash;
        uint128 bond;
        uint8 upholdVotes;
        uint8 rejectVotes;
        bool resolved;
    }

    address public immutable oracle;
    address public immutable treasury;
    uint256 public immutable challengeBond;
    mapping(address resolver => bool authorized) public resolver;
    mapping(bytes32 marketId => Proposal proposal) public proposals;
    mapping(bytes32 marketId => mapping(address resolver => bool approved)) public approvals;
    mapping(bytes32 reportNullifier => bool used) public reportNullifierUsed;
    mapping(bytes32 marketId => uint256 count) public reportCount;
    mapping(bytes32 marketId => bool paused) public paused;
    mapping(bytes32 marketId => Challenge challengeData) public challenges;
    mapping(bytes32 marketId => mapping(address resolver => bool reviewed)) public
        challengeReviewed;
    mapping(address account => uint256 amount) public bondCredits;

    error InvalidConfiguration();
    error Unauthorized(address caller);
    error InvalidProposal();
    error DuplicateApproval();
    error DuplicateReport();
    error ChallengeWindowClosed();
    error InvalidBond();
    error DuplicateChallengeReview();
    error TransferFailed();
    error NotFinalizable();

    event Proposed(bytes32 indexed marketId, bytes32 outcome, bytes32 evidenceHash);
    event Approved(bytes32 indexed marketId, address indexed resolver, uint8 approvals);
    event Challenged(bytes32 indexed marketId, bytes32 reasonHash);
    event ChallengeReviewed(
        bytes32 indexed marketId, address indexed resolver, bool uphold, bytes32 reasoningHash
    );
    event ChallengeResolved(bytes32 indexed marketId, bool upheld);
    event BondWithdrawn(address indexed account, uint256 amount);
    event Finalized(bytes32 indexed marketId, bytes32 outcome);
    event Invalidated(bytes32 indexed marketId);
    event Reported(bytes32 indexed marketId, bytes32 indexed nullifier, uint256 count, bool paused);

    constructor(
        address initialOracle,
        address initialTreasury,
        address[5] memory initialResolvers,
        uint256 initialChallengeBond
    ) {
        if (
            initialOracle == address(0) || initialTreasury == address(0)
                || initialChallengeBond == 0 || initialChallengeBond > type(uint128).max
        ) {
            revert InvalidConfiguration();
        }
        oracle = initialOracle;
        treasury = initialTreasury;
        challengeBond = initialChallengeBond;
        for (uint256 i; i < initialResolvers.length; ++i) {
            address member = initialResolvers[i];
            if (member == address(0) || resolver[member]) {
                revert InvalidConfiguration();
            }
            resolver[member] = true;
        }
    }

    function propose(bytes32 marketId, bytes32 outcome, bytes32 evidenceHash) external {
        if (msg.sender != oracle) {
            revert Unauthorized(msg.sender);
        }
        if (
            marketId == bytes32(0) || outcome == bytes32(0) || evidenceHash == bytes32(0)
                || proposals[marketId].proposedAt != 0
        ) {
            revert InvalidProposal();
        }
        // forge-lint: disable-next-line(block-timestamp)
        proposals[marketId] =
            Proposal(outcome, evidenceHash, uint64(block.timestamp), 0, false, false, false);
        emit Proposed(marketId, outcome, evidenceHash);
    }

    function approve(bytes32 marketId) external {
        if (!resolver[msg.sender]) {
            revert Unauthorized(msg.sender);
        }
        Proposal storage proposal = proposals[marketId];
        if (proposal.proposedAt == 0 || proposal.finalized || proposal.invalid) {
            revert InvalidProposal();
        }
        if (approvals[marketId][msg.sender]) {
            revert DuplicateApproval();
        }
        approvals[marketId][msg.sender] = true;
        ++proposal.approvals;
        emit Approved(marketId, msg.sender, proposal.approvals);
    }

    function challenge(bytes32 marketId, bytes32 reasonHash) external payable {
        Proposal storage proposal = proposals[marketId];
        // forge-lint: disable-next-line(block-timestamp)
        if (
            proposal.proposedAt == 0 || block.timestamp >= proposal.proposedAt + CHALLENGE_PERIOD
                || proposal.challenged || reasonHash == bytes32(0)
        ) {
            revert ChallengeWindowClosed();
        }
        if (msg.value != challengeBond) {
            revert InvalidBond();
        }
        proposal.challenged = true;
        challenges[marketId] = Challenge(msg.sender, reasonHash, uint128(msg.value), 0, 0, false);
        emit Challenged(marketId, reasonHash);
    }

    function reviewChallenge(bytes32 marketId, bool uphold, bytes32 reasoningHash) external {
        if (!resolver[msg.sender]) {
            revert Unauthorized(msg.sender);
        }
        Proposal storage proposal = proposals[marketId];
        Challenge storage dispute = challenges[marketId];
        if (!proposal.challenged || dispute.resolved || reasoningHash == bytes32(0)) {
            revert InvalidProposal();
        }
        if (challengeReviewed[marketId][msg.sender]) {
            revert DuplicateChallengeReview();
        }

        challengeReviewed[marketId][msg.sender] = true;
        if (uphold) {
            ++dispute.upholdVotes;
        } else {
            ++dispute.rejectVotes;
        }
        emit ChallengeReviewed(marketId, msg.sender, uphold, reasoningHash);

        if (dispute.upholdVotes >= QUORUM) {
            dispute.resolved = true;
            proposal.invalid = true;
            bondCredits[dispute.challenger] += dispute.bond;
            emit ChallengeResolved(marketId, true);
            emit Invalidated(marketId);
        } else if (dispute.rejectVotes >= QUORUM) {
            dispute.resolved = true;
            proposal.challenged = false;
            bondCredits[treasury] += dispute.bond;
            emit ChallengeResolved(marketId, false);
        }
    }

    function finalize(bytes32 marketId) external {
        Proposal storage proposal = proposals[marketId];
        // forge-lint: disable-next-line(block-timestamp)
        bool windowElapsed = block.timestamp >= proposal.proposedAt + CHALLENGE_PERIOD;
        if (
            proposal.proposedAt == 0 || proposal.approvals < QUORUM || !windowElapsed
                || proposal.challenged || proposal.finalized || proposal.invalid
        ) {
            revert NotFinalizable();
        }
        proposal.finalized = true;
        emit Finalized(marketId, proposal.outcome);
    }

    function invalidateTimedOut(bytes32 marketId) external {
        Proposal storage proposal = proposals[marketId];
        // forge-lint: disable-next-line(block-timestamp)
        bool timedOut = block.timestamp >= proposal.proposedAt + QUORUM_TIMEOUT;
        if (proposal.proposedAt == 0 || !timedOut || proposal.finalized || proposal.invalid) {
            revert NotFinalizable();
        }
        proposal.invalid = true;
        Challenge storage dispute = challenges[marketId];
        if (proposal.challenged && !dispute.resolved) {
            dispute.resolved = true;
            bondCredits[dispute.challenger] += dispute.bond;
        }
        emit Invalidated(marketId);
    }

    function withdrawBondCredit() external {
        uint256 amount = bondCredits[msg.sender];
        if (amount == 0) {
            revert InvalidBond();
        }
        bondCredits[msg.sender] = 0;
        (bool sent,) = payable(msg.sender).call{ value: amount }("");
        if (!sent) {
            bondCredits[msg.sender] = amount;
            revert TransferFailed();
        }
        emit BondWithdrawn(msg.sender, amount);
    }

    function report(bytes32 marketId, bytes32 reportNullifier, uint256 participantCount) external {
        if (marketId == bytes32(0) || reportNullifier == bytes32(0)) {
            revert InvalidProposal();
        }
        if (reportNullifierUsed[reportNullifier]) {
            revert DuplicateReport();
        }
        reportNullifierUsed[reportNullifier] = true;
        uint256 count = ++reportCount[marketId];
        uint256 threshold = participantCount / 100 + (participantCount % 100 == 0 ? 0 : 1);
        if (threshold < 5) {
            threshold = 5;
        }
        if (count >= threshold) {
            paused[marketId] = true;
        }
        emit Reported(marketId, reportNullifier, count, paused[marketId]);
    }
}
