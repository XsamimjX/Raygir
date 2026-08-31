// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { RayToken } from "../../src/assets/RayToken.sol";
import { CreationFeeEscrow } from "../../src/protocol/CreationFeeEscrow.sol";
import { ProtocolTreasury } from "../../src/protocol/ProtocolTreasury.sol";

contract CreationFeeEscrowTest is Test {
    uint256 private constant REVIEW_PRIVATE_KEY = 0xA55E55;
    address private constant CONTROLLER = address(0x4001);
    address private constant FAUCET = address(0x4002);
    address private constant POOL = address(0x4003);
    address private constant PAYER = address(0x4004);
    bytes32 private constant POLL_ID = keccak256("poll-1");
    uint128 private constant FEE = 100 ether;

    ProtocolTreasury private treasury;
    CreationFeeEscrow private escrow;
    RayToken private ray;

    function setUp() public {
        treasury = new ProtocolTreasury(CONTROLLER);

        uint64 deploymentNonce = vm.getNonce(address(this));
        address predictedRay = vm.computeCreateAddress(address(this), deploymentNonce + 1);
        escrow = new CreationFeeEscrow(
            RayToken(predictedRay), address(treasury), vm.addr(REVIEW_PRIVATE_KEY)
        );

        address[] memory routes = new address[](1);
        routes[0] = address(escrow);
        ray = new RayToken(POOL, FAUCET, address(treasury), routes);
        assertEq(address(ray), predictedRay);

        vm.prank(FAUCET);
        assertTrue(ray.transfer(PAYER, 1_000 ether));
        vm.prank(PAYER);
        ray.approve(address(escrow), type(uint256).max);
    }

    function testApprovalSendsTheWholeFeeToTreasury() public {
        uint256 treasuryBefore = ray.balanceOf(address(treasury));
        _deposit(POLL_ID);
        _resolve(POLL_ID, CreationFeeEscrow.Decision.Approved);

        assertEq(ray.balanceOf(address(treasury)), treasuryBefore + FEE);
        assertEq(ray.balanceOf(address(escrow)), 0);
    }

    function testContentRejectionRefundsNinetyPercent() public {
        uint256 payerBefore = ray.balanceOf(PAYER);
        uint256 treasuryBefore = ray.balanceOf(address(treasury));
        _deposit(POLL_ID);
        _resolve(POLL_ID, CreationFeeEscrow.Decision.ContentRejected);

        assertEq(ray.balanceOf(address(treasury)), treasuryBefore + FEE / 10);
        assertEq(ray.balanceOf(PAYER), payerBefore - FEE / 10);
        assertEq(ray.balanceOf(address(escrow)), 0);
    }

    function testProviderFailureRefundsEverything() public {
        uint256 payerBefore = ray.balanceOf(PAYER);
        uint256 treasuryBefore = ray.balanceOf(address(treasury));
        _deposit(POLL_ID);
        _resolve(POLL_ID, CreationFeeEscrow.Decision.ProviderFailure);

        assertEq(ray.balanceOf(PAYER), payerBefore);
        assertEq(ray.balanceOf(address(treasury)), treasuryBefore);
    }

    function testWrongSignerCannotResolve() public {
        _deposit(POLL_ID);
        uint64 deadline = uint64(block.timestamp + 5 minutes);
        bytes32 digest = escrow.hashDecision(POLL_ID, CreationFeeEscrow.Decision.Approved, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBAD, digest);

        vm.expectPartialRevert(CreationFeeEscrow.InvalidReviewSigner.selector);
        escrow.resolve(
            POLL_ID, CreationFeeEscrow.Decision.Approved, deadline, abi.encodePacked(r, s, v)
        );
    }

    function testCannotResolveTwice() public {
        _deposit(POLL_ID);
        _resolve(POLL_ID, CreationFeeEscrow.Decision.Approved);

        uint64 deadline = uint64(block.timestamp + 5 minutes);
        bytes32 digest = escrow.hashDecision(POLL_ID, CreationFeeEscrow.Decision.Approved, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(REVIEW_PRIVATE_KEY, digest);
        vm.expectRevert(
            abi.encodeWithSelector(CreationFeeEscrow.DepositNotPending.selector, POLL_ID)
        );
        escrow.resolve(
            POLL_ID, CreationFeeEscrow.Decision.Approved, deadline, abi.encodePacked(r, s, v)
        );
    }

    function testControllerCanWithdrawTreasuryToken() public {
        _deposit(POLL_ID);
        _resolve(POLL_ID, CreationFeeEscrow.Decision.Approved);

        vm.prank(CONTROLLER);
        treasury.withdrawToken(ray, CONTROLLER, FEE);
        assertEq(ray.balanceOf(CONTROLLER), FEE);
    }

    function _deposit(bytes32 pollId) private {
        vm.prank(PAYER);
        escrow.deposit(pollId, FEE);
    }

    function _resolve(bytes32 pollId, CreationFeeEscrow.Decision decision) private {
        uint64 deadline = uint64(block.timestamp + 5 minutes);
        bytes32 digest = escrow.hashDecision(pollId, decision, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(REVIEW_PRIVATE_KEY, digest);
        escrow.resolve(pollId, decision, deadline, abi.encodePacked(r, s, v));
    }
}
