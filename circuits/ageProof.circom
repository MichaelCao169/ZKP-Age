pragma circom 2.0.0;

include "../lib/circomlib/circuits/comparators.circom";
include "../lib/circomlib/circuits/bitify.circom";

template AgeProof() {
    // Input signals
    signal input age;       
    signal input threshold; 
    signal input nonce;     

    // Output signal
    signal output valid;    

    // Range checks
    component age_range = Num2Bits(32);
    component threshold_range = Num2Bits(32);
    
    age_range.in <== age;
    threshold_range.in <== threshold;

    // Compare age >= threshold
    component comparator = GreaterEqThan(32);
    comparator.in[0] <== age;
    comparator.in[1] <== threshold;

    // Set result
    valid <== comparator.out;
}

component main = AgeProof();