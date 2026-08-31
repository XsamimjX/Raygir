import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { wasm } from 'circom_tester';
import { poseidon4 } from 'poseidon-lite/poseidon4';

const directory = path.dirname(fileURLToPath(import.meta.url));
const include = path.resolve(directory, '../node_modules');

test('commitment binds the private note fields', async () => {
    const circuit = await wasm(path.resolve(directory, '../src/commitment.circom'), {
        include: [include],
    });
    const witness = await circuit.calculateWitness({
        ownerSecret: 11,
        assetId: 22,
        value: 33,
        blinding: 44,
    });

    await circuit.checkConstraints(witness);
    assert.equal(witness[1], poseidon4([11n, 22n, 33n, 44n]));
});

test('poll nullifiers are deterministic and scoped', async () => {
    const circuit = await wasm(path.resolve(directory, '../src/nullifier.circom'), {
        include: [include],
    });
    const base = {
        holderSecret: 101,
        chainId: 7331,
        verifierContract: 202,
        pollId: 303,
        policyVersion: 1,
        creditCounter: 0,
    };
    const first = await circuit.calculateWitness(base);
    const repeated = await circuit.calculateWitness(base);
    const anotherPoll = await circuit.calculateWitness({ ...base, pollId: 304 });

    await circuit.checkConstraints(first);
    assert.equal(first[1], repeated[1]);
    assert.notEqual(first[1], anotherPoll[1]);
});

test('value conservation accepts exact balance', async () => {
    const circuit = await wasm(path.resolve(directory, '../src/value-conservation.circom'), {
        include: [include],
    });
    const witness = await circuit.calculateWitness({ inputValue: 100, outputValue: 97, publicFee: 3 });

    await circuit.checkConstraints(witness);
});

test('value conservation rejects inflation', async () => {
    const circuit = await wasm(path.resolve(directory, '../src/value-conservation.circom'), {
        include: [include],
    });

    await assert.rejects(
        circuit.calculateWitness({ inputValue: 100, outputValue: 101, publicFee: 0 }),
    );
});
