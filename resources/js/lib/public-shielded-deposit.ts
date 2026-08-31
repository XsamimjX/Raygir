import { createLocalShieldedNote } from '@/lib/local-voter-vault';

const APPROVE_SELECTOR = '095ea7b3';
const DEPOSIT_SELECTOR = '73b8979f';
const UINT128_MAX = (1n << 128n) - 1n;

type EthereumProvider = {
    request(args: { method: string; params?: unknown[] }): Promise<unknown>;
};

export type PublicDepositResult = {
    approvalTransaction: string;
    depositTransaction: string;
    commitment: string;
};

export async function submitPublicShieldedDeposit(
    tokenAddress: string,
    poolAddress: string,
    amount: bigint,
): Promise<PublicDepositResult> {
    const provider = (window as Window & { ethereum?: EthereumProvider })
        .ethereum;

    if (provider === undefined) {
        throw new Error('wallet-unavailable');
    }

    if (!isAddress(tokenAddress) || !isAddress(poolAddress)) {
        throw new Error('deposit-unconfigured');
    }

    if (amount <= 0n || amount > UINT128_MAX) {
        throw new Error('invalid-amount');
    }

    const accounts = await provider.request({ method: 'eth_requestAccounts' });

    if (!Array.isArray(accounts) || typeof accounts[0] !== 'string') {
        throw new Error('wallet-unavailable');
    }

    const chainIdValue = await provider.request({ method: 'eth_chainId' });

    if (typeof chainIdValue !== 'string') {
        throw new Error('wallet-unavailable');
    }

    const chainId = BigInt(chainIdValue);
    const sender = accounts[0];
    const approvalTransaction = await sendTransaction(provider, {
        from: sender,
        to: tokenAddress,
        data: `0x${APPROVE_SELECTOR}${word(poolAddress)}${word(amount)}`,
    });
    const note = await createLocalShieldedNote(
        tokenAddress,
        poolAddress,
        chainId,
        amount,
    );
    const depositTransaction = await sendTransaction(provider, {
        from: sender,
        to: poolAddress,
        data: encodeDeposit(note.commitment, amount),
    });

    return {
        approvalTransaction,
        depositTransaction,
        commitment: note.commitment,
    };
}

function encodeDeposit(commitment: string, amount: bigint): string {
    return `0x${DEPOSIT_SELECTOR}${word(64n)}${word(128n)}${word(1n)}${word(commitment)}${word(1n)}${word(amount)}`;
}

async function sendTransaction(
    provider: EthereumProvider,
    transaction: Record<string, string>,
): Promise<string> {
    const result = await provider.request({
        method: 'eth_sendTransaction',
        params: [transaction],
    });

    if (typeof result !== 'string') {
        throw new Error('transaction-failed');
    }

    return result;
}

function word(value: bigint | string): string {
    const hex =
        typeof value === 'bigint'
            ? value.toString(16)
            : value.toLowerCase().replace(/^0x/u, '');

    return hex.padStart(64, '0');
}

function isAddress(value: string): boolean {
    return /^0x[a-fA-F0-9]{40}$/u.test(value);
}
