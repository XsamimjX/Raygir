// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IPostQuantumVerifier } from "./IPostQuantumVerifier.sol";

/// @notice Requires both secp256k1 and ML-DSA-65 authorization for a SHA3-384 artifact digest.
contract HybridSignatureVerifier {
    bytes32 public constant CLASSICAL_ALGORITHM = keccak256("secp256k1-keccak256-v1");
    bytes32 public constant POST_QUANTUM_ALGORITHM = keccak256("ml-dsa-65-fips-204-v1");
    bytes32 public constant DIGEST_ALGORITHM = keccak256("sha3-384-fips-202-v1");
    bytes32 public constant ENVELOPE_TYPEHASH = keccak256(
        "HybridEnvelope(uint256 chainId,address verifier,bytes32 domain,bytes48 artifactDigest,uint64 keyEpoch,bytes32 classicalAlgorithm,bytes32 postQuantumAlgorithm,bytes32 digestAlgorithm)"
    );

    address public immutable classicalSigner;
    IPostQuantumVerifier public immutable postQuantumVerifier;
    uint64 public immutable keyEpoch;
    bytes public postQuantumPublicKey;

    error InvalidConfiguration();
    error InvalidDigestLength(uint256 received);

    constructor(
        address initialClassicalSigner,
        IPostQuantumVerifier initialPostQuantumVerifier,
        bytes memory initialPostQuantumPublicKey,
        uint64 initialKeyEpoch
    ) {
        if (
            initialClassicalSigner == address(0)
                || address(initialPostQuantumVerifier) == address(0)
                || initialPostQuantumPublicKey.length == 0 || initialKeyEpoch == 0
        ) {
            revert InvalidConfiguration();
        }

        classicalSigner = initialClassicalSigner;
        postQuantumVerifier = initialPostQuantumVerifier;
        postQuantumPublicKey = initialPostQuantumPublicKey;
        keyEpoch = initialKeyEpoch;
    }

    function verify(
        bytes32 domain,
        bytes calldata artifactDigest,
        uint64 envelopeKeyEpoch,
        bytes calldata classicalSignature,
        bytes calldata postQuantumSignature
    ) external view returns (bool) {
        bytes32 message = envelopeDigest(domain, artifactDigest, envelopeKeyEpoch);
        if (envelopeKeyEpoch != keyEpoch) {
            return false;
        }

        (address recovered, ECDSA.RecoverError error,) =
            ECDSA.tryRecover(message, classicalSignature);
        if (error != ECDSA.RecoverError.NoError || recovered != classicalSigner) {
            return false;
        }

        try postQuantumVerifier.verify(
            message, postQuantumSignature, postQuantumPublicKey
        ) returns (
            bool valid
        ) {
            return valid;
        } catch {
            return false;
        }
    }

    function envelopeDigest(bytes32 domain, bytes calldata artifactDigest, uint64 envelopeKeyEpoch)
        public
        view
        returns (bytes32)
    {
        if (artifactDigest.length != 48) {
            revert InvalidDigestLength(artifactDigest.length);
        }

        return keccak256(
            abi.encode(
                ENVELOPE_TYPEHASH,
                block.chainid,
                address(this),
                domain,
                keccak256(artifactDigest),
                envelopeKeyEpoch,
                CLASSICAL_ALGORITHM,
                POST_QUANTUM_ALGORITHM,
                DIGEST_ALGORITHM
            )
        );
    }
}

