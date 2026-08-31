import assert from 'node:assert/strict';
import test from 'node:test';

import { benchmarkMldsa65, sha3384Artifact } from '../tools/ml-dsa-65.mjs';

test('generates a real ML-DSA-65 signature and SHA3-384 artifact digest', () => {
    const result = benchmarkMldsa65();

    assert.equal(result.valid, true);
    assert.equal(result.signatureBytes, 3309);
    assert.equal(result.publicKeyDerBytes, 1974);
    assert.equal(result.sha3384.length, 96);
    assert.equal(sha3384Artifact(Buffer.from('sepehr')).length, 48);
});
