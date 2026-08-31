<?php

namespace App\Services\Clob;

use App\Contracts\ClobSettlementGateway;
use App\Jobs\ProveAndSubmitClobSettlement;
use App\Models\ClobSettlementBatch;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ClobSettlementCoordinator
{
    public function __construct(
        private readonly ClobMatcher $matcher,
        private readonly ClobSettlementGateway $gateway,
    ) {}

    /** @param array<int, array<string, mixed>> $stateTransitions */
    public function queue(
        string $previousRoot,
        int $sequence,
        int $settlementTime,
        array $stateTransitions,
    ): ?ClobSettlementBatch {
        return DB::transaction(function () use ($previousRoot, $sequence, $settlementTime, $stateTransitions): ?ClobSettlementBatch {
            $prepared = $this->matcher->prepareSettlementBatch();
            if ($prepared === null) {
                return null;
            }
            $witness = $this->matcher->proofPayload(
                $prepared['batch_id'],
                $previousRoot,
                $sequence,
                $settlementTime,
                $stateTransitions,
            );
            $batch = ClobSettlementBatch::query()->create([
                'batch_id' => $prepared['batch_id'],
                'previous_root' => $previousRoot,
                'sequence' => $sequence,
                'match_count' => count($prepared['matches']),
                'settlement_time' => $settlementTime,
                'encrypted_witness' => $witness,
                'status' => ClobSettlementBatch::Queued,
            ]);
            ProveAndSubmitClobSettlement::dispatch($batch->getKey())->afterCommit();

            return $batch;
        }, attempts: 3);
    }

    public function reconcile(ClobSettlementBatch $batch): ClobSettlementBatch
    {
        if ($batch->status !== ClobSettlementBatch::Submitted || ! is_string($batch->transaction_hash)) {
            throw new InvalidArgumentException('Only submitted settlement batches can be reconciled.');
        }

        $receipt = $this->gateway->transactionStatus($batch->transaction_hash);
        if ($receipt['status'] === 'confirmed') {
            return DB::transaction(function () use ($batch, $receipt): ClobSettlementBatch {
                $locked = ClobSettlementBatch::query()->lockForUpdate()->findOrFail($batch->getKey());
                if ($locked->status === ClobSettlementBatch::Confirmed) {
                    return $locked;
                }
                $this->matcher->confirmSettlementBatch($locked->batch_id);
                $locked->update([
                    'status' => ClobSettlementBatch::Confirmed,
                    'confirmed_block_number' => $receipt['block_number'],
                    'confirmed_block_hash' => $receipt['block_hash'],
                ]);

                return $locked->refresh();
            }, attempts: 3);
        }

        if (in_array($receipt['status'], ['reorged', 'failed'], true)) {
            $batch->update([
                'status' => ClobSettlementBatch::Proven,
                'transaction_hash' => null,
                'confirmed_block_number' => null,
                'confirmed_block_hash' => null,
                'last_error' => $receipt['error'] ?? $receipt['status'],
            ]);
            ProveAndSubmitClobSettlement::dispatch($batch->getKey());
        }

        return $batch->refresh();
    }
}
