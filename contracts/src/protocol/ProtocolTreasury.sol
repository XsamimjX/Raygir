// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Non-upgradeable test treasury with a controller fixed at deployment.
contract ProtocolTreasury {
    using SafeERC20 for IERC20;

    address public immutable controller;

    error InvalidController();
    error Unauthorized(address caller);
    error SepTransferFailed();

    constructor(address initialController) {
        if (initialController == address(0)) {
            revert InvalidController();
        }
        controller = initialController;
    }

    receive() external payable { }

    function withdrawSep(address payable recipient, uint256 amount) external {
        _authorize();
        (bool sent,) = recipient.call{ value: amount }("");
        if (!sent) {
            revert SepTransferFailed();
        }
    }

    function withdrawToken(IERC20 token, address recipient, uint256 amount) external {
        _authorize();
        token.safeTransfer(recipient, amount);
    }

    function _authorize() private view {
        if (msg.sender != controller) {
            revert Unauthorized(msg.sender);
        }
    }
}

