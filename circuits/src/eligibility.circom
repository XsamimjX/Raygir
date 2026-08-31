pragma circom 2.2.3;

include "circomlib/circuits/poseidon.circom";
include "dual-credential-signature-template.circom";

template Eligibility() {
    signal input holderSecret;
    signal input credentialBlinding;
    signal input authorityPublicKey[2];
    signal input raygirPublicKey[2];
    signal input authoritySignatureR8[2];
    signal input authoritySignatureS;
    signal input raygirSignatureR8[2];
    signal input raygirSignatureS;
    signal output credentialCommitment;
    signal input chainId;
    signal input verifierContract;
    signal input pollId;
    signal input policyVersion;
    signal input creditCounter;
    signal output nullifier;

    component credential = Poseidon(3);
    credential.inputs[0] <== holderSecret;
    credential.inputs[1] <== credentialBlinding;
    credential.inputs[2] <== policyVersion;
    credentialCommitment <== credential.out;

    component approvals = DualCredentialSignature();
    approvals.credentialCommitment <== credential.out;
    approvals.authorityPublicKey[0] <== authorityPublicKey[0];
    approvals.authorityPublicKey[1] <== authorityPublicKey[1];
    approvals.raygirPublicKey[0] <== raygirPublicKey[0];
    approvals.raygirPublicKey[1] <== raygirPublicKey[1];
    approvals.authoritySignatureR8[0] <== authoritySignatureR8[0];
    approvals.authoritySignatureR8[1] <== authoritySignatureR8[1];
    approvals.authoritySignatureS <== authoritySignatureS;
    approvals.raygirSignatureR8[0] <== raygirSignatureR8[0];
    approvals.raygirSignatureR8[1] <== raygirSignatureR8[1];
    approvals.raygirSignatureS <== raygirSignatureS;

    component scope = Poseidon(5);
    scope.inputs[0] <== chainId;
    scope.inputs[1] <== verifierContract;
    scope.inputs[2] <== pollId;
    scope.inputs[3] <== policyVersion;
    scope.inputs[4] <== creditCounter;

    component nullifierHash = Poseidon(2);
    nullifierHash.inputs[0] <== holderSecret;
    nullifierHash.inputs[1] <== scope.out;
    nullifier <== nullifierHash.out;
}

component main {public [chainId, verifierContract, pollId, policyVersion, creditCounter, authorityPublicKey, raygirPublicKey]} = Eligibility();
