// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Test } from "forge-std/Test.sol";

import { ClobSettlement } from "../../src/markets/ClobSettlement.sol";

contract ClobAsset is ERC20 {
    constructor() ERC20("Ray", "RAY") { }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract ClobPositions is ERC1155 {
    constructor() ERC1155("") { }

    function mint(address account, uint256 id, uint256 amount) external {
        _mint(account, id, amount, "");
    }
}

contract ClobSettlementTest is Test {
    uint256 private constant BUYER_KEY = 0xA11CE;
    uint256 private constant SELLER_KEY = 0xB0B;
    address private constant MATCHER = address(0xCAFE);

    ClobAsset private collateral;
    ClobPositions private positions;
    ClobSettlement private settlement;
    address private buyer;
    address private seller;

    function setUp() public {
        buyer = vm.addr(BUYER_KEY);
        seller = vm.addr(SELLER_KEY);
        collateral = new ClobAsset();
        positions = new ClobPositions();
        settlement = new ClobSettlement(collateral, positions, MATCHER);
        collateral.mint(buyer, 100 ether);
        positions.mint(seller, 1, 100 ether);
        vm.prank(buyer);
        collateral.approve(address(settlement), type(uint256).max);
        vm.prank(seller);
        positions.setApprovalForAll(address(settlement), true);
    }

    function testPartialFillsAndRejectsOverfill() public {
        ClobSettlement.Order memory buy = _order(buyer, 10 ether, 0.6 ether, 1, true);
        ClobSettlement.Order memory sell = _order(seller, 10 ether, 0.5 ether, 2, false);
        bytes memory buySignature = _sign(BUYER_KEY, buy);
        bytes memory sellSignature = _sign(SELLER_KEY, sell);

        vm.prank(MATCHER);
        settlement.settle(buy, buySignature, sell, sellSignature, 4 ether, 0.55 ether);
        vm.prank(MATCHER);
        settlement.settle(buy, buySignature, sell, sellSignature, 6 ether, 0.55 ether);

        assertEq(positions.balanceOf(buyer, 1), 10 ether);
        assertEq(collateral.balanceOf(seller), 5.5 ether);
        vm.expectRevert(ClobSettlement.Overfilled.selector);
        vm.prank(MATCHER);
        settlement.settle(buy, buySignature, sell, sellSignature, 1, 0.55 ether);
    }

    function testCancellationAndSignatureBinding() public {
        ClobSettlement.Order memory buy = _order(buyer, 10 ether, 0.6 ether, 1, true);
        ClobSettlement.Order memory sell = _order(seller, 10 ether, 0.5 ether, 2, false);
        bytes memory buySignature = _sign(BUYER_KEY, buy);
        bytes memory sellSignature = _sign(SELLER_KEY, sell);
        vm.prank(buyer);
        settlement.cancel(1);

        vm.expectRevert(ClobSettlement.InvalidMatch.selector);
        vm.prank(MATCHER);
        settlement.settle(buy, buySignature, sell, sellSignature, 1 ether, 0.55 ether);
    }

    function _order(address maker, uint256 amount, uint256 price, uint256 nonce, bool isBuy)
        private
        view
        returns (ClobSettlement.Order memory)
    {
        return ClobSettlement.Order({
            maker: maker,
            tokenId: 1,
            amount: amount,
            price: price,
            nonce: nonce,
            expiry: uint64(block.timestamp + 1 days),
            isBuy: isBuy
        });
    }

    function _sign(uint256 key, ClobSettlement.Order memory order)
        private
        view
        returns (bytes memory)
    {
        bytes32 digest = settlement.hashOrder(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }
}
