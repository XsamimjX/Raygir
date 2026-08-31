// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Holds RAY creation fees until the fixed review signer approves or refunds them.
contract CreationFeeEscrow is EIP712, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Decision {
        Approved,
        ContentRejected,
        ProviderFailure
    }

    enum State {
        None,
        Pending,
        Resolved
    }

    struct Deposit {
        address payer;
        uint128 amount;
        State state;
    }

    bytes32 public constant DECISION_TYPEHASH =
        keccak256("ReviewDecision(bytes32 pollId,uint8 decision,uint64 deadline)");

    IERC20 public immutable ray;
    address public immutable treasury;
    address public immutable reviewSigner;

    mapping(bytes32 pollId => Deposit deposit) public deposits;

    error InvalidConfiguration();
    error InvalidAmount();
    error DuplicatePoll(bytes32 pollId);
    error DepositNotPending(bytes32 pollId);
    error SignatureExpired(uint64 deadline);
    error InvalidReviewSigner(address recovered);

    event Deposited(bytes32 indexed pollId, address indexed payer, uint256 amount);
    event Resolved(
        bytes32 indexed pollId, Decision decision, uint256 treasuryAmount, uint256 refundAmount
    );

    constructor(IERC20 initialRay, address initialTreasury, address initialReviewSigner)
        EIP712("Raygir Creation Fee Escrow", "1")
    {
        if (
            address(initialRay) == address(0) || initialTreasury == address(0)
                || initialReviewSigner == address(0)
        ) {
            revert InvalidConfiguration();
        }

        ray = initialRay;
        treasury = initialTreasury;
        reviewSigner = initialReviewSigner;
    }

    function deposit(bytes32 pollId, uint128 amount) external nonReentrant {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (deposits[pollId].state != State.None) {
            revert DuplicatePoll(pollId);
        }

        deposits[pollId] = Deposit({ payer: msg.sender, amount: amount, state: State.Pending });
        ray.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(pollId, msg.sender, amount);
    }

    function resolve(bytes32 pollId, Decision decision, uint64 deadline, bytes calldata signature)
        external
        nonReentrant
    {
        Deposit storage pending = deposits[pollId];
        if (pending.state != State.Pending) {
            revert DepositNotPending(pollId);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) {
            revert SignatureExpired(deadline);
        }

        address recovered = ECDSA.recover(hashDecision(pollId, decision, deadline), signature);
        if (recovered != reviewSigner) {
            revert InvalidReviewSigner(recovered);
        }

        pending.state = State.Resolved;
        uint256 amount = pending.amount;
        uint256 treasuryAmount;
        uint256 refundAmount;

        if (decision == Decision.Approved) {
            treasuryAmount = amount;
        } else if (decision == Decision.ContentRejected) {
            treasuryAmount = amount / 10;
            refundAmount = amount - treasuryAmount;
        } else {
            refundAmount = amount;
        }

        if (treasuryAmount != 0) {
            ray.safeTransfer(treasury, treasuryAmount);
        }
        if (refundAmount != 0) {
            ray.safeTransfer(pending.payer, refundAmount);
        }

        emit Resolved(pollId, decision, treasuryAmount, refundAmount);
    }

    function hashDecision(bytes32 pollId, Decision decision, uint64 deadline)
        public
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(DECISION_TYPEHASH, pollId, decision, deadline));
        return _hashTypedDataV4(structHash);
    }
}

