<?php

namespace App\Contracts;

interface ClobSettlementGateway
{
    /** @param array<int, string> $publicInputs */
    public function submit(string $batchId, string $proof, array $publicInputs): string;

    /** @return array{status: 'pending'|'confirmed'|'reorged'|'failed', block_number?: int, block_hash?: string, error?: string} */
    public function transactionStatus(string $transactionHash): array;
}
