// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";

import { OutcomePositions } from "../../src/markets/OutcomePositions.sol";

contract CollateralFixture is ERC20 {
    constructor() ERC20("Collateral", "COL") { }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract OutcomePositionsTest is Test {
    address private constant TRADER = address(0xA11CE);
    address private constant BUYER = address(0xB0B);
    address private constant SETTLEMENT = address(0xC10B);
    address private constant RESOLVER = address(0x0ACE);

    CollateralFixture private collateral;
    OutcomePositions private positions;

    function setUp() public {
        collateral = new CollateralFixture();
        positions = new OutcomePositions(
            collateral, SETTLEMENT, RESOLVER, uint64(block.timestamp + 1 days), "ipfs://market/{id}"
        );
        collateral.mint(TRADER, 100 ether);
        vm.prank(TRADER);
        collateral.approve(address(positions), type(uint256).max);
    }

    function testSplitAndMergeConserveCollateral() public {
        vm.startPrank(TRADER);
        positions.split(10 ether);
        assertEq(positions.balanceOf(TRADER, positions.YES()), 10 ether);
        assertEq(positions.balanceOf(TRADER, positions.NO()), 10 ether);
        assertEq(positions.collateralLocked(), 10 ether);

        positions.merge(4 ether);
        vm.stopPrank();

        assertEq(collateral.balanceOf(address(positions)), 6 ether);
        assertEq(positions.collateralLocked(), 6 ether);
    }

    function testOnlySettlementCanTransferPositions() public {
        vm.prank(TRADER);
        positions.split(10 ether);
        uint256 yes = positions.YES();

        vm.expectRevert(
            abi.encodeWithSelector(OutcomePositions.ProtocolTransferOnly.selector, TRADER)
        );
        vm.prank(TRADER);
        positions.safeTransferFrom(TRADER, BUYER, yes, 2 ether, "");

        vm.prank(TRADER);
        positions.setApprovalForAll(SETTLEMENT, true);
        vm.prank(SETTLEMENT);
        positions.safeTransferFrom(TRADER, BUYER, yes, 2 ether, "");
        assertEq(positions.balanceOf(BUYER, yes), 2 ether);
    }

    function testWinningOutcomeRedeemsOneForOne() public {
        vm.prank(TRADER);
        positions.split(10 ether);
        vm.warp(block.timestamp + 1 days);
        vm.prank(RESOLVER);
        positions.resolve(OutcomePositions.Resolution.Yes);

        vm.prank(TRADER);
        positions.redeem(10 ether);

        assertEq(collateral.balanceOf(TRADER), 100 ether);
        assertEq(positions.collateralLocked(), 0);
    }

    function testResolutionRequiresResolverAndClose() public {
        vm.expectRevert(
            abi.encodeWithSelector(OutcomePositions.NotResolver.selector, address(this))
        );
        positions.resolve(OutcomePositions.Resolution.Yes);

        vm.expectRevert(OutcomePositions.MarketStillOpen.selector);
        vm.prank(RESOLVER);
        positions.resolve(OutcomePositions.Resolution.Yes);
    }

    function testInvalidMarketRejectsWinnerRedemptionButAllowsPairMerge() public {
        vm.prank(TRADER);
        positions.split(10 ether);
        vm.warp(block.timestamp + 1 days);
        vm.prank(RESOLVER);
        positions.resolve(OutcomePositions.Resolution.Invalid);

        vm.expectRevert(OutcomePositions.MarketInvalid.selector);
        vm.prank(TRADER);
        positions.redeem(1 ether);

        vm.prank(TRADER);
        positions.merge(10 ether);
        assertEq(collateral.balanceOf(TRADER), 100 ether);
    }
}
