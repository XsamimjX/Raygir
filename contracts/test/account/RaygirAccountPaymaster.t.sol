// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import {
    IEntryPoint,
    IPaymaster,
    PackedUserOperation
} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";

import { RaygirPaymaster } from "../../src/account/RaygirPaymaster.sol";
import { RaygirSmartAccount } from "../../src/account/RaygirSmartAccount.sol";

contract ExecutionTarget {
    uint256 public value;

    function setValue(uint256 newValue) external payable returns (uint256) {
        value = newValue;
        return newValue + 1;
    }
}

contract RaygirAccountPaymasterTest is Test {
    uint256 private constant OWNER_KEY = 0xA11CE;
    uint256 private constant POLICY_KEY = 0xB0B;
    uint256 private constant MAXIMUM_COST = 0.02 ether;
    address private constant ENTRY_POINT_ADDRESS = address(0x4337);

    IEntryPoint private entryPoint = IEntryPoint(ENTRY_POINT_ADDRESS);
    RaygirSmartAccount private account;
    RaygirPaymaster private paymaster;

    function setUp() public {
        account = new RaygirSmartAccount(entryPoint, vm.addr(OWNER_KEY));
        paymaster = new RaygirPaymaster(entryPoint, vm.addr(POLICY_KEY), MAXIMUM_COST);
    }

    function testEntryPointCanExecuteButUnrelatedCallerCannot() public {
        ExecutionTarget target = new ExecutionTarget();
        bytes memory callData = abi.encodeCall(target.setValue, (42));

        vm.expectRevert(abi.encodeWithSignature("AccountUnauthorized(address)", address(this)));
        account.execute(address(target), 0, callData);

        vm.prank(ENTRY_POINT_ADDRESS);
        bytes memory result = account.execute(address(target), 0, callData);

        assertEq(target.value(), 42);
        assertEq(abi.decode(result, (uint256)), 43);
    }

    function testAccountAcceptsOwnerSignatureAndRejectsAnotherSigner() public {
        bytes32 userOpHash = keccak256("operation");
        PackedUserOperation memory userOp = _emptyUserOperation(address(account));
        userOp.signature = _sign(OWNER_KEY, userOpHash);

        vm.prank(ENTRY_POINT_ADDRESS);
        assertEq(account.validateUserOp(userOp, userOpHash, 0), 0);

        userOp.signature = _sign(POLICY_KEY, userOpHash);
        vm.prank(ENTRY_POINT_ADDRESS);
        assertEq(account.validateUserOp(userOp, userOpHash, 0), 1);
    }

    function testPaymasterRequiresPolicySignatureAndReturnsTimeBounds() public {
        uint256 maxCost = 0.01 ether;
        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = validAfter + 10 minutes;
        bytes32 quotaId = keccak256("daily-account-quota");
        PackedUserOperation memory userOp =
            _authorizedUserOperation(maxCost, validAfter, validUntil, quotaId, POLICY_KEY);

        vm.prank(ENTRY_POINT_ADDRESS);
        (bytes memory context, uint256 validationData) =
            paymaster.validatePaymasterUserOp(userOp, keccak256("unused"), maxCost);

        assertEq(abi.decode(context, (bytes32)), quotaId);
        assertEq(validationData >> 160 & type(uint48).max, validUntil);
        assertEq(validationData >> 208 & type(uint48).max, validAfter);
    }

    function testPaymasterRejectsTamperedCallData() public {
        uint256 maxCost = 0.01 ether;
        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = validAfter + 10 minutes;
        PackedUserOperation memory userOp = _authorizedUserOperation(
            maxCost, validAfter, validUntil, keccak256("quota"), POLICY_KEY
        );
        userOp.callData = abi.encodeWithSignature("differentCall()");

        vm.expectRevert(RaygirPaymaster.InvalidAuthorization.selector);
        vm.prank(ENTRY_POINT_ADDRESS);
        paymaster.validatePaymasterUserOp(userOp, bytes32(0), maxCost);
    }

    function testPaymasterRejectsCostAboveProtocolCap() public {
        PackedUserOperation memory userOp = _emptyUserOperation(address(account));

        vm.expectRevert(
            abi.encodeWithSelector(
                RaygirPaymaster.CostLimitExceeded.selector, MAXIMUM_COST + 1, MAXIMUM_COST
            )
        );
        vm.prank(ENTRY_POINT_ADDRESS);
        paymaster.validatePaymasterUserOp(userOp, bytes32(0), MAXIMUM_COST + 1);
    }

    function testOnlyEntryPointCanAccountForSponsoredGas() public {
        bytes32 quotaId = keccak256("quota");
        bytes memory context = abi.encode(quotaId);

        vm.expectRevert(
            abi.encodeWithSelector(RaygirPaymaster.UnauthorizedCaller.selector, address(this))
        );
        paymaster.postOp(IPaymaster.PostOpMode.opSucceeded, context, 100, 1);

        vm.prank(ENTRY_POINT_ADDRESS);
        paymaster.postOp(IPaymaster.PostOpMode.opSucceeded, context, 100, 1);
        assertEq(paymaster.spentByQuota(quotaId), 100);
    }

    function _authorizedUserOperation(
        uint256 maxCost,
        uint48 validAfter,
        uint48 validUntil,
        bytes32 quotaId,
        uint256 signerKey
    ) private view returns (PackedUserOperation memory userOp) {
        userOp = _emptyUserOperation(address(account));
        userOp.callData = abi.encodeCall(account.execute, (address(0xCAFE), 0, bytes("")));
        bytes32 digest = paymaster.authorizationDigest(
            userOp.sender, keccak256(userOp.callData), maxCost, validAfter, validUntil, quotaId
        );
        bytes memory signature = _sign(signerKey, digest);
        userOp.paymasterAndData = abi.encodePacked(
            address(paymaster),
            bytes16(uint128(100_000)),
            bytes16(uint128(50_000)),
            abi.encode(validAfter, validUntil, quotaId, signature)
        );
    }

    function _emptyUserOperation(address sender)
        private
        pure
        returns (PackedUserOperation memory userOp)
    {
        userOp.sender = sender;
    }

    function _sign(uint256 privateKey, bytes32 digest)
        private
        pure
        returns (bytes memory signature)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
