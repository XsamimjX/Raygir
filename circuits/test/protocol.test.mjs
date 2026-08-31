import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { wasm } from 'circom_tester';

const directory = path.dirname(fileURLToPath(import.meta.url));
const include = path.resolve(directory, '../node_modules');

async function circuit(name) {
    return wasm(path.resolve(directory, `../src/${name}.circom`), { include: [include] });
}

test('note ownership accepts the preimage and rejects a forged owner', async () => {
    const commitment = await circuit('commitment');
    const base = { ownerSecret: 11, assetId: 22, value: 33, blinding: 44 };
    const commitmentWitness = await commitment.calculateWitness(base);
    const ownership = await circuit('note-ownership');
    await ownership.checkConstraints(
        await ownership.calculateWitness({ ...base, expectedCommitment: commitmentWitness[1] }),
    );
    await assert.rejects(
        ownership.calculateWitness({ ...base, ownerSecret: 12, expectedCommitment: commitmentWitness[1] }),
    );
});

test('eligibility binds the credential and changes nullifier across polls', async () => {
    const eligibility = await circuit('eligibility');
    const privateInputs = {
        holderSecret: 7,
        credentialBlinding: 9,
        authorityPublicKey: [
            '13277427435165878497778222415993513565335242147425444199013288855685581939618',
            '13622229784656158136036771217484571176836296686641868549125388198837476602820',
        ],
        raygirPublicKey: [
            '12245681108156315862721578421537205412164963293078065541324995831326019830563',
            '3850804844767147361944551138681828170238733301762589784617578364038335435190',
        ],
        authoritySignatureR8: [
            '3346298855409515383464823232731539032900141739613162363952813518327464643779',
            '17026526495364541899783482920412572679621903523734326488403370573275723409845',
        ],
        authoritySignatureS:
            '1729440658945771217802443744496372991810871391699746193041176487383904342519',
        raygirSignatureR8: [
            '17628878068552521970984603917453237520281780694889215048311075043058515256212',
            '9938155777191259253121417418974811955727066765090469258807897593871516286683',
        ],
        raygirSignatureS:
            '279550579103942587904673557100188732390342125458137531930777547299771199899',
    };
    const credentialProbe = await eligibility.calculateWitness({
        ...privateInputs,
        chainId: 7331,
        verifierContract: 10,
        pollId: 20,
        policyVersion: 1,
        creditCounter: 0,
    });
    await eligibility.checkConstraints(credentialProbe);
    const anotherPoll = await eligibility.calculateWitness({
        ...privateInputs,
        chainId: 7331,
        verifierContract: 10,
        pollId: 21,
        policyVersion: 1,
        creditCounter: 0,
    });
    assert.equal(credentialProbe[1], anotherPoll[1]);
    assert.notEqual(credentialProbe[2], anotherPoll[2]);
    await assert.rejects(
        eligibility.calculateWitness({
            ...privateInputs,
            chainId: 7331,
            verifierContract: 10,
            pollId: 20,
            policyVersion: 1,
            creditCounter: 0,
            raygirSignatureS: BigInt(privateInputs.raygirSignatureS) + 1n,
        }),
    );
});

test('stake circuit conserves value and rejects inflation', async () => {
    const stake = await circuit('stake-conservation');
    await stake.checkConstraints(
        await stake.calculateWitness({ inputValue: 100, stakeValue: 60, changeValue: 40 }),
    );
    await assert.rejects(
        stake.calculateWitness({ inputValue: 100, stakeValue: 101, changeValue: 0 }),
    );
});

test('settlement root is deterministic and binds sequence and trades', async () => {
    const settlement = await circuit('settlement-root');
    const valid = { previousRoot: 1, sequence: 2, tradesDigest: 3 };
    const first = await settlement.calculateWitness(valid);
    const repeated = await settlement.calculateWitness(valid);
    const nextSequence = await settlement.calculateWitness({ ...valid, sequence: 3 });
    await settlement.checkConstraints(first);
    assert.equal(first[1], repeated[1]);
    assert.notEqual(first[1], nextSequence[1]);
});

test('claim binds owner, poll, payout, commitment, and nullifier', async () => {
    const claim = await circuit('claim');
    const commitment = await circuit('commitment');
    const commitmentWitness = await commitment.calculateWitness({
        ownerSecret: 17,
        assetId: 23,
        value: 29,
        blinding: 19,
    });
    const valid = {
        ownerSecret: 17,
        blinding: 19,
        pollId: 23,
        payoutValue: 29,
        positionCommitment: commitmentWitness[1],
    };
    const witness = await claim.calculateWitness(valid);

    await claim.checkConstraints(witness);
    assert.notEqual(witness[1], 0n);
    await assert.rejects(
        claim.calculateWitness({ ...valid, ownerSecret: 18 }),
    );
});

test('batch settlement conserves value and binds the next root', async () => {
    const batch = await circuit('batch-settlement');
    const valid = {
        totalInputValue: 100,
        totalOutputValue: 98,
        publicFee: 2,
        previousRoot: 31,
        sequence: 32,
        batchDigest: 33,
    };
    const first = await batch.calculateWitness(valid);
    const nextSequence = await batch.calculateWitness({ ...valid, sequence: 33 });

    await batch.checkConstraints(first);
    assert.notEqual(first[1], nextSequence[1]);
    await assert.rejects(
        batch.calculateWitness({ ...valid, totalOutputValue: 99 }),
    );
});

test('civic tally proves per-ballot and aggregate credit conservation', async () => {
    const tally = await circuit('civic-tally');
    const valid = {
        pollId: 404,
        active: [1, 1, 0, 0],
        ballotCredits: [2, 1, 0, 0],
        allocations: [
            [1, 1, 0, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
        ],
        optionEnabled: [1, 1, 0, 0, 0, 0, 0, 0],
    };
    const witness = await tally.calculateWitness(valid);

    await tally.checkConstraints(witness);
    assert.equal(witness[1], 1n);
    assert.equal(witness[2], 2n);
    assert.equal(witness[9], 3n);
    await assert.rejects(
        tally.calculateWitness({
            ...valid,
            ballotCredits: [3, 1, 0, 0],
        }),
    );
    await assert.rejects(
        tally.calculateWitness({
            ...valid,
            allocations: valid.allocations.map((allocation, index) =>
                index === 0 ? [1, 1, 1, 0, 0, 0, 0, 0] : allocation,
            ),
        }),
    );
});

test('dual credential signatures require both authority and Raygir approval', async () => {
    const signatures = await circuit('dual-credential-signature');
    const valid = {
        credentialCommitment: 1234,
        authorityPublicKey: [
            '13277427435165878497778222415993513565335242147425444199013288855685581939618',
            '13622229784656158136036771217484571176836296686641868549125388198837476602820',
        ],
        raygirPublicKey: [
            '12245681108156315862721578421537205412164963293078065541324995831326019830563',
            '3850804844767147361944551138681828170238733301762589784617578364038335435190',
        ],
        authoritySignatureR8: [
            '11220723668893468001994760120794694848178115379170651044669708829805665054484',
            '2367470421002446880004241260470975644531657398480773647535134774673409612366',
        ],
        authoritySignatureS:
            '2010143491207902444122668013146870263468969134090678646686512037244361350365',
        raygirSignatureR8: [
            '442467359286068636881583441150348092703129235019411969149377982462406852673',
            '12108733997773210011401126518872675046532716969781712966608786460583778010048',
        ],
        raygirSignatureS:
            '2183141878115019927719033519601757306487012305691712894510576771672617461552',
    };

    await signatures.checkConstraints(await signatures.calculateWitness(valid));
    await assert.rejects(
        signatures.calculateWitness({ ...valid, raygirSignatureS: BigInt(valid.raygirSignatureS) + 1n }),
    );
    await assert.rejects(
        signatures.calculateWitness({ ...valid, credentialCommitment: 1235 }),
    );
});
