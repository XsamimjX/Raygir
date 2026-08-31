pragma circom 2.2.3;

include "circomlib/circuits/poseidon.circom";

template SettlementRoot() {
    signal input previousRoot;
    signal input sequence;
    signal input tradesDigest;
    signal output settlementRoot;

    component hash = Poseidon(3);
    hash.inputs[0] <== previousRoot;
    hash.inputs[1] <== sequence;
    hash.inputs[2] <== tradesDigest;
    settlementRoot <== hash.out;
}

component main {public [previousRoot, sequence, tradesDigest]} = SettlementRoot();
