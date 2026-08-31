import { ml_dsa65 } from '@noble/post-quantum/ml-dsa.js';
import { poseidon4 } from 'poseidon-lite/poseidon4';

const DATABASE_NAME = 'raygir-local-voter-vault';
const DATABASE_VERSION = 2;
const STORE_NAME = 'vaults';
const NOTE_STORE_NAME = 'shielded-notes';
const PRIMARY_VAULT = 'primary';
const VAULT_VERSION = 2;
const SECRET_LENGTH = 32;
const ML_DSA_SEED_LENGTH = 32;
const PRF_SALT_LENGTH = 32;
const IV_LENGTH = 12;
const SNARK_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617n;

type PrfInput = AuthenticationExtensionsClientInputs & {
    prf: {
        eval?: { first: BufferSource };
        evalByCredential?: Record<string, { first: BufferSource }>;
    };
};

type PrfOutput = AuthenticationExtensionsClientOutputs & {
    prf?: {
        enabled?: boolean;
        results?: { first?: ArrayBuffer };
    };
};

type StoredVault = {
    id: typeof PRIMARY_VAULT;
    version: typeof VAULT_VERSION;
    credentialId: string;
    prfSalt: string;
    iv: string;
    ciphertext: string;
    passkeyQx: string;
    passkeyQy: string;
    postQuantumPublicKey: string;
    createdAt: string;
};

type StoredShieldedNote = {
    commitment: string;
    poolAddress: string;
    chainId: string;
    amount: string;
    iv: string;
    ciphertext: string;
    createdAt: string;
};

export type LocalVoterVaultSummary = Pick<
    StoredVault,
    'createdAt' | 'passkeyQx' | 'passkeyQy' | 'postQuantumPublicKey'
>;

export type LocalVoterRecoveryPackage = {
    format: 'raygir-voter-recovery';
    vault: StoredVault;
};

export type LocalShieldedNote = Pick<
    StoredShieldedNote,
    'commitment' | 'poolAddress' | 'chainId' | 'amount' | 'createdAt'
>;

export class LocalVoterVaultError extends Error {
    constructor(
        public readonly code:
            | 'unsupported'
            | 'prf-unsupported'
            | 'already-exists'
            | 'not-found'
            | 'cancelled'
            | 'corrupted',
    ) {
        super(code);
        this.name = 'LocalVoterVaultError';
    }
}

export async function localVoterVaultExists(): Promise<boolean> {
    return (await readVault()) !== undefined;
}

export async function createLocalVoterVault(): Promise<LocalVoterVaultSummary> {
    requireBrowserSupport();

    if (await localVoterVaultExists()) {
        throw new LocalVoterVaultError('already-exists');
    }

    const prfSalt = crypto.getRandomValues(new Uint8Array(PRF_SALT_LENGTH));
    const userId = crypto.getRandomValues(new Uint8Array(32));
    const challenge = crypto.getRandomValues(new Uint8Array(32));
    const created = await credentialCreate({
        publicKey: {
            challenge,
            rp: { name: 'Raygir local research vault' },
            user: {
                id: userId,
                name: `local-${base64Url(userId)}`,
                displayName: 'Local Raygir vault',
            },
            pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
            authenticatorSelection: {
                residentKey: 'required',
                userVerification: 'required',
            },
            attestation: 'none',
            timeout: 120_000,
            extensions: {
                prf: { eval: { first: prfSalt } },
            } as PrfInput,
        },
    });

    const credentialId = base64Url(new Uint8Array(created.rawId));
    const passkey = await extractPasskeyCoordinates(created);
    const creationOutput = created.getClientExtensionResults() as PrfOutput;

    if (creationOutput.prf?.enabled !== true) {
        throw new LocalVoterVaultError('prf-unsupported');
    }

    const prfOutput =
        creationOutput.prf.results?.first ??
        (await evaluatePrf(credentialId, toArrayBuffer(prfSalt)));
    const wrappingKey = await deriveWrappingKey(prfOutput);
    const secret = crypto.getRandomValues(
        new Uint8Array(SECRET_LENGTH + ML_DSA_SEED_LENGTH),
    );
    const postQuantumKeys = ml_dsa65.keygen(secret.slice(SECRET_LENGTH));
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));
    const ciphertext = await crypto.subtle.encrypt(
        {
            name: 'AES-GCM',
            iv,
            additionalData: vaultAdditionalData(credentialId),
        },
        wrappingKey,
        secret,
    );
    secret.fill(0);
    postQuantumKeys.secretKey.fill(0);

    const vault: StoredVault = {
        id: PRIMARY_VAULT,
        version: VAULT_VERSION,
        credentialId,
        prfSalt: base64Url(prfSalt),
        iv: base64Url(iv),
        ciphertext: base64Url(new Uint8Array(ciphertext)),
        passkeyQx: base64Url(passkey.qx),
        passkeyQy: base64Url(passkey.qy),
        postQuantumPublicKey: base64Url(postQuantumKeys.publicKey),
        createdAt: new Date().toISOString(),
    };
    await writeVault(vault);

    return vaultSummary(vault);
}

export async function unlockLocalVoterVault(): Promise<LocalVoterVaultSummary> {
    requireBrowserSupport();
    const vault = await readVault();

    if (vault === undefined) {
        throw new LocalVoterVaultError('not-found');
    }

    const prfOutput = await evaluatePrf(
        vault.credentialId,
        fromBase64Url(vault.prfSalt),
    );
    const wrappingKey = await deriveWrappingKey(prfOutput);

    try {
        const plaintext = await crypto.subtle.decrypt(
            {
                name: 'AES-GCM',
                iv: fromBase64Url(vault.iv),
                additionalData: vaultAdditionalData(vault.credentialId),
            },
            wrappingKey,
            fromBase64Url(vault.ciphertext),
        );
        const secret = new Uint8Array(plaintext);

        if (secret.length !== SECRET_LENGTH + ML_DSA_SEED_LENGTH) {
            throw new LocalVoterVaultError('corrupted');
        }

        try {
            const postQuantumKeys = ml_dsa65.keygen(
                secret.slice(SECRET_LENGTH),
            );
            const matches =
                base64Url(postQuantumKeys.publicKey) ===
                vault.postQuantumPublicKey;
            postQuantumKeys.secretKey.fill(0);

            if (!matches) {
                throw new LocalVoterVaultError('corrupted');
            }
        } finally {
            secret.fill(0);
        }
    } catch (error) {
        if (error instanceof LocalVoterVaultError) {
            throw error;
        }

        throw new LocalVoterVaultError('corrupted');
    }

    return vaultSummary(vault);
}

export async function createLocalShieldedNote(
    assetAddress: string,
    poolAddress: string,
    chainId: bigint,
    amount: bigint,
): Promise<LocalShieldedNote> {
    const vault = await readVault();

    if (vault === undefined) {
        throw new LocalVoterVaultError('not-found');
    }

    const prfOutput = await evaluatePrf(
        vault.credentialId,
        fromBase64Url(vault.prfSalt),
    );
    const wrappingKey = await deriveWrappingKey(prfOutput);
    const ownerSecret = randomFieldElement();
    const blinding = randomFieldElement();
    const noteSecret = concatenate(
        bigintBytes(ownerSecret),
        bigintBytes(blinding),
    );
    const commitment = bigintBytes(
        poseidon4([ownerSecret, BigInt(assetAddress), amount, blinding]),
    );
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));

    try {
        const ciphertext = await crypto.subtle.encrypt(
            {
                name: 'AES-GCM',
                iv,
                additionalData: toArrayBuffer(commitment),
            },
            wrappingKey,
            toArrayBuffer(noteSecret),
        );
        const note: StoredShieldedNote = {
            commitment: `0x${hex(commitment)}`,
            poolAddress: poolAddress.toLowerCase(),
            chainId: chainId.toString(),
            amount: amount.toString(),
            iv: base64Url(iv),
            ciphertext: base64Url(new Uint8Array(ciphertext)),
            createdAt: new Date().toISOString(),
        };
        await writeShieldedNote(note);

        return note;
    } finally {
        noteSecret.fill(0);
    }
}

async function extractPasskeyCoordinates(credential: PublicKeyCredential) {
    if (!(credential.response instanceof AuthenticatorAttestationResponse)) {
        throw new LocalVoterVaultError('unsupported');
    }

    const publicKey = credential.response.getPublicKey();

    if (publicKey === null) {
        throw new LocalVoterVaultError('unsupported');
    }

    const cryptoKey = await crypto.subtle.importKey(
        'spki',
        publicKey,
        { name: 'ECDSA', namedCurve: 'P-256' },
        true,
        ['verify'],
    );
    const jwk = await crypto.subtle.exportKey('jwk', cryptoKey);

    if (typeof jwk.x !== 'string' || typeof jwk.y !== 'string') {
        throw new LocalVoterVaultError('unsupported');
    }

    return {
        qx: new Uint8Array(fromBase64Url(jwk.x)),
        qy: new Uint8Array(fromBase64Url(jwk.y)),
    };
}

function vaultSummary(vault: StoredVault): LocalVoterVaultSummary {
    return {
        createdAt: vault.createdAt,
        passkeyQx: vault.passkeyQx,
        passkeyQy: vault.passkeyQy,
        postQuantumPublicKey: vault.postQuantumPublicKey,
    };
}

export async function exportLocalVoterRecovery(): Promise<string> {
    const vault = await readVault();

    if (vault === undefined) {
        throw new LocalVoterVaultError('not-found');
    }

    return JSON.stringify({
        format: 'raygir-voter-recovery',
        vault,
    } satisfies LocalVoterRecoveryPackage);
}

export async function importLocalVoterRecovery(
    serialized: string,
): Promise<void> {
    let parsed: unknown;

    try {
        parsed = JSON.parse(serialized);
    } catch {
        throw new LocalVoterVaultError('corrupted');
    }

    if (!isRecoveryPackage(parsed)) {
        throw new LocalVoterVaultError('corrupted');
    }

    await writeVault(parsed.vault);
}

function requireBrowserSupport(): void {
    if (
        !window.isSecureContext ||
        !('PublicKeyCredential' in window) ||
        !navigator.credentials ||
        !crypto.subtle ||
        !window.indexedDB
    ) {
        throw new LocalVoterVaultError('unsupported');
    }
}

async function evaluatePrf(
    credentialId: string,
    prfSalt: ArrayBuffer,
): Promise<ArrayBuffer> {
    const assertion = await credentialGet({
        publicKey: {
            challenge: crypto.getRandomValues(new Uint8Array(32)),
            allowCredentials: [
                { id: fromBase64Url(credentialId), type: 'public-key' },
            ],
            userVerification: 'required',
            timeout: 120_000,
            extensions: {
                prf: {
                    evalByCredential: {
                        [credentialId]: { first: prfSalt },
                    },
                },
            } as PrfInput,
        },
    });
    const output = assertion.getClientExtensionResults() as PrfOutput;
    const first = output.prf?.results?.first;

    if (first === undefined) {
        throw new LocalVoterVaultError('prf-unsupported');
    }

    return first;
}

async function deriveWrappingKey(prfOutput: ArrayBuffer): Promise<CryptoKey> {
    try {
        const material = await crypto.subtle.importKey(
            'raw',
            prfOutput,
            'HKDF',
            false,
            ['deriveKey'],
        );

        return await crypto.subtle.deriveKey(
            {
                name: 'HKDF',
                hash: 'SHA-256',
                salt: new TextEncoder().encode('raygir-voter-vault-hkdf-v1'),
                info: new TextEncoder().encode('aes-gcm-wrapping-key'),
            },
            material,
            { name: 'AES-GCM', length: 256 },
            false,
            ['encrypt', 'decrypt'],
        );
    } finally {
        new Uint8Array(prfOutput).fill(0);
    }
}

function vaultAdditionalData(credentialId: string): ArrayBuffer {
    return toArrayBuffer(
        new TextEncoder().encode(
            `raygir-voter-vault-v${VAULT_VERSION}:${credentialId}`,
        ),
    );
}

async function credentialCreate(
    options: CredentialCreationOptions,
): Promise<PublicKeyCredential> {
    try {
        const credential = await navigator.credentials.create(options);

        if (!(credential instanceof PublicKeyCredential)) {
            throw new LocalVoterVaultError('unsupported');
        }

        return credential;
    } catch (error) {
        if (error instanceof LocalVoterVaultError) {
            throw error;
        }

        if (error instanceof DOMException && error.name === 'NotAllowedError') {
            throw new LocalVoterVaultError('cancelled');
        }

        throw error;
    }
}

async function credentialGet(
    options: CredentialRequestOptions,
): Promise<PublicKeyCredential> {
    try {
        const credential = await navigator.credentials.get(options);

        if (!(credential instanceof PublicKeyCredential)) {
            throw new LocalVoterVaultError('unsupported');
        }

        return credential;
    } catch (error) {
        if (error instanceof LocalVoterVaultError) {
            throw error;
        }

        if (error instanceof DOMException && error.name === 'NotAllowedError') {
            throw new LocalVoterVaultError('cancelled');
        }

        throw error;
    }
}

function readVault(): Promise<StoredVault | undefined> {
    return new Promise((resolve, reject) => {
        const request = openDatabase();
        request.onerror = () => reject(request.error);
        request.onsuccess = () => {
            const database = request.result;
            const getRequest = database
                .transaction(STORE_NAME, 'readonly')
                .objectStore(STORE_NAME)
                .get(PRIMARY_VAULT);
            getRequest.onerror = () => reject(getRequest.error);
            getRequest.onsuccess = () => {
                const result: unknown = getRequest.result;

                if (result === undefined || isStoredVault(result)) {
                    resolve(result);

                    return;
                }

                reject(new LocalVoterVaultError('corrupted'));
            };
        };
    });
}

function writeVault(vault: StoredVault): Promise<void> {
    return new Promise((resolve, reject) => {
        const request = openDatabase();
        request.onerror = () => reject(request.error);
        request.onsuccess = () => {
            const database = request.result;
            const transaction = database.transaction(STORE_NAME, 'readwrite');
            transaction.objectStore(STORE_NAME).put(vault);
            transaction.oncomplete = () => resolve();
            transaction.onerror = () => reject(transaction.error);
        };
    });
}

function openDatabase(): IDBOpenDBRequest {
    const request = indexedDB.open(DATABASE_NAME, DATABASE_VERSION);
    request.onupgradeneeded = () => {
        if (!request.result.objectStoreNames.contains(STORE_NAME)) {
            request.result.createObjectStore(STORE_NAME, { keyPath: 'id' });
        }

        if (!request.result.objectStoreNames.contains(NOTE_STORE_NAME)) {
            request.result.createObjectStore(NOTE_STORE_NAME, {
                keyPath: 'commitment',
            });
        }
    };

    return request;
}

function writeShieldedNote(note: StoredShieldedNote): Promise<void> {
    return new Promise((resolve, reject) => {
        const request = openDatabase();
        request.onerror = () => reject(request.error);
        request.onsuccess = () => {
            const database = request.result;
            const transaction = database.transaction(
                NOTE_STORE_NAME,
                'readwrite',
            );
            transaction.objectStore(NOTE_STORE_NAME).add(note);
            transaction.oncomplete = () => resolve();
            transaction.onerror = () => reject(transaction.error);
        };
    });
}

function concatenate(...arrays: Uint8Array[]): Uint8Array {
    const length = arrays.reduce((total, value) => total + value.length, 0);
    const output = new Uint8Array(length);
    let offset = 0;

    for (const value of arrays) {
        output.set(value, offset);
        offset += value.length;
    }

    return output;
}

function randomFieldElement(): bigint {
    return (
        BigInt(`0x${hex(crypto.getRandomValues(new Uint8Array(32)))}`) %
        SNARK_FIELD
    );
}

function bigintBytes(value: bigint): Uint8Array {
    const encoded = value.toString(16).padStart(64, '0');

    return Uint8Array.from(encoded.match(/.{2}/gu) ?? [], (byte) =>
        Number.parseInt(byte, 16),
    );
}

function hex(bytes: Uint8Array): string {
    return Array.from(bytes, (value) =>
        value.toString(16).padStart(2, '0'),
    ).join('');
}

function base64Url(bytes: Uint8Array): string {
    let binary = '';

    for (const byte of bytes) {
        binary += String.fromCharCode(byte);
    }

    return btoa(binary)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replace(/=+$/u, '');
}

function fromBase64Url(value: string): ArrayBuffer {
    const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
    const binary = atob(padded);

    return toArrayBuffer(
        Uint8Array.from(binary, (character) => character.charCodeAt(0)),
    );
}

function toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
    const buffer = new ArrayBuffer(bytes.byteLength);
    new Uint8Array(buffer).set(bytes);

    return buffer;
}

function isStoredVault(value: unknown): value is StoredVault {
    if (typeof value !== 'object' || value === null) {
        return false;
    }

    const vault = value as Partial<StoredVault>;

    return (
        vault.id === PRIMARY_VAULT &&
        vault.version === VAULT_VERSION &&
        typeof vault.credentialId === 'string' &&
        typeof vault.prfSalt === 'string' &&
        typeof vault.iv === 'string' &&
        typeof vault.ciphertext === 'string' &&
        typeof vault.passkeyQx === 'string' &&
        typeof vault.passkeyQy === 'string' &&
        typeof vault.postQuantumPublicKey === 'string' &&
        typeof vault.createdAt === 'string'
    );
}

function isRecoveryPackage(value: unknown): value is LocalVoterRecoveryPackage {
    if (typeof value !== 'object' || value === null) {
        return false;
    }

    const recovery = value as Partial<LocalVoterRecoveryPackage>;

    return (
        recovery.format === 'raygir-voter-recovery' &&
        isStoredVault(recovery.vault)
    );
}
