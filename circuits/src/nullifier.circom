pragma circom 2.2.3;

include "circomlib/circuits/poseidon.circom";

template PollNullifier() {
    signal input holderSecret;
    signal input chainId;
    signal input verifierContract;
    signal input pollId;
    signal input policyVersion;
    signal input creditCounter;
    signal output scope;
    signal output nullifier;

    component scopeHash = Poseidon(4);
    scopeHash.inputs[0] <== chainId;
    scopeHash.inputs[1] <== verifierContract;
    scopeHash.inputs[2] <== pollId;
    scopeHash.inputs[3] <== policyVersion;
    scope <== scopeHash.out;

    component nullifierHash = Poseidon(3);
    nullifierHash.inputs[0] <== holderSecret;
    nullifierHash.inputs[1] <== scopeHash.out;
    nullifierHash.inputs[2] <== creditCounter;
    nullifier <== nullifierHash.out;
}

component main {public [chainId, verifierContract, pollId, policyVersion, creditCounter]} =
    PollNullifier();
