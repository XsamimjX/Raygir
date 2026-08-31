<?php

use App\Contracts\ClobBatchProver;
use App\Contracts\ClobSettlementGateway;
use App\Jobs\ProveAndSubmitClobSettlement;
use App\Models\ClobSettlementBatch;
use App\Models\ClobTrade;
use App\Services\Clob\ClobMatcher;
use App\Services\Clob\ClobSettlementCoordinator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

function pipelineEnvelope(string $name, string $side, string $maker): array
{
    return [
        'order_hash' => hash('sha256', $name),
        'market_id' => str_pad('9', 64, '0', STR_PAD_LEFT),
        'token_id' => '2',
        'side' => $side,
        'maker' => $maker,
        'amount' => '10',
        'price' => '20',
        'nonce' => (string) hexdec(substr(hash('sha256', $name), 0, 8)),
        'expiry' => now()->addHour()->timestamp,
        'public_key_x' => hash('sha256', 'x-'.$name),
        'public_key_y' => hash('sha256', 'y-'.$name),
        'signature' => hash('sha256', 'r-'.$name).hash('sha256', 's-'.$name),
    ];
}

function pipelineStateTransition(): array
{
    $balance = [
        'balance' => '1000',
        'blinding' => str_pad('1', 64, '0', STR_PAD_LEFT),
        'new_blinding' => str_pad('2', 64, '0', STR_PAD_LEFT),
        'index' => 0,
        'siblings' => array_merge([
            str_pad('3', 64, '0', STR_PAD_LEFT),
            str_pad('4', 64, '0', STR_PAD_LEFT),
        ], array_fill(0, 14, str_repeat('0', 64))),
    ];

    return [
        'buyer_quote' => $balance,
        'seller_outcome' => [...$balance, 'index' => 3],
        'buyer_outcome' => [...$balance, 'index' => 1],
        'seller_quote' => [...$balance, 'index' => 2],
    ];
}

test('settlement proving survives queues without retaining private witnesses', function () {
    Queue::fake();
    $matcher = app(ClobMatcher::class);
    $matcher->submit(pipelineEnvelope('pipeline-sell', 'sell', '0x'.str_repeat('1', 40)));
    $matcher->submit(pipelineEnvelope('pipeline-buy', 'buy', '0x'.str_repeat('2', 40)));

    $gateway = Mockery::mock(ClobSettlementGateway::class);
    $coordinator = new ClobSettlementCoordinator($matcher, $gateway);
    $batch = $coordinator->queue(str_pad('1', 64, '0', STR_PAD_LEFT), 7, now()->timestamp, [pipelineStateTransition()]);

    expect($batch)->toBeInstanceOf(ClobSettlementBatch::class)
        ->and(DB::table('clob_settlement_batches')->value('encrypted_witness'))->not->toContain('buyer_quote');
    Queue::assertPushed(ProveAndSubmitClobSettlement::class);

    $prover = Mockery::mock(ClobBatchProver::class);
    $publicInputs = ['1', '7', '0', (string) $batch->settlement_time, '1', '123', '2'];
    $prover->shouldReceive('prove')->once()->andReturn([
        'proof' => 'proof-bytes',
        'public_inputs' => $publicInputs,
        'next_root' => str_pad('2', 64, '0', STR_PAD_LEFT),
    ]);
    $gateway->shouldReceive('submit')
        ->once()
        ->with($batch->batch_id, 'proof-bytes', $publicInputs)
        ->andReturn(str_repeat('c', 64));

    (new ProveAndSubmitClobSettlement($batch->getKey()))->handle($prover, $gateway);
    $batch->refresh();

    expect($batch->status)->toBe(ClobSettlementBatch::Submitted)
        ->and($batch->encrypted_witness)->toBeNull()
        ->and($batch->witness_erased_at)->not->toBeNull()
        ->and($batch->transaction_hash)->toBe(str_repeat('c', 64));
});

test('canonical confirmation and reorg recovery preserve settlement state', function () {
    Queue::fake();
    $matcher = app(ClobMatcher::class);
    $matcher->submit(pipelineEnvelope('reorg-sell', 'sell', '0x'.str_repeat('3', 40)));
    $matcher->submit(pipelineEnvelope('reorg-buy', 'buy', '0x'.str_repeat('4', 40)));
    $trade = ClobTrade::query()->sole();
    $prepared = $matcher->prepareSettlementBatch();
    $batch = ClobSettlementBatch::query()->create([
        'batch_id' => $prepared['batch_id'],
        'previous_root' => str_pad('1', 64, '0', STR_PAD_LEFT),
        'next_root' => str_pad('2', 64, '0', STR_PAD_LEFT),
        'sequence' => 8,
        'match_count' => 1,
        'settlement_time' => now()->timestamp,
        'proof' => 'proof-bytes',
        'public_inputs' => ['8', '1'],
        'transaction_hash' => str_repeat('d', 64),
        'status' => ClobSettlementBatch::Submitted,
    ]);

    $gateway = Mockery::mock(ClobSettlementGateway::class);
    $gateway->shouldReceive('transactionStatus')->once()->andReturn(['status' => 'reorged']);
    $coordinator = new ClobSettlementCoordinator($matcher, $gateway);
    expect($coordinator->reconcile($batch)->status)->toBe(ClobSettlementBatch::Proven)
        ->and($trade->refresh()->settlement_status)->toBe('submitted');
    Queue::assertPushed(ProveAndSubmitClobSettlement::class);

    $batch->update(['status' => ClobSettlementBatch::Submitted, 'transaction_hash' => str_repeat('e', 64)]);
    $gateway->shouldReceive('transactionStatus')->once()->andReturn([
        'status' => 'confirmed',
        'block_number' => 42,
        'block_hash' => str_repeat('f', 64),
    ]);

    expect($coordinator->reconcile($batch)->status)->toBe(ClobSettlementBatch::Confirmed)
        ->and($trade->refresh()->settlement_status)->toBe('confirmed')
        ->and($batch->refresh()->confirmed_block_number)->toBe(42);
});

test('prover output cannot replace the queued public settlement inputs', function () {
    $batch = ClobSettlementBatch::factory()->create([
        'previous_root' => str_pad('1', 64, '0', STR_PAD_LEFT),
        'sequence' => 9,
        'match_count' => 1,
        'settlement_time' => 1234,
    ]);
    $prover = Mockery::mock(ClobBatchProver::class);
    $prover->shouldReceive('prove')->once()->andReturn([
        'proof' => 'proof-bytes',
        'public_inputs' => ['1', '10', '0', '1234', '1', '123', '2'],
        'next_root' => str_pad('2', 64, '0', STR_PAD_LEFT),
    ]);
    $gateway = Mockery::mock(ClobSettlementGateway::class);
    $gateway->shouldNotReceive('submit');

    expect(fn () => (new ProveAndSubmitClobSettlement($batch->getKey()))->handle($prover, $gateway))
        ->toThrow(RuntimeException::class, 'does not bind');
    expect($batch->refresh()->encrypted_witness)->not->toBeNull()
        ->and($batch->status)->toBe(ClobSettlementBatch::Proving);
});
