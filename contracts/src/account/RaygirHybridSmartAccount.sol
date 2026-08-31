// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Account } from "@openzeppelin/contracts/account/Account.sol";
import { IEntryPoint } from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import { WebAuthn } from "@openzeppelin/contracts/utils/cryptography/WebAuthn.sol";

import { IPostQuantumVerifier } from "../crypto/IPostQuantumVerifier.sol";

/// @notice Non-upgradeable ERC-4337 account requiring WebAuthn and ML-DSA authorization.
contract RaygirHybridSmartAccount is Account {
    IEntryPoint private immutable _entryPoint;
    bytes32 public immutable passkeyQx;
    bytes32 public immutable passkeyQy;
    IPostQuantumVerifier public immutable postQuantumVerifier;
    bytes public postQuantumPublicKey;

    error InvalidConfiguration();
    error CallFailed(bytes returnData);

    constructor(
        IEntryPoint initialEntryPoint,
        bytes32 initialPasskeyQx,
        bytes32 initialPasskeyQy,
        IPostQuantumVerifier initialPostQuantumVerifier,
        bytes memory initialPostQuantumPublicKey
    ) {
        if (
            address(initialEntryPoint) == address(0) || initialPasskeyQx == bytes32(0)
                || initialPasskeyQy == bytes32(0)
                || address(initialPostQuantumVerifier) == address(0)
                || initialPostQuantumPublicKey.length == 0
        ) {
            revert InvalidConfiguration();
        }

        _entryPoint = initialEntryPoint;
        passkeyQx = initialPasskeyQx;
        passkeyQy = initialPasskeyQy;
        postQuantumVerifier = initialPostQuantumVerifier;
        postQuantumPublicKey = initialPostQuantumPublicKey;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyEntryPointOrSelf
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = target.call{ value: value }(data);
        if (!success) {
            revert CallFailed(returnData);
        }
    }

    function verifyHybridSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool)
    {
        (WebAuthn.WebAuthnAuth memory passkey, bytes memory postQuantumSignature) =
            abi.decode(signature, (WebAuthn.WebAuthnAuth, bytes));
        if (!WebAuthn.verify(abi.encodePacked(hash), passkey, passkeyQx, passkeyQy)) {
            return false;
        }

        try postQuantumVerifier.verify(hash, postQuantumSignature, postQuantumPublicKey) returns (
            bool valid
        ) {
            return valid;
        } catch {
            return false;
        }
    }

    function _rawSignatureValidation(bytes32 hash, bytes calldata signature)
        internal
        view
        override
        returns (bool)
    {
        try this.verifyHybridSignature(hash, signature) returns (bool valid) {
            return valid;
        } catch {
            return false;
        }
    }
}
