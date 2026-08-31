// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { Test } from "forge-std/Test.sol";

import { RayToken } from "../../src/assets/RayToken.sol";

contract RayTokenHandler is Test {
    address internal constant Pool = address(0x1001);
    address internal constant Faucet = address(0x1002);
    address internal constant Market = address(0x1004);
    address internal constant Alice = address(0x2001);
    address internal constant Bob = address(0x2002);

    RayToken private immutable ray;

    constructor(RayToken token) {
        ray = token;
    }

    function faucetToAlice(uint256 amount) external {
        _transfer(Faucet, Alice, amount);
    }

    function aliceToMarket(uint256 amount) external {
        _transfer(Alice, Market, amount);
    }

    function marketToBob(uint256 amount) external {
        _transfer(Market, Bob, amount);
    }

    function bobToPool(uint256 amount) external {
        _transfer(Bob, Pool, amount);
    }

    function poolToFaucet(uint256 amount) external {
        _transfer(Pool, Faucet, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 transferable = bound(amount, 0, ray.balanceOf(from));
        vm.prank(from);
        assertTrue(ray.transfer(to, transferable));
    }
}

contract RayTokenInvariantTest is StdInvariant, Test {
    address private constant Pool = address(0x1001);
    address private constant Faucet = address(0x1002);
    address private constant Treasury = address(0x1003);
    address private constant Market = address(0x1004);
    address private constant Alice = address(0x2001);
    address private constant Bob = address(0x2002);

    RayToken private ray;

    function setUp() public {
        address[] memory routes = new address[](1);
        routes[0] = Market;
        ray = new RayToken(Pool, Faucet, Treasury, routes);
        targetContract(address(new RayTokenHandler(ray)));
    }

    function invariantSupplyIsFixedAndFullyAccountedFor() public view {
        uint256 accounted = ray.balanceOf(Pool) + ray.balanceOf(Faucet) + ray.balanceOf(Treasury)
            + ray.balanceOf(Market) + ray.balanceOf(Alice) + ray.balanceOf(Bob);

        assertEq(ray.totalSupply(), ray.TOTAL_SUPPLY());
        assertEq(accounted, ray.totalSupply());
    }
}
