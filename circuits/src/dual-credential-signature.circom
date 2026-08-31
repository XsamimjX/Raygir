pragma circom 2.2.3;

include "dual-credential-signature-template.circom";

component main {public [credentialCommitment, authorityPublicKey, raygirPublicKey]} =
    DualCredentialSignature();
