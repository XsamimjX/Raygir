// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @notice Fixed metadata for cryptographic algorithms permitted by one protocol release.
contract CryptographicAlgorithmRegistry {
    enum Kind {
        Signature,
        Digest,
        Proof
    }

    struct Algorithm {
        bytes32 id;
        Kind kind;
        bool postQuantum;
        uint16 claimedSecurityBits;
        address implementation;
        bytes32 specificationHash;
    }

    mapping(bytes32 id => Algorithm algorithm) private algorithms;

    error InvalidAlgorithm(bytes32 id);
    error DuplicateAlgorithm(bytes32 id);
    error UnknownAlgorithm(bytes32 id);

    constructor(Algorithm[] memory initialAlgorithms) {
        uint256 algorithmCount = initialAlgorithms.length;
        for (uint256 i; i < algorithmCount; ++i) {
            Algorithm memory algorithm = initialAlgorithms[i];
            if (
                algorithm.id == bytes32(0) || algorithm.claimedSecurityBits == 0
                    || algorithm.specificationHash == bytes32(0)
            ) {
                revert InvalidAlgorithm(algorithm.id);
            }
            if (algorithms[algorithm.id].id != bytes32(0)) {
                revert DuplicateAlgorithm(algorithm.id);
            }
            algorithms[algorithm.id] = algorithm;
        }
    }

    function get(bytes32 id) external view returns (Algorithm memory algorithm) {
        algorithm = algorithms[id];
        if (algorithm.id == bytes32(0)) {
            revert UnknownAlgorithm(id);
        }
    }
}

