pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/poseidon.circom";

template Claim(bits) {
    signal input ownerSecret;
    signal input blinding;
    signal input pollId;
    signal input payoutValue;
    signal input positionCommitment;
    signal output claimNullifier;

    component payoutRange = Num2Bits(bits);
    payoutRange.in <== payoutValue;

    component commitment = Poseidon(4);
    commitment.inputs[0] <== ownerSecret;
    commitment.inputs[1] <== pollId;
    commitment.inputs[2] <== payoutValue;
    commitment.inputs[3] <== blinding;
    positionCommitment === commitment.out;

    component nullifier = Poseidon(3);
    nullifier.inputs[0] <== ownerSecret;
    nullifier.inputs[1] <== pollId;
    nullifier.inputs[2] <== positionCommitment;
    claimNullifier <== nullifier.out;
}

component main {public [pollId, payoutValue, positionCommitment]} = Claim(128);
