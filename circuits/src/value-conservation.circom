pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";

template ValueConservation(maxBits) {
    signal input inputValue;
    signal input outputValue;
    signal input publicFee;

    component inputRange = Num2Bits(maxBits);
    inputRange.in <== inputValue;

    component outputRange = Num2Bits(maxBits);
    outputRange.in <== outputValue;

    component feeRange = Num2Bits(maxBits);
    feeRange.in <== publicFee;

    inputValue === outputValue + publicFee;
}

component main {public [publicFee]} = ValueConservation(128);
