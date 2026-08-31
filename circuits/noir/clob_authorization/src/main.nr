global MAX_MATCHES: u32 = 2;
global QUOTE_ASSET_ID: Field = 1;
global TREE_DEPTH: u32 = 16;

struct PrivateOrderData {
    market_id: Field,
    token_id: Field,
    amount: u128,
    price: u128,
    nonce: u64,
    expiry: u64,
}

struct AuthorizedOrder {
    data: PrivateOrderData,
    public_key_x: [u8; 32],
    public_key_y: [u8; 32],
    signature: [u8; 64],
}

struct PrivateExecution {
    fill_amount: u128,
    execution_price: u128,
}

struct BalanceWitness {
    balance: u128,
    blinding: Field,
    new_blinding: Field,
    index: u32,
    siblings: [Field; 16],
}

struct PrivateStateTransition {
    buyer_quote: BalanceWitness,
    seller_outcome: BalanceWitness,
    buyer_outcome: BalanceWitness,
    seller_quote: BalanceWitness,
}

struct PublicSettlement {
    previous_root: Field,
    sequence: u64,
    public_fee: u128,
    settlement_time: u64,
}

fn order_digest(order: PrivateOrderData, order_side: Field) -> Field {
    let mut state = [21, order.market_id, order.token_id, order_side];
    state = std::hash::poseidon2_permutation(state);
    state[0] += order.amount as Field;
    state[1] += order.price as Field;
    state[2] += order.nonce as Field;
    state[3] += order.expiry as Field;
    std::hash::poseidon2_permutation(state)[0]
}

fn bytes_limb(bytes: [u8; 32], offset: u32) -> Field {
    let mut value = 0;
    for i in 0..16 {
        value = value * 256 + bytes[offset + i] as Field;
    }
    value
}

fn owner_digest(public_key_x: [u8; 32], public_key_y: [u8; 32]) -> Field {
    let mut state = [
        23,
        bytes_limb(public_key_x, 0),
        bytes_limb(public_key_x, 16),
        bytes_limb(public_key_y, 0),
    ];
    state = std::hash::poseidon2_permutation(state);
    state[0] += bytes_limb(public_key_y, 16);
    std::hash::poseidon2_permutation(state)[0]
}

fn balance_leaf(owner: Field, asset_id: Field, balance: u128, blinding: Field) -> Field {
    let mut state = std::hash::poseidon2_permutation([
        24,
        owner,
        asset_id,
        balance as Field,
    ]);
    state[0] += blinding;
    std::hash::poseidon2_permutation(state)[0]
}

fn merkle_node(left: Field, right: Field) -> Field {
    std::hash::poseidon2_permutation([25, left, right, 0])[0]
}

fn merkle_root(leaf: Field, index: u32, siblings: [Field; 16]) -> Field {
    assert(index < 65536, "balance index is outside the tree");
    let mut node = leaf;
    for level in 0..TREE_DEPTH {
        let is_right = ((index >> level) & 1) == 1;
        node = if is_right {
            merkle_node(siblings[level], node)
        } else {
            merkle_node(node, siblings[level])
        };
    }
    node
}

fn update_balance(
    root: Field,
    owner: Field,
    asset_id: Field,
    new_balance: u128,
    witness: BalanceWitness,
) -> Field {
    let old_leaf = balance_leaf(owner, asset_id, witness.balance, witness.blinding);
    assert(
        merkle_root(old_leaf, witness.index, witness.siblings) == root,
        "balance is not in the current root",
    );
    let new_leaf = balance_leaf(owner, asset_id, new_balance, witness.new_blinding);
    merkle_root(new_leaf, witness.index, witness.siblings)
}

fn authorized_match_digest(
    buy_digest: Field,
    sell_digest: Field,
    fill_amount: u128,
    execution_price: u128,
) -> Field {
    std::hash::poseidon2_permutation([
        buy_digest,
        sell_digest,
        fill_amount as Field,
        execution_price as Field,
    ])[0]
}

fn authorized_batch_digest(
    match_digests: [Field; 2],
    match_count: u8,
    previous_root: Field,
    sequence: u64,
    settlement_time: u64,
) -> Field {
    let mut state = [22, match_count as Field, previous_root, sequence as Field];
    for i in 0..MAX_MATCHES {
        if i < match_count as u32 {
            state[0] += match_digests[i];
            state[1] += i as Field;
            state = std::hash::poseidon2_permutation(state);
        }
    }
    state[1] += settlement_time as Field;
    state = std::hash::poseidon2_permutation(state);
    state[0]
}

fn validate_match(
    buy: AuthorizedOrder,
    sell: AuthorizedOrder,
    execution: PrivateExecution,
    settlement_time: u64,
) -> [Field; 8] {
    let AuthorizedOrder { data: buy_data, public_key_x: buy_x, public_key_y: buy_y, signature: buy_sig } = buy;
    let AuthorizedOrder { data: sell_data, public_key_x: sell_x, public_key_y: sell_y, signature: sell_sig } = sell;
    let PrivateExecution { fill_amount, execution_price } = execution;

    assert(fill_amount > 0, "fill amount is zero");
    assert(execution_price > 0, "execution price is zero");
    assert(fill_amount <= buy_data.amount, "buy order is overfilled");
    assert(fill_amount <= sell_data.amount, "sell order is overfilled");
    assert(execution_price <= buy_data.price, "buy limit is exceeded");
    assert(execution_price >= sell_data.price, "sell limit is not met");
    assert(buy_data.expiry >= settlement_time, "buy order is expired");
    assert(sell_data.expiry >= settlement_time, "sell order is expired");
    assert(buy_data.market_id == sell_data.market_id, "market mismatch");
    assert(buy_data.token_id == sell_data.token_id, "token mismatch");
    assert(buy_data.token_id != QUOTE_ASSET_ID, "outcome asset equals quote asset");
    let same_x = buy_x == sell_x;
    let same_y = buy_y == sell_y;
    assert(!(same_x & same_y), "self match is forbidden");

    let buy_digest = order_digest(buy_data, 1);
    let sell_digest = order_digest(sell_data, 2);
    let buy_hash: [u8; 32] = buy_digest.to_be_bytes();
    let sell_hash: [u8; 32] = sell_digest.to_be_bytes();
    assert(
        std::ecdsa_secp256k1::verify_signature(buy_x, buy_y, buy_sig, buy_hash),
        "buy authorization is invalid",
    );
    assert(
        std::ecdsa_secp256k1::verify_signature(sell_x, sell_y, sell_sig, sell_hash),
        "sell authorization is invalid",
    );

    let quote_value = fill_amount * execution_price;
    [
        authorized_match_digest(buy_digest, sell_digest, fill_amount, execution_price),
        buy_digest,
        sell_digest,
        owner_digest(buy_x, buy_y),
        owner_digest(sell_x, sell_y),
        buy_data.token_id,
        fill_amount as Field,
        quote_value as Field,
    ]
}

fn apply_match_state(
    root: Field,
    validated: [Field; 8],
    state_transition: PrivateStateTransition,
) -> Field {
    let buyer_owner = validated[3];
    let seller_owner = validated[4];
    let outcome_asset_id = validated[5];
    let fill_amount = validated[6] as u128;
    let quote_value = validated[7] as u128;
    let PrivateStateTransition { buyer_quote, seller_outcome, buyer_outcome, seller_quote } = state_transition;

    assert(buyer_quote.balance >= quote_value, "buyer quote balance is insufficient");
    assert(seller_outcome.balance >= fill_amount, "seller outcome balance is insufficient");
    let mut next_root = update_balance(
        root,
        buyer_owner,
        QUOTE_ASSET_ID,
        buyer_quote.balance - quote_value,
        buyer_quote,
    );
    next_root = update_balance(
        next_root,
        seller_owner,
        outcome_asset_id,
        seller_outcome.balance - fill_amount,
        seller_outcome,
    );
    next_root = update_balance(
        next_root,
        buyer_owner,
        outcome_asset_id,
        buyer_outcome.balance + fill_amount,
        buyer_outcome,
    );
    update_balance(
        next_root,
        seller_owner,
        QUOTE_ASSET_ID,
        seller_quote.balance + quote_value,
        seller_quote,
    )
}

fn main(
    buys: [AuthorizedOrder; 2],
    sells: [AuthorizedOrder; 2],
    executions: [PrivateExecution; 2],
    state_transitions: [PrivateStateTransition; 2],
    settlement: pub PublicSettlement,
    match_count: pub u8,
) -> pub [Field; 2] {
    let PublicSettlement { previous_root, sequence, public_fee, settlement_time } = settlement;
    assert(match_count > 0, "batch is empty");
    assert(match_count as u32 <= MAX_MATCHES, "batch is too large");

    let mut match_digests = [0; 2];
    let mut buy_digests = [0; 2];
    let mut sell_digests = [0; 2];
    let mut next_root = previous_root;
    for i in 0..MAX_MATCHES {
        if i < match_count as u32 {
            let validated = validate_match(buys[i], sells[i], executions[i], settlement_time);
            match_digests[i] = validated[0];
            buy_digests[i] = validated[1];
            sell_digests[i] = validated[2];
            next_root = apply_match_state(next_root, validated, state_transitions[i]);
        }
    }
    if match_count == 2 {
        assert(buy_digests[0] != buy_digests[1], "buy order is repeated");
        assert(sell_digests[0] != sell_digests[1], "sell order is repeated");
    }
    assert(public_fee == 0, "fees are disabled");

    let batch_digest = authorized_batch_digest(
        match_digests,
        match_count,
        previous_root,
        sequence,
        settlement_time,
    );
    [
        batch_digest,
        next_root,
    ]
}

#[test]
fn batch_digest_binds_count_order_and_matches() {
    let matches = [1, 2];
    let digest = authorized_batch_digest(matches, 2, 3, 4, 5);
    assert(digest == authorized_batch_digest(matches, 2, 3, 4, 5));
    assert(digest != authorized_batch_digest([2, 1], 2, 3, 4, 5));
    assert(digest != authorized_batch_digest(matches, 1, 3, 4, 5));
    assert(digest != authorized_batch_digest([1, 3], 2, 3, 4, 5));
    assert(digest != authorized_batch_digest(matches, 2, 3, 5, 5));
}

#[test]
fn merkle_root_binds_leaf_path_and_index() {
    let path = [2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    let changed_path = [3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    let root = merkle_root(1, 0, path);
    assert(root != merkle_root(2, 0, path));
    assert(root != merkle_root(1, 1, path));
    assert(root != merkle_root(1, 0, changed_path));
}

#[test(should_fail_with = "buyer quote balance is insufficient")]
fn rejects_balance_overspend_before_state_update() {
    let empty = BalanceWitness {
        balance: 5,
        blinding: 1,
        new_blinding: 2,
        index: 0,
        siblings: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    };
    let transition = PrivateStateTransition {
        buyer_quote: empty,
        seller_outcome: empty,
        buyer_outcome: empty,
        seller_quote: empty,
    };
    let _ = apply_match_state(1, [0, 0, 0, 1, 2, 3, 1, 10], transition);
}

#[test(should_fail_with = "balance is not in the current root")]
fn rejects_stale_balance_path() {
    let witness = BalanceWitness {
        balance: 5,
        blinding: 1,
        new_blinding: 2,
        index: 0,
        siblings: [3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    };
    let _ = update_balance(1, 2, 3, 4, witness);
}
