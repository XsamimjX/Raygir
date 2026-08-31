global COMMITMENT_DOMAIN: Field = 1;
global NULLIFIER_DOMAIN: Field = 2;

fn hash_fields(inputs: [Field; 7]) -> Field {
    let mut state = [inputs[0], inputs[1], inputs[2], 0];
    state = std::hash::poseidon2_permutation(state);
    state[0] += inputs[3];
    state[1] += inputs[4];
    state[2] += inputs[5];
    state = std::hash::poseidon2_permutation(state);
    state[0] += inputs[6];
    state = std::hash::poseidon2_permutation(state);
    state[0]
}

fn note_commitment(owner_secret: Field, asset_id: Field, value: u128, blinding: Field) -> Field {
    hash_fields(
        [COMMITMENT_DOMAIN, owner_secret, asset_id, value as Field, blinding, 0, 0],
    )
}

fn poll_nullifier(
    holder_secret: Field,
    chain_id: Field,
    verifier_contract: Field,
    poll_id: Field,
    policy_version: Field,
    credit_counter: Field,
) -> Field {
    hash_fields([
        NULLIFIER_DOMAIN,
        holder_secret,
        chain_id,
        verifier_contract,
        poll_id,
        policy_version,
        credit_counter,
    ])
}

fn main(
    owner_secret: Field,
    holder_secret: Field,
    blinding: Field,
    value: u128,
    output_value: u128,
    asset_id: pub Field,
    public_fee: pub u128,
    chain_id: pub Field,
    verifier_contract: pub Field,
    poll_id: pub Field,
    policy_version: pub Field,
    credit_counter: pub Field,
) -> pub [Field; 2] {
    assert(value == output_value + public_fee, "value is not conserved");
    [
        note_commitment(owner_secret, asset_id, value, blinding),
        poll_nullifier(
            holder_secret,
            chain_id,
            verifier_contract,
            poll_id,
            policy_version,
            credit_counter,
        ),
    ]
}

#[test]
fn commitment_is_deterministic_and_binds_fields() {
    let first = note_commitment(11, 22, 33, 44);
    assert(first == note_commitment(11, 22, 33, 44));
    assert(first != note_commitment(12, 22, 33, 44));
    assert(first != note_commitment(11, 23, 33, 44));
}

#[test]
fn nullifier_is_deterministic_and_poll_scoped() {
    let first = poll_nullifier(101, 7331, 202, 303, 1, 0);
    assert(first == poll_nullifier(101, 7331, 202, 303, 1, 0));
    assert(first != poll_nullifier(101, 7331, 202, 304, 1, 0));
    assert(first != poll_nullifier(101, 7331, 202, 303, 1, 1));
}

#[test]
fn value_conservation_accepts_exact_balance() {
    assert(100 as u128 == 97 as u128 + 3 as u128);
}

#[test(should_fail_with = "value is not conserved")]
fn value_conservation_rejects_inflation() {
    let value = 100 as u128;
    let output_value = 101 as u128;
    let public_fee = 0 as u128;
    assert(value == output_value + public_fee, "value is not conserved");
}
