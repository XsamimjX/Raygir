pragma circom 2.2.3;

include "circomlib/circuits/eddsaposeidon.circom";

template DualCredentialSignature() {
    signal input credentialCommitment;
    signal input authorityPublicKey[2];
    signal input raygirPublicKey[2];
    signal input authoritySignatureR8[2];
    signal input authoritySignatureS;
    signal input raygirSignatureR8[2];
    signal input raygirSignatureS;

    component authority = EdDSAPoseidonVerifier();
    authority.enabled <== 1;
    authority.Ax <== authorityPublicKey[0];
    authority.Ay <== authorityPublicKey[1];
    authority.R8x <== authoritySignatureR8[0];
    authority.R8y <== authoritySignatureR8[1];
    authority.S <== authoritySignatureS;
    authority.M <== credentialCommitment;

    component raygir = EdDSAPoseidonVerifier();
    raygir.enabled <== 1;
    raygir.Ax <== raygirPublicKey[0];
    raygir.Ay <== raygirPublicKey[1];
    raygir.R8x <== raygirSignatureR8[0];
    raygir.R8y <== raygirSignatureR8[1];
    raygir.S <== raygirSignatureS;
    raygir.M <== credentialCommitment;
}
