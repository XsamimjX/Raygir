<?php

namespace App\Jobs;

use App\Contracts\ClobBatchProver;
use App\Contracts\ClobSettlementGateway;
use App\Models\ClobSettlementBatch;
use Brick\Math\BigInteger;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use RuntimeException;

class ProveAndSubmitClobSettlement implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    /** @var array<int, int> */
    public array $backoff = [5, 30, 120, 300];

    public function __construct(public int $settlementBatchId)
    {
        $this->onQueue('proving');
    }

    public function handle(ClobBatchProver $prover, ClobSettlementGateway $gateway): void
    {
        $batch = ClobSettlementBatch::query()->findOrFail($this->settlementBatchId);
        if ($batch->status === ClobSettlementBatch::Confirmed || $batch->status === ClobSettlementBatch::Submitted) {
            return;
        }

        if ($batch->proof === null) {
            $claimed = ClobSettlementBatch::query()
                ->whereKey($batch->getKey())
                ->whereIn('status', [ClobSettlementBatch::Queued, ClobSettlementBatch::Proving])
                ->update(['status' => ClobSettlementBatch::Proving, 'last_error' => null]);
            if ($claimed !== 1) {
                throw new RuntimeException('Settlement batch could not be claimed for proving.');
            }

            $batch->refresh();
            if (! is_array($batch->encrypted_witness)) {
                throw new RuntimeException('Settlement witness has already been erased.');
            }
            $result = $prover->prove($batch->encrypted_witness);
            $this->validateProofResult($batch, $result);
            $batch->forceFill([
                'next_root' => $result['next_root'],
                'proof' => $result['proof'],
                'public_inputs' => $result['public_inputs'],
                'encrypted_witness' => null,
                'witness_erased_at' => now(),
                'status' => ClobSettlementBatch::Proven,
            ])->save();
        }

        $batch->refresh();
        if (! is_string($batch->proof) || ! is_array($batch->public_inputs)) {
            throw new RuntimeException('Settlement proof output is incomplete.');
        }
        $transactionHash = $gateway->submit($batch->batch_id, $batch->proof, $batch->public_inputs);
        $batch->forceFill([
            'transaction_hash' => $transactionHash,
            'status' => ClobSettlementBatch::Submitted,
            'last_error' => null,
        ])->save();
    }

    public function failed(?\Throwable $exception): void
    {
        ClobSettlementBatch::query()->whereKey($this->settlementBatchId)->update([
            'last_error' => mb_substr($exception?->getMessage() ?? 'Unknown proving failure.', 0, 2000),
        ]);
    }

    /** @param array{proof: string, public_inputs: array<int, string>, next_root: string} $result */
    private function validateProofResult(ClobSettlementBatch $batch, array $result): void
    {
        $inputs = $result['public_inputs'];
        $expected = [
            BigInteger::fromBase($batch->previous_root, 16)->toBase(10),
            (string) $batch->sequence,
            '0',
            (string) $batch->settlement_time,
            (string) $batch->match_count,
        ];
        if ($result['proof'] === ''
            || count($inputs) !== 7
            || array_slice($inputs, 0, 5) !== $expected
            || $inputs[6] !== BigInteger::fromBase($result['next_root'], 16)->toBase(10)) {
            throw new RuntimeException('Settlement proof does not bind the queued public inputs.');
        }
    }
}
