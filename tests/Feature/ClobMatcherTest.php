<?php

use App\Models\ClobOrder;
use App\Models\ClobTrade;
use App\Services\Clob\ClobMatcher;
use Illuminate\Support\Facades\DB;

function clobEnvelope(
    string $name,
    string $side,
    string $price,
    string $amount,
    string $maker,
): array {
    return [
        'order_hash' => hash('sha256', $name),
        'market_id' => str_pad('9', 64, '0', STR_PAD_LEFT),
        'token_id' => '2',
        'side' => $side,
        'maker' => $maker,
        'amount' => $amount,
        'price' => $price,
        'nonce' => (string) hexdec(substr(hash('sha256', $name), 0, 8)),
        'expiry' => now()->addHour()->timestamp,
        'public_key_x' => hash('sha256', 'x-'.$name),
        'public_key_y' => hash('sha256', 'y-'.$name),
        'signature' => hash('sha256', 'r-'.$name).hash('sha256', 's-'.$name),
    ];
}

function clobStateTransition(): array
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

test('matcher uses price time priority across partial fills', function () {
    $matcher = app(ClobMatcher::class);
    $sellerOne = '0x'.str_repeat('1', 40);
    $sellerTwo = '0x'.str_repeat('2', 40);
    $sellerThree = '0x'.str_repeat('3', 40);
    $buyer = '0x'.str_repeat('4', 40);

    $matcher->submit(clobEnvelope('sell-first', 'sell', '50', '4', $sellerOne));
    $matcher->submit(clobEnvelope('sell-second', 'sell', '50', '3', $sellerTwo));
    $matcher->submit(clobEnvelope('sell-expensive', 'sell', '60', '10', $sellerThree));
    $result = $matcher->submit(clobEnvelope('buy', 'buy', '60', '8', $buyer));

    expect($result['trades'])->toHaveCount(3)
        ->and(collect($result['trades'])->pluck('amount')->all())->toBe(['4', '3', '1'])
        ->and(collect($result['trades'])->pluck('price')->all())->toBe(['50', '50', '60'])
        ->and($result['order']->status)->toBe(ClobOrder::Filled);

    $book = $matcher->book(str_pad('9', 64, '0', STR_PAD_LEFT), '2');
    expect($book['sell'])->toBe([['price' => '60', 'amount' => '9']])
        ->and($book['buy'])->toBe([]);
});

test('encrypted order envelope is opaque in PostgreSQL but rebuilds the same book', function () {
    $matcher = app(ClobMatcher::class);
    $envelope = clobEnvelope(
        'private-sell',
        'sell',
        '75',
        '12',
        '0x'.str_repeat('a', 40),
    );
    $matcher->submit($envelope);

    $stored = DB::table((new ClobOrder)->getTable())->value('encrypted_envelope');
    expect($stored)->not->toContain($envelope['maker'])
        ->not->toContain($envelope['signature']);

    $restartedMatcher = new ClobMatcher;
    expect($restartedMatcher->book($envelope['market_id'], '2'))->toBe([
        'buy' => [],
        'sell' => [['price' => '75', 'amount' => '12']],
    ]);
});

test('cancelled orders cannot match and only their maker can cancel them', function () {
    $matcher = app(ClobMatcher::class);
    $seller = '0x'.str_repeat('1', 40);
    $sell = clobEnvelope('cancelled-sell', 'sell', '50', '4', $seller);
    $matcher->submit($sell);

    expect(fn () => $matcher->cancel($sell['order_hash'], '0x'.str_repeat('9', 40)))
        ->toThrow(RuntimeException::class, 'cannot be cancelled');
    expect($matcher->cancel($sell['order_hash'], $seller)->status)->toBe(ClobOrder::Cancelled);

    $result = $matcher->submit(clobEnvelope(
        'buy-after-cancel',
        'buy',
        '50',
        '4',
        '0x'.str_repeat('2', 40),
    ));
    expect($result['trades'])->toBe([])
        ->and(ClobTrade::query()->count())->toBe(0);
});

test('duplicate hashes and malformed envelopes are rejected', function () {
    $matcher = app(ClobMatcher::class);
    $order = clobEnvelope('duplicate', 'buy', '50', '4', '0x'.str_repeat('1', 40));
    $matcher->submit($order);

    expect(fn () => $matcher->submit($order))->toThrow(RuntimeException::class, 'already')
        ->and(fn () => $matcher->submit([...$order, 'order_hash' => 'bad']))
        ->toThrow(InvalidArgumentException::class, 'order_hash');

});

test('settlement batches are deterministic replay safe and recoverable after matcher restart', function () {
    $matcher = app(ClobMatcher::class);
    $matcher->submit(clobEnvelope(
        'batch-sell',
        'sell',
        '50',
        '4',
        '0x'.str_repeat('1', 40),
    ));
    $matcher->submit(clobEnvelope(
        'batch-buy',
        'buy',
        '50',
        '4',
        '0x'.str_repeat('2', 40),
    ));

    $batch = $matcher->prepareSettlementBatch();
    expect($batch)->not->toBeNull()
        ->and($batch['matches'])->toHaveCount(1)
        ->and($batch['matches'][0]['buy']['signature'])->toHaveLength(128)
        ->and($matcher->prepareSettlementBatch())->toBeNull();
    $singlePayload = $matcher->proofPayload(
        $batch['batch_id'],
        str_pad('1', 64, '0', STR_PAD_LEFT),
        7,
        900,
        [clobStateTransition()],
    );
    expect($singlePayload['match_count'])->toBe('1')
        ->and($singlePayload['buys'])->toHaveCount(2)
        ->and($singlePayload['executions'][1])->toBe([
            'fill_amount' => '0',
            'execution_price' => '0',
        ]);

    $restartedMatcher = new ClobMatcher;
    expect($restartedMatcher->settlementBatch($batch['root']))->toBe($batch);

    expect($restartedMatcher->releaseSettlementBatch($batch['root']))->toBe(1);
    $retried = $restartedMatcher->prepareSettlementBatch();
    expect($retried['root'])->toBe($batch['root'])
        ->and($restartedMatcher->confirmSettlementBatch($retried['root']))->toBe(1)
        ->and(ClobTrade::query()->sole()->settlement_status)->toBe('confirmed');

    expect(fn () => $restartedMatcher->confirmSettlementBatch($retried['root']))
        ->toThrow(RuntimeException::class, 'not awaiting');
});

test('settlement proof payload matches the two match Noir ABI', function () {
    $matcher = app(ClobMatcher::class);
    foreach ([
        clobEnvelope('proof-sell-one', 'sell', '20', '10', '0x'.str_repeat('1', 40)),
        clobEnvelope('proof-buy-one', 'buy', '20', '10', '0x'.str_repeat('2', 40)),
        clobEnvelope('proof-sell-two', 'sell', '24', '5', '0x'.str_repeat('3', 40)),
        clobEnvelope('proof-buy-two', 'buy', '25', '5', '0x'.str_repeat('4', 40)),
    ] as $order) {
        $matcher->submit($order);
    }

    $batch = $matcher->prepareSettlementBatch();
    expect(fn () => $matcher->proofPayload(
        $batch['batch_id'],
        str_pad('1', 64, '0', STR_PAD_LEFT),
        7,
        900,
        [],
    ))->toThrow(InvalidArgumentException::class, 'Every match');
    $payload = $matcher->proofPayload(
        $batch['batch_id'],
        str_pad('1', 64, '0', STR_PAD_LEFT),
        7,
        900,
        [clobStateTransition(), clobStateTransition()],
    );

    expect($payload['match_count'])->toBe('2')
        ->and($payload['buys'])->toHaveCount(2)
        ->and($payload['sells'])->toHaveCount(2)
        ->and($payload['executions'])->toBe([
            ['fill_amount' => '10', 'execution_price' => '20'],
            ['fill_amount' => '5', 'execution_price' => '24'],
        ])
        ->and($payload['state_transitions'])->toHaveCount(2)
        ->and($payload['settlement'])->toBe([
            'previous_root' => '1',
            'sequence' => '7',
            'public_fee' => '0',
            'settlement_time' => '900',
        ])
        ->and($payload['buys'][0]['public_key_x'])->toHaveCount(32)
        ->and($payload['buys'][0]['signature'])->toHaveCount(64);
});

test('a proof batch never repeats an order', function () {
    $matcher = app(ClobMatcher::class);
    foreach ([
        clobEnvelope('unique-sell-one', 'sell', '20', '2', '0x'.str_repeat('1', 40)),
        clobEnvelope('unique-sell-two', 'sell', '20', '2', '0x'.str_repeat('2', 40)),
        clobEnvelope('shared-buy', 'buy', '20', '4', '0x'.str_repeat('3', 40)),
    ] as $order) {
        $matcher->submit($order);
    }

    $batch = $matcher->prepareSettlementBatch();
    expect($batch['matches'])->toHaveCount(1)
        ->and($batch['matches'][0]['buy']['order_hash'])->toBe(hash('sha256', 'shared-buy'));
});
