// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface IPostQuantumVerifier {
    function verify(bytes32 message, bytes calldata signature, bytes calldata publicKey)
        external
        view
        returns (bool);
}

