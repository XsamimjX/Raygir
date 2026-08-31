// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { MockSepTomanOracle } from "../../src/assets/MockSepTomanOracle.sol";
import { SepehrToman } from "../../src/assets/SepehrToman.sol";
import { SptmSale } from "../../src/assets/SptmSale.sol";

contract SepehrTomanTest is Test {
    uint256 private constant ORACLE_PRIVATE_KEY = 0xA11CE;
    uint64 private constant MAX_AGE = 1 hours;
    uint256 private constant SEP_PRICE = 50_000_000;

    address private oracleSigner;
    address payable private treasury;
    address private buyer;
    MockSepTomanOracle private oracle;
    SepehrToman private sptm;
    SptmSale private sale;

    function setUp() public {
        oracleSigner = vm.addr(ORACLE_PRIVATE_KEY);
        treasury = payable(address(0x7001));
        buyer = address(0x7002);
        vm.deal(buyer, 2 ether);
        vm.warp(10_000);

        oracle = new MockSepTomanOracle(oracleSigner, MAX_AGE);
        sptm = new SepehrToman(oracle, treasury);
        sale = sptm.sale();

        _publishPrice(SEP_PRICE, uint64(block.timestamp), 1, uint64(block.timestamp + 5 minutes));
    }

    function testUsesSixDecimalsAndOneThousandTomanDisplayUnit() public view {
        assertEq(sptm.decimals(), 6);
        assertEq(sale.quote(1 ether), 50_000 * 1e6);
    }

    function testHigherSepPriceMakesTheSameSepBuyMoreSptm() public {
        uint256 quoteBefore = sale.quote(1 ether);
        _publishPrice(100_000_000, uint64(block.timestamp), 2, uint64(block.timestamp + 5 minutes));

        assertEq(sale.quote(1 ether), quoteBefore * 2);
    }

    function testFuzzQuoteMatchesReferenceFormula(uint128 sepWei) public view {
        assertEq(sale.quote(sepWei), uint256(sepWei) * SEP_PRICE / 1e15);
    }

    function testPurchaseMintsQuotedAmountAndForwardsSep() public {
        uint256 treasuryBefore = treasury.balance;

        vm.prank(buyer);
        uint256 minted = sale.buy{ value: 0.5 ether }(buyer);

        assertEq(minted, 25_000 * 1e6);
        assertEq(sptm.balanceOf(buyer), minted);
        assertEq(treasury.balance, treasuryBefore + 0.5 ether);
        assertEq(address(sale).balance, 0);
    }

    function testSptmRemainsTransferable() public {
        address recipient = address(0x7003);
        vm.prank(buyer);
        sale.buy{ value: 0.5 ether }(buyer);

        vm.prank(buyer);
        assertTrue(sptm.transfer(recipient, 1_000 * 1e6));

        assertEq(sptm.balanceOf(recipient), 1_000 * 1e6);
    }

    function testOnlySaleCanMint() public {
        vm.expectRevert(abi.encodeWithSelector(SepehrToman.UnauthorizedMinter.selector, buyer));
        vm.prank(buyer);
        sptm.mintFromSale(buyer, 1e6);
    }

    function testRejectsStalePrice() public {
        vm.warp(block.timestamp + MAX_AGE + 1);

        vm.expectPartialRevert(MockSepTomanOracle.StalePrice.selector);
        sale.quote(1 ether);
    }

    function testRejectsWrongOracleSigner() public {
        uint64 nextNonce = 2;
        uint64 deadline = uint64(block.timestamp + 5 minutes);
        bytes32 digest = _priceDigest(60_000_000, uint64(block.timestamp), nextNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xB0B, digest);

        vm.expectPartialRevert(MockSepTomanOracle.InvalidSigner.selector);
        oracle.updatePrice(
            60_000_000, uint64(block.timestamp), nextNonce, deadline, abi.encodePacked(r, s, v)
        );
    }

    function testRejectsReplayedOracleUpdate() public {
        uint64 deadline = uint64(block.timestamp + 5 minutes);
        bytes32 digest = _priceDigest(SEP_PRICE, uint64(block.timestamp), 1, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_PRIVATE_KEY, digest);

        vm.expectRevert(abi.encodeWithSelector(MockSepTomanOracle.InvalidNonce.selector, 2, 1));
        oracle.updatePrice(
            SEP_PRICE, uint64(block.timestamp), 1, deadline, abi.encodePacked(r, s, v)
        );
    }

    function _publishPrice(uint256 price, uint64 timestamp, uint64 nextNonce, uint64 deadline)
        private
    {
        bytes32 digest = _priceDigest(price, timestamp, nextNonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_PRIVATE_KEY, digest);
        oracle.updatePrice(price, timestamp, nextNonce, deadline, abi.encodePacked(r, s, v));
    }

    function _priceDigest(uint256 price, uint64 timestamp, uint64 nextNonce, uint64 deadline)
        private
        view
        returns (bytes32)
    {
        return oracle.hashPriceUpdate(price, timestamp, nextNonce, deadline);
    }
}
