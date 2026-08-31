// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { PariMutuelPayout } from "./PariMutuelPayout.sol";

/// @notice Immutable pari-mutuel pool using opaque position commitments and relay-authorized claims.
contract PredictionPool {
    using SafeERC20 for IERC20;

    enum Resolution {
        Unresolved,
        OptionOne,
        OptionTwo,
        Invalid
    }

    struct Position {
        uint128 stake;
        uint256 weight;
        bool claimed;
    }

    IERC20 public immutable asset;
    address public immutable creator;
    address public immutable proofRelay;
    address public immutable resolver;
    uint64 public immutable opensAt;
    uint64 public immutable closesAt;
    uint16 public immutable boostBps;

    Resolution public resolution;
    uint256 public totalPot;
    uint256 public winningWeight;
    bool public creatorClaimed;
    mapping(bytes32 commitment => Position position) public positions;

    error InvalidConfiguration();
    error PoolNotOpen();
    error PoolStillOpen();
    error Unauthorized(address caller);
    error DuplicateCommitment(bytes32 commitment);
    error UnknownPosition(bytes32 commitment);
    error AlreadyResolved();
    error AlreadyClaimed();
    error InvalidResolution();
    error InvalidClaim();

    event Staked(bytes32 indexed commitment, uint256 amount, uint256 weight);
    event Resolved(Resolution outcome, uint256 winningWeight);
    event Claimed(bytes32 indexed commitment, address indexed recipient, uint256 amount);
    event CreatorRewardClaimed(address indexed creator, uint256 amount);

    constructor(
        IERC20 initialAsset,
        address initialCreator,
        address initialProofRelay,
        address initialResolver,
        uint64 initialOpensAt,
        uint64 initialClosesAt,
        uint16 initialBoostBps
    ) {
        if (
            address(initialAsset) == address(0) || initialCreator == address(0)
                || initialProofRelay == address(0) || initialResolver == address(0)
                || initialOpensAt >= initialClosesAt || initialBoostBps > 500
        ) {
            revert InvalidConfiguration();
        }

        asset = initialAsset;
        creator = initialCreator;
        proofRelay = initialProofRelay;
        resolver = initialResolver;
        opensAt = initialOpensAt;
        closesAt = initialClosesAt;
        boostBps = initialBoostBps;
    }

    function stake(bytes32 commitment, uint128 amount, uint64 committedAt) external {
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < opensAt || block.timestamp >= closesAt) {
            revert PoolNotOpen();
        }
        if (commitment == bytes32(0) || amount == 0) {
            revert InvalidConfiguration();
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (committedAt != block.timestamp) {
            revert InvalidConfiguration();
        }
        if (positions[commitment].stake != 0) {
            revert DuplicateCommitment(commitment);
        }

        uint256 calculatedWeight =
            PariMutuelPayout.weightedStake(amount, opensAt, closesAt, committedAt, boostBps);
        positions[commitment] =
            Position({ stake: amount, weight: calculatedWeight, claimed: false });
        totalPot += amount;
        asset.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(commitment, amount, calculatedWeight);
    }

    function resolve(Resolution outcome, uint256 totalWinningWeight) external {
        if (msg.sender != resolver) {
            revert Unauthorized(msg.sender);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < closesAt) {
            revert PoolStillOpen();
        }
        if (resolution != Resolution.Unresolved) {
            revert AlreadyResolved();
        }
        if (
            outcome == Resolution.Unresolved
                || (outcome != Resolution.Invalid && totalWinningWeight == 0)
        ) {
            revert InvalidResolution();
        }

        resolution = outcome;
        winningWeight = totalWinningWeight;
        emit Resolved(outcome, totalWinningWeight);
    }

    function claim(
        bytes32 commitment,
        address recipient,
        bool isWinner,
        uint256 previousCumulativeWeight,
        uint256 cumulativeWeight
    ) external returns (uint256 amount) {
        if (msg.sender != proofRelay) {
            revert Unauthorized(msg.sender);
        }
        Position storage position = positions[commitment];
        if (position.stake == 0) {
            revert UnknownPosition(commitment);
        }
        if (position.claimed) {
            revert AlreadyClaimed();
        }
        if (recipient == address(0) || resolution == Resolution.Unresolved) {
            revert InvalidClaim();
        }

        position.claimed = true;
        if (resolution == Resolution.Invalid) {
            amount = position.stake;
        } else {
            if (!isWinner || cumulativeWeight - previousCumulativeWeight != position.weight) {
                revert InvalidClaim();
            }
            amount = PariMutuelPayout.payoutSlice(
                PariMutuelPayout.winnerPool(totalPot),
                previousCumulativeWeight,
                cumulativeWeight,
                winningWeight
            );
        }

        asset.safeTransfer(recipient, amount);
        emit Claimed(commitment, recipient, amount);
    }

    function claimCreatorReward() external returns (uint256 amount) {
        if (msg.sender != creator) {
            revert Unauthorized(msg.sender);
        }
        if (
            resolution == Resolution.Unresolved || resolution == Resolution.Invalid
                || creatorClaimed
        ) {
            revert InvalidClaim();
        }

        creatorClaimed = true;
        amount = PariMutuelPayout.creatorReward(totalPot);
        asset.safeTransfer(creator, amount);
        emit CreatorRewardClaimed(creator, amount);
    }
}
