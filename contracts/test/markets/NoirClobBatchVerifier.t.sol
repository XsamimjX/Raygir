// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { INoirVerifier } from "../../src/markets/INoirVerifier.sol";
import { NoirClobBatchVerifier } from "../../src/markets/NoirClobBatchVerifier.sol";

contract RecordingNoirVerifier is INoirVerifier {
    bytes32 public inputsHash;
    bool public valid = true;

    function setValid(bool value) external {
        valid = value;
    }

    function verify(bytes calldata proof, bytes32[] calldata publicInputs)
        external
        view
        returns (bool)
    {
        return valid && proof.length != 0 && keccak256(abi.encode(publicInputs)) == inputsHash;
    }

    function expectInputs(bytes32[] calldata publicInputs) external {
        inputsHash = keccak256(abi.encode(publicInputs));
    }
}

contract NoirClobBatchVerifierTest is Test {
    function testBindsThePinnedNoirPublicInputOrder() public {
        RecordingNoirVerifier noir = new RecordingNoirVerifier();
        NoirClobBatchVerifier adapter = new NoirClobBatchVerifier(noir);
        bytes32[] memory expected = new bytes32[](7);
        expected[0] = bytes32(uint256(1));
        expected[1] = bytes32(uint256(7));
        expected[2] = bytes32(uint256(9));
        expected[3] = bytes32(uint256(900));
        expected[4] = bytes32(uint256(2));
        expected[5] = bytes32(uint256(3));
        expected[6] = bytes32(uint256(4));
        noir.expectInputs(expected);

        assertTrue(adapter.verify(hex"1234", expected[0], expected[6], 7, expected[5], 9, 900, 2));
        noir.setValid(false);
        assertFalse(adapter.verify(hex"1234", expected[0], expected[6], 7, expected[5], 9, 900, 2));
    }
}
