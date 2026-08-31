// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface INoirVerifier {
    function verify(bytes calldata proof, bytes32[] calldata publicInputs)
        external
        view
        returns (bool);
}
