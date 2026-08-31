// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";

import { PredictionPool } from "../../src/markets/PredictionPool.sol";

contract PredictionAsset is ERC20 {
    constructor() ERC20("Ray", "RAY") { }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract PredictionPoolTest is Test {
    address private constant CREATOR = address(0xC0DE);
    address private constant RELAY = address(0xBEEF);
    address private constant RESOLVER = address(0x0ACE);
    address private constant FIRST = address(0xA11CE);
    address private constant SECOND = address(0xB0B);

    PredictionAsset private asset;
    PredictionPool private pool;

    function setUp() public {
        asset = new PredictionAsset();
        pool = new PredictionPool(
            asset,
            CREATOR,
            RELAY,
            RESOLVER,
            uint64(block.timestamp),
            uint64(block.timestamp + 100),
            0
        );
        asset.mint(FIRST, 40 ether);
        asset.mint(SECOND, 60 ether);
        vm.prank(FIRST);
        asset.approve(address(pool), type(uint256).max);
        vm.prank(SECOND);
        asset.approve(address(pool), type(uint256).max);
    }

    function testSettlementConservesWholePot() public {
        vm.prank(FIRST);
        pool.stake(keccak256("first"), 40 ether, uint64(block.timestamp));
        vm.prank(SECOND);
        pool.stake(keccak256("second"), 60 ether, uint64(block.timestamp));

        vm.warp(block.timestamp + 100);
        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.OptionOne, 40 ether);

        vm.prank(RELAY);
        uint256 winnerPayout = pool.claim(keccak256("first"), FIRST, true, 0, 40 ether);
        vm.prank(CREATOR);
        uint256 creatorReward = pool.claimCreatorReward();

        assertEq(winnerPayout, 90 ether);
        assertEq(creatorReward, 10 ether);
        assertEq(winnerPayout + creatorReward, 100 ether);
        assertEq(asset.balanceOf(address(pool)), 0);
    }

    function testInvalidPoolRefundsAndPaysNoCreatorReward() public {
        vm.prank(FIRST);
        pool.stake(keccak256("first"), 40 ether, uint64(block.timestamp));
        vm.warp(block.timestamp + 100);
        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.Invalid, 0);

        vm.prank(RELAY);
        assertEq(pool.claim(keccak256("first"), FIRST, false, 0, 0), 40 ether);
        vm.expectRevert(PredictionPool.InvalidClaim.selector);
        vm.prank(CREATOR);
        pool.claimCreatorReward();
    }

    function testFuzzInvalidPoolRefundsEveryStakedUnit(uint128 firstInput, uint128 secondInput)
        public
    {
        uint128 firstStake = uint128(bound(firstInput, 1, 40 ether));
        uint128 secondStake = uint128(bound(secondInput, 1, 60 ether));
        vm.prank(FIRST);
        pool.stake(keccak256("first"), firstStake, uint64(block.timestamp));
        vm.prank(SECOND);
        pool.stake(keccak256("second"), secondStake, uint64(block.timestamp));

        vm.warp(block.timestamp + 100);
        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.Invalid, 0);

        vm.startPrank(RELAY);
        uint256 firstRefund = pool.claim(keccak256("first"), FIRST, false, 0, 0);
        uint256 secondRefund = pool.claim(keccak256("second"), SECOND, false, 0, 0);
        vm.stopPrank();

        assertEq(firstRefund + secondRefund, firstStake + secondStake);
        assertEq(asset.balanceOf(address(pool)), 0);
    }

    function testNoWinnerMustUseInvalidResolutionAndRefund() public {
        vm.prank(FIRST);
        pool.stake(keccak256("first"), 40 ether, uint64(block.timestamp));
        vm.warp(block.timestamp + 100);

        vm.expectRevert(PredictionPool.InvalidResolution.selector);
        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.OptionOne, 0);

        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.Invalid, 0);
        vm.prank(RELAY);
        assertEq(pool.claim(keccak256("first"), FIRST, false, 0, 0), 40 ether);
    }

    function testCommitmentAndClaimCannotReplay() public {
        bytes32 commitment = keccak256("position");
        vm.prank(FIRST);
        pool.stake(commitment, 40 ether, uint64(block.timestamp));

        vm.expectRevert(
            abi.encodeWithSelector(PredictionPool.DuplicateCommitment.selector, commitment)
        );
        vm.prank(FIRST);
        pool.stake(commitment, 1 ether, uint64(block.timestamp));

        vm.warp(block.timestamp + 100);
        vm.prank(RESOLVER);
        pool.resolve(PredictionPool.Resolution.OptionOne, 40 ether);
        vm.prank(RELAY);
        pool.claim(commitment, FIRST, true, 0, 40 ether);

        vm.expectRevert(PredictionPool.AlreadyClaimed.selector);
        vm.prank(RELAY);
        pool.claim(commitment, FIRST, true, 0, 40 ether);
    }
}
