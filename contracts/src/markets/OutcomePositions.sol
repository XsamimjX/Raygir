// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Fully collateralized YES/NO positions with protocol-only secondary transfers.
contract OutcomePositions is ERC1155 {
    using SafeERC20 for IERC20;

    uint256 public constant YES = 1;
    uint256 public constant NO = 2;

    enum Resolution {
        Unresolved,
        Yes,
        No,
        Invalid
    }

    IERC20 public immutable collateral;
    address public immutable settlement;
    address public immutable resolver;
    uint64 public immutable closesAt;
    Resolution public resolution;
    uint256 public collateralLocked;

    error InvalidConfiguration();
    error MarketClosed();
    error MarketStillOpen();
    error AlreadyResolved();
    error MarketUnresolved();
    error InvalidOutcome();
    error NotResolver(address caller);
    error ProtocolTransferOnly(address caller);
    error MarketInvalid();

    event Split(address indexed account, uint256 amount);
    event Merged(address indexed account, uint256 amount);
    event Resolved(Resolution outcome);
    event Redeemed(address indexed account, uint256 indexed outcome, uint256 amount);

    constructor(
        IERC20 initialCollateral,
        address initialSettlement,
        address initialResolver,
        uint64 initialClosesAt,
        string memory metadataUri
    ) ERC1155(metadataUri) {
        // forge-lint: disable-next-line(block-timestamp)
        bool alreadyClosed = initialClosesAt <= block.timestamp;
        if (
            address(initialCollateral) == address(0) || initialSettlement == address(0)
                || initialResolver == address(0) || alreadyClosed
        ) {
            revert InvalidConfiguration();
        }

        collateral = initialCollateral;
        settlement = initialSettlement;
        resolver = initialResolver;
        closesAt = initialClosesAt;
    }

    function split(uint256 amount) external {
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp >= closesAt || resolution != Resolution.Unresolved) {
            revert MarketClosed();
        }
        if (amount == 0) {
            revert InvalidConfiguration();
        }

        collateral.safeTransferFrom(msg.sender, address(this), amount);
        collateralLocked += amount;
        _mint(msg.sender, YES, amount, "");
        _mint(msg.sender, NO, amount, "");
        emit Split(msg.sender, amount);
    }

    function merge(uint256 amount) external {
        _burn(msg.sender, YES, amount);
        _burn(msg.sender, NO, amount);
        collateralLocked -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit Merged(msg.sender, amount);
    }

    function resolve(Resolution outcome) external {
        if (msg.sender != resolver) {
            revert NotResolver(msg.sender);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp < closesAt) {
            revert MarketStillOpen();
        }
        if (resolution != Resolution.Unresolved) {
            revert AlreadyResolved();
        }
        if (outcome == Resolution.Unresolved) {
            revert InvalidOutcome();
        }

        resolution = outcome;
        emit Resolved(outcome);
    }

    function redeem(uint256 amount) external {
        Resolution outcome = resolution;
        if (outcome == Resolution.Unresolved) {
            revert MarketUnresolved();
        }
        if (outcome == Resolution.Invalid) {
            revert MarketInvalid();
        }

        uint256 winningToken = outcome == Resolution.Yes ? YES : NO;
        _burn(msg.sender, winningToken, amount);
        collateralLocked -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit Redeemed(msg.sender, winningToken, amount);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override
    {
        if (from != address(0) && to != address(0) && msg.sender != settlement) {
            revert ProtocolTransferOnly(msg.sender);
        }

        super._update(from, to, ids, values);
    }
}
