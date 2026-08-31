// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import {
    CryptographicAlgorithmRegistry
} from "../../src/crypto/CryptographicAlgorithmRegistry.sol";

contract CryptographicAlgorithmRegistryTest is Test {
    bytes32 private constant ML_DSA_65 = keccak256("ml-dsa-65-fips-204-v1");
    bytes32 private constant SPECIFICATION_HASH = keccak256("FIPS-204");
    address private constant VERIFIER = address(0x6001);

    function testReturnsPinnedAlgorithmMetadata() public {
        CryptographicAlgorithmRegistry registry = _registry();
        CryptographicAlgorithmRegistry.Algorithm memory algorithm = registry.get(ML_DSA_65);

        assertEq(algorithm.id, ML_DSA_65);
        assertEq(uint8(algorithm.kind), uint8(CryptographicAlgorithmRegistry.Kind.Signature));
        assertTrue(algorithm.postQuantum);
        assertEq(algorithm.claimedSecurityBits, 192);
        assertEq(algorithm.implementation, VERIFIER);
        assertEq(algorithm.specificationHash, SPECIFICATION_HASH);
    }

    function testUnknownAlgorithmReverts() public {
        CryptographicAlgorithmRegistry registry = _registry();
        bytes32 unknown = keccak256("unknown");

        vm.expectRevert(
            abi.encodeWithSelector(
                CryptographicAlgorithmRegistry.UnknownAlgorithm.selector, unknown
            )
        );
        registry.get(unknown);
    }

    function testDuplicateAlgorithmReverts() public {
        CryptographicAlgorithmRegistry.Algorithm[] memory algorithms =
            new CryptographicAlgorithmRegistry.Algorithm[](2);
        algorithms[0] = _algorithm();
        algorithms[1] = _algorithm();

        vm.expectRevert(
            abi.encodeWithSelector(
                CryptographicAlgorithmRegistry.DuplicateAlgorithm.selector, ML_DSA_65
            )
        );
        new CryptographicAlgorithmRegistry(algorithms);
    }

    function _registry() private returns (CryptographicAlgorithmRegistry) {
        CryptographicAlgorithmRegistry.Algorithm[] memory algorithms =
            new CryptographicAlgorithmRegistry.Algorithm[](1);
        algorithms[0] = _algorithm();
        return new CryptographicAlgorithmRegistry(algorithms);
    }

    function _algorithm() private pure returns (CryptographicAlgorithmRegistry.Algorithm memory) {
        return CryptographicAlgorithmRegistry.Algorithm({
            id: ML_DSA_65,
            kind: CryptographicAlgorithmRegistry.Kind.Signature,
            postQuantum: true,
            claimedSecurityBits: 192,
            implementation: VERIFIER,
            specificationHash: SPECIFICATION_HASH
        });
    }
}
