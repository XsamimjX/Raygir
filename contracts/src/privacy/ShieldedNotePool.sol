// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IShieldedNoteVerifier } from "./IShieldedNoteVerifier.sol";

/// @notice Shared deposit pool with proof-authorized, replay-safe note withdrawals.
contract ShieldedNotePool {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    IShieldedNoteVerifier public immutable verifier;
    mapping(bytes32 commitment => uint128 amount) public depositedAmount;
    mapping(bytes32 nullifier => bool used) public nullifierUsed;

    error InvalidConfiguration();
    error InvalidBatch();
    error DuplicateCommitment(bytes32 commitment);
    error UnknownCommitment(bytes32 commitment);
    error NullifierAlreadyUsed(bytes32 nullifier);
    error InvalidProof();

    event NoteDeposited(bytes32 indexed commitment, uint128 amount);
    event NoteWithdrawn(
        bytes32 indexed commitment,
        bytes32 indexed nullifier,
        address indexed recipient,
        uint128 amount
    );

    constructor(IERC20 initialAsset, IShieldedNoteVerifier initialVerifier) {
        if (address(initialAsset) == address(0) || address(initialVerifier) == address(0)) {
            revert InvalidConfiguration();
        }

        asset = initialAsset;
        verifier = initialVerifier;
    }

    function deposit(bytes32[] calldata commitments, uint128[] calldata amounts) external {
        uint256 count = commitments.length;
        if (count == 0 || count != amounts.length) {
            revert InvalidBatch();
        }

        uint256 total;
        for (uint256 i; i < count; ++i) {
            bytes32 commitment = commitments[i];
            uint128 amount = amounts[i];
            if (commitment == bytes32(0) || amount == 0) {
                revert InvalidBatch();
            }
            if (depositedAmount[commitment] != 0) {
                revert DuplicateCommitment(commitment);
            }

            depositedAmount[commitment] = amount;
            total += amount;
            emit NoteDeposited(commitment, amount);
        }

        asset.safeTransferFrom(msg.sender, address(this), total);
    }

    function withdraw(
        bytes calldata proof,
        bytes32 commitment,
        bytes32 nullifier,
        address recipient,
        uint128 amount
    ) external {
        if (recipient == address(0) || nullifier == bytes32(0) || amount == 0) {
            revert InvalidConfiguration();
        }
        if (depositedAmount[commitment] != amount) {
            revert UnknownCommitment(commitment);
        }
        if (nullifierUsed[nullifier]) {
            revert NullifierAlreadyUsed(nullifier);
        }
        if (!verifier.verify(proof, commitment, nullifier, recipient, amount)) {
            revert InvalidProof();
        }

        delete depositedAmount[commitment];
        nullifierUsed[nullifier] = true;
        asset.safeTransfer(recipient, amount);
        emit NoteWithdrawn(commitment, nullifier, recipient, amount);
    }
}
