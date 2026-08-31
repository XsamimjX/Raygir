pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/poseidon.circom";

template BatchSettlement(bits) {
    signal input totalInputValue;
    signal input totalOutputValue;
    signal input publicFee;
    signal input previousRoot;
    signal input sequence;
    signal input batchDigest;
    signal output nextRoot;

    component inputRange = Num2Bits(bits);
    component outputRange = Num2Bits(bits);
    component feeRange = Num2Bits(bits);
    inputRange.in <== totalInputValue;
    outputRange.in <== totalOutputValue;
    feeRange.in <== publicFee;

    totalInputValue === totalOutputValue + publicFee;

    component root = Poseidon(5);
    root.inputs[0] <== previousRoot;
    root.inputs[1] <== sequence;
    root.inputs[2] <== batchDigest;
    root.inputs[3] <== totalOutputValue;
    root.inputs[4] <== publicFee;
    nextRoot <== root.out;
}

component main {public [previousRoot, sequence, batchDigest, publicFee]} = BatchSettlement(128);
