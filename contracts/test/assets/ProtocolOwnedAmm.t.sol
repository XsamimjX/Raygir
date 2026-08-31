// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { ProtocolOwnedAmm } from "../../src/assets/ProtocolOwnedAmm.sol";
import { RayToken } from "../../src/assets/RayToken.sol";

contract ProtocolOwnedAmmTest is Test {
    address private constant FAUCET = address(0x3001);
    address private constant TREASURY = address(0x3002);
    address private constant BUYER = address(0x3003);

    ProtocolOwnedAmm private amm;
    RayToken private ray;

    function setUp() public {
        uint64 deploymentNonce = vm.getNonce(address(this));
        address predictedRay = vm.computeCreateAddress(address(this), deploymentNonce + 1);
        amm = new ProtocolOwnedAmm(RayToken(predictedRay), TREASURY);

        address[] memory routes = new address[](0);
        ray = new RayToken(address(amm), FAUCET, TREASURY, routes);
        assertEq(address(ray), predictedRay);

        vm.deal(TREASURY, 1_000 ether);
        vm.prank(TREASURY);
        amm.initialize{ value: 1_000 ether }();
        vm.deal(BUYER, 100 ether);
    }

    function testPoolStartsWithProtocolAllocationAndNoLpToken() public view {
        assertEq(ray.balanceOf(address(amm)), 80_000_000 ether);
        assertEq(address(amm).balance, 1_000 ether);
        assertTrue(amm.initialized());
    }

    function testBuyThenSellMaintainsOrIncreasesConstantProduct() public {
        uint256 productBefore = _constantProduct();

        vm.prank(BUYER);
        uint256 rayOut = amm.buyRay{ value: 10 ether }(0, uint64(block.timestamp));
        assertGt(rayOut, 0);
        assertGe(_constantProduct(), productBefore);

        vm.prank(BUYER);
        ray.approve(address(amm), rayOut);

        vm.prank(BUYER);
        uint256 sepOut = amm.sellRay(rayOut, 0, uint64(block.timestamp));
        assertGt(sepOut, 0);
        assertGe(_constantProduct(), productBefore);
    }

    function testQuoteMatchesBuyOutput() public {
        uint256 quoted = amm.quoteRayOut(2 ether);

        vm.prank(BUYER);
        uint256 received = amm.buyRay{ value: 2 ether }(quoted, uint64(block.timestamp));

        assertEq(received, quoted);
    }

    function testMinimumOutputProtectsBuyer() public {
        uint256 quoted = amm.quoteRayOut(1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(ProtocolOwnedAmm.SlippageExceeded.selector, quoted + 1, quoted)
        );
        vm.prank(BUYER);
        amm.buyRay{ value: 1 ether }(quoted + 1, uint64(block.timestamp));
    }

    function testExpiredSwapReverts() public {
        vm.warp(block.timestamp + 1);

        vm.expectRevert(ProtocolOwnedAmm.DeadlineExpired.selector);
        vm.prank(BUYER);
        amm.buyRay{ value: 1 ether }(0, uint64(block.timestamp - 1));
    }

    function testCannotInitializeTwice() public {
        vm.deal(TREASURY, 1 ether);
        vm.expectRevert(ProtocolOwnedAmm.AlreadyInitialized.selector);
        vm.prank(TREASURY);
        amm.initialize{ value: 1 ether }();
    }

    function _constantProduct() private view returns (uint256) {
        return address(amm).balance * ray.balanceOf(address(amm));
    }
}
