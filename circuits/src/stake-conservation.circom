pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";

template StakeConservation(bits) {
    signal input inputValue;
    signal input stakeValue;
    signal input changeValue;

    component inputRange = Num2Bits(bits);
    component stakeRange = Num2Bits(bits);
    component changeRange = Num2Bits(bits);
    inputRange.in <== inputValue;
    stakeRange.in <== stakeValue;
    changeRange.in <== changeValue;
    inputValue === stakeValue + changeValue;
}

component main {public [stakeValue]} = StakeConservation(128);
