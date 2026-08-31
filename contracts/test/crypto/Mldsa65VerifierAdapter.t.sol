// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { Mldsa65VerifierAdapter } from "../../src/crypto/Mldsa65VerifierAdapter.sol";

contract NativeVerifierFixture {
    bool private immutable _result;

    constructor(bool result) {
        _result = result;
    }

    fallback() external {
        bool result = _result;
        assembly ("memory-safe") {
            mstore(0, result)
            return(0, 32)
        }
    }
}

contract MalformedNativeVerifierFixture {
    fallback() external {
        assembly ("memory-safe") {
            mstore(0, 1)
            return(31, 1)
        }
    }
}

contract Mldsa65VerifierAdapterTest is Test {
    function testForwardsToConfiguredNativeVerifier() public {
        Mldsa65VerifierAdapter adapter =
            new Mldsa65VerifierAdapter(address(new NativeVerifierFixture(true)));

        assertTrue(adapter.verify(keccak256("message"), hex"01", hex"02"));
    }

    function testReturnsFalseForFalseMalformedOrUnavailableVerifier() public {
        Mldsa65VerifierAdapter rejecting =
            new Mldsa65VerifierAdapter(address(new NativeVerifierFixture(false)));
        Mldsa65VerifierAdapter malformed =
            new Mldsa65VerifierAdapter(address(new MalformedNativeVerifierFixture()));
        Mldsa65VerifierAdapter unavailable = new Mldsa65VerifierAdapter(address(0xDEAD));

        assertFalse(rejecting.verify(bytes32(0), "", ""));
        assertFalse(malformed.verify(bytes32(0), "", ""));
        assertFalse(unavailable.verify(bytes32(0), "", ""));
    }
}
