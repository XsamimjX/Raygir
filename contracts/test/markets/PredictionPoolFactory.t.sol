// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";

import { PredictionPool } from "../../src/markets/PredictionPool.sol";
import { PredictionPoolFactory } from "../../src/markets/PredictionPoolFactory.sol";

contract PredictionFactoryAsset is ERC20 {
    constructor() ERC20("Ray", "RAY") { }
}

contract PredictionPoolFactoryTest is Test {
    address private constant Creator = address(0xC0DE);
    address private constant Relay = address(0xBEEF);
    address private constant Resolver = address(0x0ACE);
    bytes32 private constant MarketId = keccak256("prediction-market");

    PredictionFactoryAsset private asset;
    PredictionPoolFactory private factory;

    function setUp() public {
        asset = new PredictionFactoryAsset();
        factory = new PredictionPoolFactory(asset, Relay, Resolver);
    }

    function testCreatesImmutablePoolAndRejectsDuplicateMarket() public {
        vm.prank(Creator);
        PredictionPool pool = factory.createPredictionPool(
            MarketId, uint64(block.timestamp), uint64(block.timestamp + 1 days), 100
        );

        assertEq(factory.poolFor(MarketId), address(pool));
        assertEq(address(pool.asset()), address(asset));
        assertEq(pool.creator(), Creator);
        assertEq(pool.proofRelay(), Relay);
        assertEq(pool.resolver(), Resolver);
        assertEq(pool.boostBps(), 100);

        vm.expectRevert(
            abi.encodeWithSelector(PredictionPoolFactory.DuplicateMarket.selector, MarketId)
        );
        vm.prank(Creator);
        factory.createPredictionPool(
            MarketId, uint64(block.timestamp), uint64(block.timestamp + 1 days), 100
        );
    }
}
