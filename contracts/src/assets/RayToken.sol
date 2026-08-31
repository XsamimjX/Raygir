// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Fixed-supply Raygir protocol credit. Transfers must involve an approved protocol route.
contract RayToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 100_000_000 ether;

    error DirectUserTransferDisabled(address from, address to);
    error InvalidAllocation();
    error InvalidProtocolRoute(address route);

    mapping(address route => bool approved) public immutableProtocolRoute;

    constructor(address pool, address faucet, address treasury, address[] memory protocolRoutes)
        ERC20("Raygir", "RAY")
    {
        if (pool == address(0) || faucet == address(0) || treasury == address(0)) {
            revert InvalidAllocation();
        }

        _approveProtocolRoute(pool);
        _approveProtocolRoute(faucet);
        _approveProtocolRoute(treasury);

        uint256 routeCount = protocolRoutes.length;
        for (uint256 i; i < routeCount; ++i) {
            _approveProtocolRoute(protocolRoutes[i]);
        }

        _mint(pool, 80_000_000 ether);
        _mint(faucet, 10_000_000 ether);
        _mint(treasury, 10_000_000 ether);
    }

    function _approveProtocolRoute(address route) private {
        if (route == address(0)) {
            revert InvalidProtocolRoute(route);
        }

        immutableProtocolRoute[route] = true;
    }

    function _update(address from, address to, uint256 value) internal override {
        bool isMintOrBurn = from == address(0) || to == address(0);
        if (!isMintOrBurn && !immutableProtocolRoute[from] && !immutableProtocolRoute[to]) {
            revert DirectUserTransferDisabled(from, to);
        }

        super._update(from, to, value);
    }
}

