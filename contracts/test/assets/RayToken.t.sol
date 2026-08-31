// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { RayToken } from "../../src/assets/RayToken.sol";

contract RayTokenTest is Test {
    address private constant POOL = address(0x1001);
    address private constant FAUCET = address(0x1002);
    address private constant TREASURY = address(0x1003);
    address private constant MARKET = address(0x1004);
    address private constant ALICE = address(0x2001);
    address private constant BOB = address(0x2002);

    RayToken private ray;

    function setUp() public {
        address[] memory routes = new address[](1);
        routes[0] = MARKET;
        ray = new RayToken(POOL, FAUCET, TREASURY, routes);
    }

    function testAllocatesTheEntireFixedSupply() public view {
        assertEq(ray.totalSupply(), 100_000_000 ether);
        assertEq(ray.balanceOf(POOL), 80_000_000 ether);
        assertEq(ray.balanceOf(FAUCET), 10_000_000 ether);
        assertEq(ray.balanceOf(TREASURY), 10_000_000 ether);
    }

    function testProtocolRouteCanTransferToAndFromUsers() public {
        vm.prank(FAUCET);
        assertTrue(ray.transfer(ALICE, 100 ether));

        vm.prank(ALICE);
        assertTrue(ray.transfer(MARKET, 40 ether));

        vm.prank(MARKET);
        assertTrue(ray.transfer(BOB, 15 ether));

        assertEq(ray.balanceOf(ALICE), 60 ether);
        assertEq(ray.balanceOf(MARKET), 25 ether);
        assertEq(ray.balanceOf(BOB), 15 ether);
    }

    function testDirectUserTransferReverts() public {
        vm.prank(FAUCET);
        assertTrue(ray.transfer(ALICE, 100 ether));

        vm.expectRevert(
            abi.encodeWithSelector(RayToken.DirectUserTransferDisabled.selector, ALICE, BOB)
        );
        vm.prank(ALICE);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        ray.transfer(BOB, 1 ether);
    }

    function testTransferFromCannotBypassDirectTransferRestriction() public {
        vm.prank(FAUCET);
        assertTrue(ray.transfer(ALICE, 100 ether));

        vm.prank(ALICE);
        ray.approve(BOB, 1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(RayToken.DirectUserTransferDisabled.selector, ALICE, BOB)
        );
        vm.prank(BOB);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        ray.transferFrom(ALICE, BOB, 1 ether);
    }

    function testRejectsZeroAllocationAddress() public {
        address[] memory routes = new address[](0);
        vm.expectRevert(RayToken.InvalidAllocation.selector);
        new RayToken(address(0), FAUCET, TREASURY, routes);
    }

    function testRejectsZeroAdditionalProtocolRoute() public {
        address[] memory routes = new address[](1);
        routes[0] = address(0);
        vm.expectRevert(abi.encodeWithSelector(RayToken.InvalidProtocolRoute.selector, address(0)));
        new RayToken(POOL, FAUCET, TREASURY, routes);
    }
}
