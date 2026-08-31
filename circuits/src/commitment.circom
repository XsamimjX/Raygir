pragma circom 2.2.3;

include "circomlib/circuits/poseidon.circom";

template Commitment() {
    signal input ownerSecret;
    signal input assetId;
    signal input value;
    signal input blinding;
    signal output commitment;

    component hash = Poseidon(4);
    hash.inputs[0] <== ownerSecret;
    hash.inputs[1] <== assetId;
    hash.inputs[2] <== value;
    hash.inputs[3] <== blinding;
    commitment <== hash.out;
}

component main {public [assetId]} = Commitment();
