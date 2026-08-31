pragma circom 2.2.3;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/poseidon.circom";

template CivicTally(ballots, options, bits) {
    signal input pollId;
    signal input active[ballots];
    signal input ballotCredits[ballots];
    signal input allocations[ballots][options];
    signal input optionEnabled[options];
    signal output optionTotals[options];
    signal output revealedCredits;
    signal output tallyRoot;

    signal ballotAccumulator[ballots][options + 1];
    signal optionAccumulator[options][ballots + 1];
    signal revealedAccumulator[ballots + 1];
    component creditRange[ballots];
    component allocationRange[ballots][options];

    revealedAccumulator[0] <== 0;
    for (var option = 0; option < options; option++) {
        optionEnabled[option] * (optionEnabled[option] - 1) === 0;
        optionAccumulator[option][0] <== 0;
    }

    for (var ballot = 0; ballot < ballots; ballot++) {
        active[ballot] * (active[ballot] - 1) === 0;
        ballotCredits[ballot] * (1 - active[ballot]) === 0;

        creditRange[ballot] = Num2Bits(bits);
        creditRange[ballot].in <== ballotCredits[ballot];
        ballotAccumulator[ballot][0] <== 0;

        for (var option = 0; option < options; option++) {
            allocationRange[ballot][option] = Num2Bits(bits);
            allocationRange[ballot][option].in <== allocations[ballot][option];
            allocations[ballot][option] * (1 - active[ballot]) === 0;
            allocations[ballot][option] * (1 - optionEnabled[option]) === 0;
            ballotAccumulator[ballot][option + 1] <==
                ballotAccumulator[ballot][option] + allocations[ballot][option];
            optionAccumulator[option][ballot + 1] <==
                optionAccumulator[option][ballot] + allocations[ballot][option];
        }

        ballotAccumulator[ballot][options] === ballotCredits[ballot];
        revealedAccumulator[ballot + 1] <==
            revealedAccumulator[ballot] + ballotCredits[ballot];
    }

    for (var option = 0; option < options; option++) {
        optionTotals[option] <== optionAccumulator[option][ballots];
    }
    revealedCredits <== revealedAccumulator[ballots];

    component root = Poseidon(options + 2);
    root.inputs[0] <== pollId;
    for (var option = 0; option < options; option++) {
        root.inputs[option + 1] <== optionTotals[option];
    }
    root.inputs[options + 1] <== revealedCredits;
    tallyRoot <== root.out;
}

component main {public [pollId, optionEnabled]} = CivicTally(4, 8, 32);
