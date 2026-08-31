// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { MockSepTomanOracle } from "./MockSepTomanOracle.sol";

interface ISptmMintable {
    function mintFromSale(address recipient, uint256 amount) external;
}

/// @notice One-way test sale. SEP is sent to the test treasury; SPTM cannot be redeemed here.
contract SptmSale {
    uint256 private constant QUOTE_DENOMINATOR = 1e15;

    ISptmMintable public immutable token;
    MockSepTomanOracle public immutable oracle;
    address payable public immutable treasury;

    error InvalidConfiguration();
    error PurchaseTooSmall();
    error TreasuryTransferFailed();

    event Purchased(address indexed recipient, uint256 sepPaid, uint256 sptmMinted);

    constructor(
        ISptmMintable initialToken,
        MockSepTomanOracle initialOracle,
        address payable initialTreasury
    ) {
        if (
            address(initialToken) == address(0) || address(initialOracle) == address(0)
                || initialTreasury == address(0)
        ) {
            revert InvalidConfiguration();
        }

        token = initialToken;
        oracle = initialOracle;
        treasury = initialTreasury;
    }

    function quote(uint256 sepWei) public view returns (uint256) {
        return Math.mulDiv(sepWei, oracle.currentPrice(), QUOTE_DENOMINATOR);
    }

    function buy(address recipient) external payable returns (uint256 sptmAmount) {
        if (recipient == address(0)) {
            revert InvalidConfiguration();
        }

        sptmAmount = quote(msg.value);
        if (sptmAmount == 0) {
            revert PurchaseTooSmall();
        }

        (bool sent,) = treasury.call{ value: msg.value }("");
        if (!sent) {
            revert TreasuryTransferFailed();
        }

        token.mintFromSale(recipient, sptmAmount);
        emit Purchased(recipient, msg.value, sptmAmount);
    }
}

