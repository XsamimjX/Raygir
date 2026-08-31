// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {
    IEntryPoint,
    PackedUserOperation
} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { WebAuthn } from "@openzeppelin/contracts/utils/cryptography/WebAuthn.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { P256 } from "@openzeppelin/contracts/utils/cryptography/P256.sol";
import { Test } from "forge-std/Test.sol";

import { RaygirHybridSmartAccount } from "../../src/account/RaygirHybridSmartAccount.sol";
import { IPostQuantumVerifier } from "../../src/crypto/IPostQuantumVerifier.sol";

contract HybridAccountPqVerifier is IPostQuantumVerifier {
    function verify(bytes32 message, bytes calldata signature, bytes calldata publicKey)
        external
        pure
        returns (bool)
    {
        return keccak256(signature) == keccak256(abi.encode(message, keccak256(publicKey)));
    }
}

contract RaygirHybridSmartAccountTest is Test {
    uint256 private constant PasskeyPrivateKey = 0xA11CE;
    bytes private postQuantumPublicKey = hex"010203040506";
    RaygirHybridSmartAccount private account;

    function setUp() public {
        (uint256 qx, uint256 qy) = vm.publicKeyP256(PasskeyPrivateKey);
        account = new RaygirHybridSmartAccount(
            IEntryPoint(address(0x4337)),
            bytes32(qx),
            bytes32(qy),
            new HybridAccountPqVerifier(),
            postQuantumPublicKey
        );
    }

    function testRequiresValidPasskeyAndPostQuantumSignatures() public view {
        bytes32 hash = keccak256("user-operation");
        WebAuthn.WebAuthnAuth memory passkey = _passkeySignature(hash);
        bytes memory postQuantumSignature = abi.encode(hash, keccak256(postQuantumPublicKey));

        assertTrue(account.verifyHybridSignature(hash, abi.encode(passkey, postQuantumSignature)));
        assertFalse(account.verifyHybridSignature(hash, abi.encode(passkey, bytes(""))));

        passkey.r ^= bytes32(uint256(1));
        assertFalse(account.verifyHybridSignature(hash, abi.encode(passkey, postQuantumSignature)));
    }

    function testMalformedEnvelopeFailsClosedDuringAccountValidation() public {
        vm.prank(address(0x4337));
        assertEq(account.validateUserOp(_userOperation("malformed"), bytes32(uint256(1)), 0), 1);
    }

    function _passkeySignature(bytes32 hash) private view returns (WebAuthn.WebAuthnAuth memory) {
        bytes memory authenticatorData = new bytes(37);
        authenticatorData[32] = bytes1(uint8(0x05));
        string memory clientDataJSON = string.concat(
            '{"type":"webauthn.get","challenge":"', Base64.encodeURL(abi.encodePacked(hash)), '"}'
        );
        bytes32 messageHash =
            sha256(abi.encodePacked(authenticatorData, sha256(bytes(clientDataJSON))));
        (bytes32 r, bytes32 s) = vm.signP256(PasskeyPrivateKey, messageHash);

        return WebAuthn.WebAuthnAuth({
            r: r,
            s: bytes32(Math.min(uint256(s), P256.N - uint256(s))),
            challengeIndex: 23,
            typeIndex: 1,
            authenticatorData: authenticatorData,
            clientDataJSON: clientDataJSON
        });
    }

    function _userOperation(bytes memory signature)
        private
        pure
        returns (PackedUserOperation memory operation)
    {
        operation.signature = signature;
    }
}
