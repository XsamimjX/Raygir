// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IPostQuantumVerifier } from "./IPostQuantumVerifier.sol";

/// @notice Fail-closed adapter for a chain-native ML-DSA-65 verifier contract or precompile.
contract Mldsa65VerifierAdapter is IPostQuantumVerifier {
    address public immutable nativeVerifier;

    error InvalidConfiguration();

    constructor(address initialNativeVerifier) {
        if (initialNativeVerifier == address(0)) {
            revert InvalidConfiguration();
        }

        nativeVerifier = initialNativeVerifier;
    }

    function verify(bytes32 message, bytes calldata signature, bytes calldata publicKey)
        external
        view
        returns (bool)
    {
        (bool success, bytes memory result) =
            nativeVerifier.staticcall(abi.encodePacked(message, publicKey, signature));

        return success && result.length == 32 && abi.decode(result, (bool));
    }
}
