<?php

namespace App\Services\Clob;

use App\Contracts\ClobSettlementGateway;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class HttpClobSettlementGateway implements ClobSettlementGateway
{
    public function submit(string $batchId, string $proof, array $publicInputs): string
    {
        $response = $this->client()->post('/api/v1/clob/settlements', [
            'idempotency_key' => $batchId,
            'proof' => $proof,
            'public_inputs' => $publicInputs,
        ])->throw()->json();
        $transactionHash = $response['transaction_hash'] ?? null;
        if (! is_string($transactionHash) || preg_match('/\A[0-9a-f]{64}\z/', $transactionHash) !== 1) {
            throw new RuntimeException('Settlement gateway returned an invalid transaction hash.');
        }

        return $transactionHash;
    }

    public function transactionStatus(string $transactionHash): array
    {
        $response = $this->client()->get("/api/v1/clob/settlements/{$transactionHash}")->throw()->json();
        $status = $response['status'] ?? null;
        if (! in_array($status, ['pending', 'confirmed', 'reorged', 'failed'], true)) {
            throw new RuntimeException('Settlement gateway returned an invalid status.');
        }
        if ($status === 'confirmed'
            && (! is_int($response['block_number'] ?? null)
                || ! is_string($response['block_hash'] ?? null)
                || preg_match('/\A[0-9a-f]{64}\z/', $response['block_hash']) !== 1)) {
            throw new RuntimeException('Confirmed settlement is missing its canonical block reference.');
        }

        return $response;
    }

    private function client(): PendingRequest
    {
        $endpoint = config('services.clob.gateway_endpoint');
        if (! is_string($endpoint) || $endpoint === '') {
            throw new RuntimeException('CLOB_GATEWAY_ENDPOINT is not configured.');
        }

        return Http::baseUrl($endpoint)
            ->withToken((string) config('services.clob.gateway_token'))
            ->acceptJson()
            ->asJson()
            ->timeout(15)
            ->retry(2, 200, throw: false);
    }
}
