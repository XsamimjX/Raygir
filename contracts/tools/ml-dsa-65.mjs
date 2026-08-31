import { createHash, generateKeyPairSync, sign, verify } from 'node:crypto';
import { fileURLToPath } from 'node:url';

export function sha3384Artifact(content) {
    return createHash('sha3-384').update(content).digest();
}

export function benchmarkMldsa65(message = Buffer.from('sepehr-ml-dsa-65-benchmark-v1')) {
    const { publicKey, privateKey } = generateKeyPairSync('ml-dsa-65');
    const startedAt = process.hrtime.bigint();
    const signature = sign(null, message, privateKey);
    const signedAt = process.hrtime.bigint();
    const valid = verify(null, message, publicKey, signature);
    const verifiedAt = process.hrtime.bigint();

    return {
        valid,
        signatureBytes: signature.length,
        publicKeyDerBytes: publicKey.export({ type: 'spki', format: 'der' }).length,
        sha3384: sha3384Artifact(message).toString('hex'),
        signMicroseconds: Number((signedAt - startedAt) / 1000n),
        verifyMicroseconds: Number((verifiedAt - signedAt) / 1000n),
    };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
    process.stdout.write(`${JSON.stringify(benchmarkMldsa65(), null, 2)}\n`);
}
