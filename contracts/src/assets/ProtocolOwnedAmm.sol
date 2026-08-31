// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Zero-fee, no-LP-token SEP/RAY testnet pool owned by the protocol.
contract ProtocolOwnedAmm is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable ray;
    address public immutable treasury;
    bool public initialized;

    error InvalidConfiguration();
    error Unauthorized(address caller);
    error AlreadyInitialized();
    error EmptyReserve();
    error DeadlineExpired();
    error SlippageExceeded(uint256 minimum, uint256 received);
    error SepTransferFailed();

    event Initialized(uint256 sepReserve, uint256 rayReserve);
    event RayPurchased(address indexed buyer, uint256 sepIn, uint256 rayOut);
    event RaySold(address indexed seller, uint256 rayIn, uint256 sepOut);

    constructor(IERC20 initialRay, address initialTreasury) {
        if (address(initialRay) == address(0) || initialTreasury == address(0)) {
            revert InvalidConfiguration();
        }

        ray = initialRay;
        treasury = initialTreasury;
    }

    function initialize() external payable {
        if (msg.sender != treasury) {
            revert Unauthorized(msg.sender);
        }
        if (initialized) {
            revert AlreadyInitialized();
        }
        if (msg.value == 0 || ray.balanceOf(address(this)) == 0) {
            revert EmptyReserve();
        }

        initialized = true;
        emit Initialized(msg.value, ray.balanceOf(address(this)));
    }

    function quoteRayOut(uint256 sepIn) public view returns (uint256) {
        uint256 sepReserve = address(this).balance;
        uint256 rayReserve = ray.balanceOf(address(this));
        if (!initialized || sepReserve == 0 || rayReserve == 0) {
            revert EmptyReserve();
        }

        return rayReserve * sepIn / (sepReserve + sepIn);
    }

    function quoteSepOut(uint256 rayIn) public view returns (uint256) {
        uint256 sepReserve = address(this).balance;
        uint256 rayReserve = ray.balanceOf(address(this));
        if (!initialized || sepReserve == 0 || rayReserve == 0) {
            revert EmptyReserve();
        }

        return sepReserve * rayIn / (rayReserve + rayIn);
    }

    function buyRay(uint256 minimumRayOut, uint64 deadline)
        external
        payable
        nonReentrant
        returns (uint256 rayOut)
    {
        _checkDeadline(deadline);
        uint256 sepReserveBefore = address(this).balance - msg.value;
        uint256 rayReserve = ray.balanceOf(address(this));
        if (!initialized || msg.value == 0 || sepReserveBefore == 0 || rayReserve == 0) {
            revert EmptyReserve();
        }

        rayOut = rayReserve * msg.value / (sepReserveBefore + msg.value);
        if (rayOut < minimumRayOut || rayOut == 0) {
            revert SlippageExceeded(minimumRayOut, rayOut);
        }

        ray.safeTransfer(msg.sender, rayOut);
        emit RayPurchased(msg.sender, msg.value, rayOut);
    }

    function sellRay(uint256 rayIn, uint256 minimumSepOut, uint64 deadline)
        external
        nonReentrant
        returns (uint256 sepOut)
    {
        _checkDeadline(deadline);
        uint256 sepReserve = address(this).balance;
        uint256 rayReserveBefore = ray.balanceOf(address(this));
        if (!initialized || rayIn == 0 || sepReserve == 0 || rayReserveBefore == 0) {
            revert EmptyReserve();
        }

        ray.safeTransferFrom(msg.sender, address(this), rayIn);
        uint256 received = ray.balanceOf(address(this)) - rayReserveBefore;
        sepOut = sepReserve * received / (rayReserveBefore + received);
        if (sepOut < minimumSepOut || sepOut == 0) {
            revert SlippageExceeded(minimumSepOut, sepOut);
        }

        (bool sent,) = payable(msg.sender).call{ value: sepOut }("");
        if (!sent) {
            revert SepTransferFailed();
        }

        emit RaySold(msg.sender, received, sepOut);
    }

    function _checkDeadline(uint64 deadline) private view {
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
    }
}

