// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

interface IShieldedNoteVerifier {
    function verify(
        bytes calldata proof,
        bytes32 commitment,
        bytes32 nullifier,
        address recipient,
        uint128 amount
    ) external view returns (bool);
}
