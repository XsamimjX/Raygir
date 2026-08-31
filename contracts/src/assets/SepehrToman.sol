// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { MockSepTomanOracle } from "./MockSepTomanOracle.sol";
import { ISptmMintable, SptmSale } from "./SptmSale.sol";

/// @notice Transferable, non-redeemable test token. One SPTM represents 1,000 displayed Toman.
contract SepehrToman is ERC20, ISptmMintable {
    uint8 private constant TOKEN_DECIMALS = 6;

    SptmSale public immutable sale;

    error UnauthorizedMinter(address caller);

    constructor(MockSepTomanOracle oracle, address payable treasury)
        ERC20("Sepehr Toman Test", "SPTM")
    {
        sale = new SptmSale(ISptmMintable(address(this)), oracle, treasury);
    }

    function decimals() public pure override returns (uint8) {
        return TOKEN_DECIMALS;
    }

    function mintFromSale(address recipient, uint256 amount) external {
        if (msg.sender != address(sale)) {
            revert UnauthorizedMinter(msg.sender);
        }

        _mint(recipient, amount);
    }
}

