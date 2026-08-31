// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { IClobBatchVerifier } from "../../src/markets/IClobBatchVerifier.sol";
import { ShieldedClobBatchSettlement } from "../../src/markets/ShieldedClobBatchSettlement.sol";

contract MockClobBatchVerifier is IClobBatchVerifier {
    bool public valid = true;

    function setValid(bool value) external {
        valid = value;
    }

    function verify(bytes calldata, bytes32, bytes32, uint64, bytes32, uint128, uint64, uint8)
        external
        view
        returns (bool)
    {
        return valid;
    }
}

contract ShieldedClobBatchSettlementTest is Test {
    address private constant MATCHER = address(0xB47C);
    bytes32 private constant INITIAL_ROOT = bytes32(uint256(1));
    bytes32 private constant NEXT_ROOT = bytes32(uint256(2));
    bytes32 private constant DIGEST = bytes32(uint256(3));

    MockClobBatchVerifier private verifier;
    ShieldedClobBatchSettlement private settlement;

    function setUp() public {
        verifier = new MockClobBatchVerifier();
        settlement = new ShieldedClobBatchSettlement(verifier, MATCHER, INITIAL_ROOT, 7);
    }

    function testMatcherAdvancesAValidProvenRootExactlyOnce() public {
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 2);

        assertEq(settlement.currentRoot(), NEXT_ROOT);
        assertEq(settlement.nextSequence(), 8);
        assertTrue(settlement.batchSettled(DIGEST));

        vm.expectRevert(ShieldedClobBatchSettlement.InvalidTransition.selector);
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 2);
    }

    function testRejectsUnauthorizedOutOfOrderAndForgedTransitions() public {
        vm.expectRevert(
            abi.encodeWithSelector(ShieldedClobBatchSettlement.Unauthorized.selector, address(this))
        );
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 2);

        vm.expectRevert(ShieldedClobBatchSettlement.InvalidTransition.selector);
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 8, DIGEST, 0, 2);

        verifier.setValid(false);
        vm.expectRevert(ShieldedClobBatchSettlement.InvalidProof.selector);
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 2);
    }

    function testRejectsEmptyOrOversizedBatches() public {
        vm.expectRevert(ShieldedClobBatchSettlement.InvalidTransition.selector);
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 0);

        vm.expectRevert(ShieldedClobBatchSettlement.InvalidTransition.selector);
        vm.prank(MATCHER);
        settlement.settle(hex"1234", INITIAL_ROOT, NEXT_ROOT, 7, DIGEST, 0, 3);
    }
}
