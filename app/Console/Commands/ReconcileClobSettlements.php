<?php

namespace App\Console\Commands;

use App\Models\ClobSettlementBatch;
use App\Services\Clob\ClobSettlementCoordinator;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Throwable;

#[Signature('clob:settlements:reconcile {--limit=100}')]
#[Description('Confirm canonical CLOB settlements and resubmit failed or reorged transactions')]
class ReconcileClobSettlements extends Command
{
    public function handle(ClobSettlementCoordinator $coordinator): int
    {
        $limit = filter_var($this->option('limit'), FILTER_VALIDATE_INT, [
            'options' => ['min_range' => 1, 'max_range' => 1000],
        ]);
        if ($limit === false) {
            $this->error('The limit must be an integer between 1 and 1000.');

            return self::INVALID;
        }

        $failed = 0;
        ClobSettlementBatch::query()
            ->where('status', ClobSettlementBatch::Submitted)
            ->orderBy('id')
            ->limit($limit)
            ->get()
            ->each(function (ClobSettlementBatch $batch) use ($coordinator, &$failed): void {
                try {
                    $coordinator->reconcile($batch);
                } catch (Throwable $exception) {
                    $failed++;
                    $batch->update(['last_error' => mb_substr($exception->getMessage(), 0, 2000)]);
                    $this->warn("{$batch->batch_id}: {$exception->getMessage()}");
                }
            });

        return $failed === 0 ? self::SUCCESS : self::FAILURE;
    }
}
