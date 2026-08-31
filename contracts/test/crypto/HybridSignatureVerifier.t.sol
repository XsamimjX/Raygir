// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { HybridSignatureVerifier } from "../../src/crypto/HybridSignatureVerifier.sol";
import { IPostQuantumVerifier } from "../../src/crypto/IPostQuantumVerifier.sol";

contract DeterministicPqVerifierMock is IPostQuantumVerifier {
    function verify(bytes32 message, bytes calldata signature, bytes calldata publicKey)
        external
        pure
        returns (bool)
    {
        return keccak256(signature) == keccak256(abi.encode(message, keccak256(publicKey)));
    }
}

contract RevertingPqVerifierMock is IPostQuantumVerifier {
    function verify(bytes32, bytes calldata, bytes calldata) external pure returns (bool) {
        revert("verifier unavailable");
    }
}

contract HybridSignatureVerifierTest is Test {
    uint256 private constant CLASSICAL_PRIVATE_KEY = 0xC1A551C;
    uint64 private constant KEY_EPOCH = 1;
    bytes32 private constant RELEASE_DOMAIN = keccak256("SEPEHR_RELEASE_CERTIFICATE_V1");

    bytes private pqPublicKey = hex"010203040506";
    bytes private sha3Digest = new bytes(48);
    HybridSignatureVerifier private verifier;

    function setUp() public {
        for (uint256 i; i < sha3Digest.length; ++i) {
            // Safe because the fixed digest length is 48 bytes.
            // forge-lint: disable-next-line(unsafe-typecast)
            sha3Digest[i] = bytes1(uint8(i + 1));
        }

        verifier = new HybridSignatureVerifier(
            vm.addr(CLASSICAL_PRIVATE_KEY),
            new DeterministicPqVerifierMock(),
            pqPublicKey,
            KEY_EPOCH
        );
    }

    function testAcceptsOnlyTheCompleteHybridEnvelope() public view {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertTrue(
            verifier.verify(RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, classicalSignature, pqSignature)
        );
    }

    function testMissingPostQuantumSignatureFailsClosed() public view {
        (bytes memory classicalSignature,) = _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(verifier.verify(RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, classicalSignature, ""));
    }

    function testClassicalOnlySignatureFailsClosed() public view {
        (bytes memory classicalSignature,) = _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(verifier.verify(RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, classicalSignature, ""));
    }

    function testMissingClassicalSignatureFailsClosed() public view {
        (, bytes memory pqSignature) = _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(verifier.verify(RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, "", pqSignature));
    }

    function testSwappedAlgorithmSignaturesFailClosed() public view {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(
            verifier.verify(RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, pqSignature, classicalSignature)
        );
    }

    function testDomainChangeCannotReuseSignatures() public view {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(
            verifier.verify(
                keccak256("OTHER_DOMAIN"), sha3Digest, KEY_EPOCH, classicalSignature, pqSignature
            )
        );
    }

    function testKeyEpochChangeCannotReuseSignatures() public view {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(
            verifier.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH + 1, classicalSignature, pqSignature
            )
        );
    }

    function testArtifactChangeCannotReuseSignatures() public view {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);
        bytes memory differentDigest = bytes.concat(sha3Digest);
        differentDigest[0] ^= 0x01;

        assertFalse(
            verifier.verify(
                RELEASE_DOMAIN, differentDigest, KEY_EPOCH, classicalSignature, pqSignature
            )
        );
    }

    function testVerifierInstanceChangeCannotReuseSignatures() public {
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);
        HybridSignatureVerifier replacement = new HybridSignatureVerifier(
            vm.addr(CLASSICAL_PRIVATE_KEY),
            new DeterministicPqVerifierMock(),
            pqPublicKey,
            KEY_EPOCH
        );

        assertFalse(
            replacement.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, classicalSignature, pqSignature
            )
        );
    }

    function testKeyRotationRequiresNewVerifierAndRejectsOldEpoch() public {
        HybridSignatureVerifier replacement = new HybridSignatureVerifier(
            vm.addr(CLASSICAL_PRIVATE_KEY),
            new DeterministicPqVerifierMock(),
            pqPublicKey,
            KEY_EPOCH + 1
        );
        (bytes memory oldClassicalSignature, bytes memory oldPqSignature) =
            _sign(verifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);
        (bytes memory newClassicalSignature, bytes memory newPqSignature) =
            _sign(replacement, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH + 1);

        assertFalse(
            replacement.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, oldClassicalSignature, oldPqSignature
            )
        );
        assertTrue(
            replacement.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH + 1, newClassicalSignature, newPqSignature
            )
        );
        assertFalse(
            verifier.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, newClassicalSignature, newPqSignature
            )
        );
    }

    function testMalformedDigestIsRejected() public {
        vm.expectRevert(
            abi.encodeWithSelector(HybridSignatureVerifier.InvalidDigestLength.selector, 47)
        );
        verifier.envelopeDigest(RELEASE_DOMAIN, new bytes(47), KEY_EPOCH);
    }

    function testPostQuantumVerifierFailureFailsClosed() public {
        HybridSignatureVerifier unavailableVerifier = new HybridSignatureVerifier(
            vm.addr(CLASSICAL_PRIVATE_KEY), new RevertingPqVerifierMock(), pqPublicKey, KEY_EPOCH
        );
        (bytes memory classicalSignature, bytes memory pqSignature) =
            _sign(unavailableVerifier, RELEASE_DOMAIN, sha3Digest, KEY_EPOCH);

        assertFalse(
            unavailableVerifier.verify(
                RELEASE_DOMAIN, sha3Digest, KEY_EPOCH, classicalSignature, pqSignature
            )
        );
    }

    function _sign(
        HybridSignatureVerifier target,
        bytes32 domain,
        bytes memory digest,
        uint64 epoch
    ) private view returns (bytes memory classicalSignature, bytes memory pqSignature) {
        bytes32 message = target.envelopeDigest(domain, digest, epoch);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(CLASSICAL_PRIVATE_KEY, message);
        classicalSignature = abi.encodePacked(r, s, v);
        pqSignature = abi.encode(message, keccak256(pqPublicKey));
    }
}
