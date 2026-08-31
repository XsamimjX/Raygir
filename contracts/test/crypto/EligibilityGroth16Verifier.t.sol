// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { Groth16Verifier } from "../fixtures/EligibilityGroth16Verifier.sol";

contract EligibilityGroth16VerifierTest is Test {
    Groth16Verifier private verifier;

    function setUp() public {
        verifier = new Groth16Verifier();
    }

    function testAcceptsDualCredentialProofAndRejectsTampering() public view {
        (uint256[2] memory proofA, uint256[2][2] memory proofB, uint256[2] memory proofC) = _proof();
        uint256[11] memory publicSignals = _publicSignals();

        assertTrue(verifier.verifyProof(proofA, proofB, proofC, publicSignals));

        publicSignals[8] = 21;
        assertFalse(verifier.verifyProof(proofA, proofB, proofC, publicSignals));

        publicSignals[8] = 20;
        proofA[0] ^= 1;
        assertFalse(verifier.verifyProof(proofA, proofB, proofC, publicSignals));
    }

    function _proof()
        private
        pure
        returns (uint256[2] memory proofA, uint256[2][2] memory proofB, uint256[2] memory proofC)
    {
        proofA = [
            uint256(0x2154a4571065440414335f6e8c409df99181386c2679578f858c8ba033539b32),
            uint256(0x0d704a2643e92085102466f12671fb7c2a12a11678e0f08a608a0feeb415966b)
        ];
        proofB = [
            [
                uint256(0x222dead974c3709ed4e2e5f74b086548edbb687d05a113c8bdfb0de629def32d),
                uint256(0x1f5c3033fc1ee6e58b3c86c97ada422de1591dc2b16917865e91735223595515)
            ],
            [
                uint256(0x2c962ca3bca4c67dbaf6569cdbe814df6d5cfaadc6fb8798d9ab1ba166856be1),
                uint256(0x2334bb6404051d530751e8cf5f22d6395c9cf510fc4afc68493182f37f80da38)
            ]
        ];
        proofC = [
            uint256(0x24161bdcb6aff48b7a79fb0b947ba70ad100d6e2675345383a5a2640def56423),
            uint256(0x00a9b3e2eca4980a886118230e70bc6f1f8f897320be605dc2ce1d8a6bc88064)
        ];
    }

    function _publicSignals() private pure returns (uint256[11] memory publicSignals) {
        publicSignals = [
            uint256(0x1807289cc1a8e6745bf8b85402c6e44f26484581da2a38b9b0db0a0b98996f91),
            uint256(0x02a716a1b49a5ca11979049bd9992f7b78a6ebba49077c19cbe7bf8036631247),
            uint256(0x1d5ac1f31407018b7d413a4f52c8f74463b30e6ac2238220ad8b254de4eaa3a2),
            uint256(0x1e1de8a908826c3f9ac2e0ceee929ecd0caf3b99b3ef24523aaab796a6f733c4),
            uint256(0x1b12cf54db781ef719cb47880539d9c6c2faf0f286cc6ea5a03f8cb5bf4e4323),
            uint256(0x08837a72272fbe05181e30a3b29ce22fbf28d94671ec4770eda045f4c6dc11b6),
            uint256(7331),
            uint256(10),
            uint256(20),
            uint256(1),
            uint256(0)
        ];
    }
}
