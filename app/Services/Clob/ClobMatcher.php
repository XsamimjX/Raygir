<?php

namespace App\Services\Clob;

use App\Models\ClobOrder;
use App\Models\ClobTrade;
use Brick\Math\BigInteger;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

class ClobMatcher
{
    /**
     * @param  array{order_hash: string, market_id: string, token_id: string, side: string, maker: string, amount: string, price: string, nonce: string, expiry: int, public_key_x: string, public_key_y: string, signature: string}  $envelope
     * @return array{order: ClobOrder, trades: array<int, ClobTrade>}
     */
    public function submit(array $envelope): array
    {
        $this->validateEnvelope($envelope);

        return DB::transaction(function () use ($envelope): array {
            if (ClobOrder::query()->where('order_hash', $envelope['order_hash'])->exists()) {
                throw new RuntimeException('Order hash has already been submitted.');
            }

            $incoming = ClobOrder::query()->create([
                'order_hash' => $envelope['order_hash'],
                'market_id' => $envelope['market_id'],
                'token_id' => $envelope['token_id'],
                'side' => $envelope['side'],
                'encrypted_envelope' => [...$envelope, 'filled_amount' => '0'],
                'expires_at' => date(DATE_ATOM, $envelope['expiry']),
            ]);

            $candidates = ClobOrder::query()
                ->where('market_id', $incoming->market_id)
                ->where('token_id', $incoming->token_id)
                ->where('side', $incoming->side === 'buy' ? 'sell' : 'buy')
                ->where('status', ClobOrder::Open)
                ->where('expires_at', '>', now())
                ->whereKeyNot($incoming->getKey())
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            $trades = [];
            foreach ($this->priceTimeSorted($candidates, $incoming->side) as $resting) {
                $incomingEnvelope = $incoming->encrypted_envelope;
                $restingEnvelope = $resting->encrypted_envelope;
                if ($incomingEnvelope['maker'] === $restingEnvelope['maker']
                    || ! $this->crosses($incomingEnvelope, $restingEnvelope)) {
                    continue;
                }

                $incomingRemaining = bcsub($incomingEnvelope['amount'], $incomingEnvelope['filled_amount']);
                $restingRemaining = bcsub($restingEnvelope['amount'], $restingEnvelope['filled_amount']);
                $fillAmount = bccomp($incomingRemaining, $restingRemaining) <= 0
                    ? $incomingRemaining
                    : $restingRemaining;
                $incomingEnvelope['filled_amount'] = bcadd($incomingEnvelope['filled_amount'], $fillAmount);
                $restingEnvelope['filled_amount'] = bcadd($restingEnvelope['filled_amount'], $fillAmount);

                $incoming->update([
                    'encrypted_envelope' => $incomingEnvelope,
                    'status' => bccomp($incomingEnvelope['filled_amount'], $incomingEnvelope['amount']) === 0
                        ? ClobOrder::Filled
                        : ClobOrder::Open,
                ]);
                $resting->update([
                    'encrypted_envelope' => $restingEnvelope,
                    'status' => bccomp($restingEnvelope['filled_amount'], $restingEnvelope['amount']) === 0
                        ? ClobOrder::Filled
                        : ClobOrder::Open,
                ]);

                $buy = $incoming->side === 'buy' ? $incoming : $resting;
                $sell = $incoming->side === 'sell' ? $incoming : $resting;
                $trades[] = ClobTrade::query()->create([
                    'market_id' => $incoming->market_id,
                    'token_id' => $incoming->token_id,
                    'buy_order_hash' => $buy->order_hash,
                    'sell_order_hash' => $sell->order_hash,
                    'amount' => $fillAmount,
                    'price' => $restingEnvelope['price'],
                    'matched_at' => now(),
                ]);

                if ($incoming->status === ClobOrder::Filled) {
                    break;
                }
            }

            return ['order' => $incoming->fresh(), 'trades' => $trades];
        }, attempts: 3);
    }

    public function cancel(string $orderHash, string $maker): ClobOrder
    {
        return DB::transaction(function () use ($orderHash, $maker): ClobOrder {
            $order = ClobOrder::query()->where('order_hash', $orderHash)->lockForUpdate()->firstOrFail();
            if ($order->status !== ClobOrder::Open || $order->encrypted_envelope['maker'] !== $maker) {
                throw new RuntimeException('Order cannot be cancelled.');
            }
            $order->update(['status' => ClobOrder::Cancelled]);

            return $order->fresh();
        }, attempts: 3);
    }

    /**
     * @return array{buy: array<int, array{price: string, amount: string}>, sell: array<int, array{price: string, amount: string}>}
     */
    public function book(string $marketId, string $tokenId): array
    {
        $levels = ['buy' => [], 'sell' => []];
        ClobOrder::query()
            ->where('market_id', $marketId)
            ->where('token_id', $tokenId)
            ->where('status', ClobOrder::Open)
            ->where('expires_at', '>', now())
            ->orderBy('id')
            ->get()
            ->each(function (ClobOrder $order) use (&$levels): void {
                $envelope = $order->encrypted_envelope;
                $remaining = bcsub($envelope['amount'], $envelope['filled_amount']);
                $levels[$order->side][$envelope['price']] = bcadd(
                    $levels[$order->side][$envelope['price']] ?? '0',
                    $remaining,
                );
            });

        uksort($levels['buy'], fn (string $left, string $right): int => bccomp($right, $left));
        uksort($levels['sell'], fn (string $left, string $right): int => bccomp($left, $right));

        foreach ($levels as $side => $prices) {
            $levels[$side] = collect($prices)
                ->map(fn (string $amount, string $price): array => compact('price', 'amount'))
                ->values()
                ->all();
        }

        return $levels;
    }

    /**
     * @return array{root: string, sequence_start: int, sequence_end: int, matches: array<int, array<string, mixed>>}|null
     */
    public function prepareSettlementBatch(int $limit = 2): ?array
    {
        if ($limit < 1 || $limit > 2) {
            throw new InvalidArgumentException('Settlement batch limit must be one or two matches.');
        }

        return DB::transaction(function () use ($limit): ?array {
            $candidates = ClobTrade::query()
                ->where('settlement_status', 'pending')
                ->orderBy('id')
                ->limit(250)
                ->lockForUpdate()
                ->get();
            $buyOrders = [];
            $sellOrders = [];
            $trades = $candidates->filter(function (ClobTrade $trade) use (&$buyOrders, &$sellOrders, $limit): bool {
                if (count($buyOrders) >= $limit
                    || isset($buyOrders[$trade->buy_order_hash])
                    || isset($sellOrders[$trade->sell_order_hash])) {
                    return false;
                }
                $buyOrders[$trade->buy_order_hash] = true;
                $sellOrders[$trade->sell_order_hash] = true;

                return true;
            })->take($limit)->values();
            if ($trades->isEmpty()) {
                return null;
            }

            $root = $this->fieldDigest($trades->map(fn (ClobTrade $trade): string => implode(':', [
                $trade->id,
                $trade->buy_order_hash,
                $trade->sell_order_hash,
                $trade->amount,
                $trade->price,
            ]))->implode('|'));
            ClobTrade::query()->whereKey($trades->modelKeys())->update([
                'settlement_status' => 'submitted',
                'settlement_root' => $root,
            ]);

            return $this->settlementBatch($root);
        }, attempts: 3);
    }

    /**
     * @return array{root: string, sequence_start: int, sequence_end: int, matches: array<int, array<string, mixed>>}
     */
    public function settlementBatch(string $root): array
    {
        $trades = ClobTrade::query()
            ->where('settlement_root', $root)
            ->orderBy('id')
            ->get();
        if ($trades->isEmpty()) {
            throw new RuntimeException('Settlement batch does not exist.');
        }

        $orders = ClobOrder::query()
            ->whereIn('order_hash', $trades->flatMap(
                fn (ClobTrade $trade): array => [$trade->buy_order_hash, $trade->sell_order_hash],
            )->unique())
            ->get()
            ->keyBy('order_hash');
        $matches = $trades->map(function (ClobTrade $trade) use ($orders): array {
            $buy = $orders->get($trade->buy_order_hash);
            $sell = $orders->get($trade->sell_order_hash);
            if (! $buy instanceof ClobOrder || ! $sell instanceof ClobOrder) {
                throw new RuntimeException('Settlement order envelope is missing.');
            }

            return [
                'sequence' => $trade->id,
                'amount' => $trade->amount,
                'price' => $trade->price,
                'buy' => $buy->encrypted_envelope,
                'sell' => $sell->encrypted_envelope,
            ];
        })->all();

        return [
            'root' => $root,
            'batch_id' => $root,
            'sequence_start' => $trades->firstOrFail()->id,
            'sequence_end' => $trades->last()->id,
            'matches' => $matches,
        ];
    }

    /**
     * @param  array<int, array<string, mixed>>  $stateTransitions
     * @return array{match_count: string, buys: array<int, array<string, mixed>>, sells: array<int, array<string, mixed>>, executions: array<int, array<string, string>>, state_transitions: array<int, array<string, mixed>>, settlement: array<string, string>}
     */
    public function proofPayload(
        string $batchId,
        string $previousRoot,
        int $sequence,
        int $settlementTime,
        array $stateTransitions,
    ): array {
        $batch = $this->settlementBatch($batchId);
        if (count($stateTransitions) !== count($batch['matches'])) {
            throw new InvalidArgumentException('Every match requires one transient state transition witness.');
        }
        $orders = fn (string $side): array => collect($batch['matches'])->map(
            fn (array $match): array => $this->proofOrder($match[$side]),
        )->all();
        $buys = $orders('buy');
        $sells = $orders('sell');
        $executions = collect($batch['matches'])->map(fn (array $match): array => [
            'fill_amount' => $match['amount'],
            'execution_price' => $match['price'],
        ])->all();
        $proofStateTransitions = array_map($this->proofStateTransition(...), $stateTransitions);
        while (count($buys) < 2) {
            $buys[] = $this->emptyProofOrder();
            $sells[] = $this->emptyProofOrder();
            $executions[] = ['fill_amount' => '0', 'execution_price' => '0'];
            $proofStateTransitions[] = $this->emptyStateTransition();
        }

        return [
            'match_count' => (string) count($batch['matches']),
            'buys' => $buys,
            'sells' => $sells,
            'executions' => $executions,
            'state_transitions' => $proofStateTransitions,
            'settlement' => [
                'previous_root' => $this->fieldValue($previousRoot, 'previous root'),
                'sequence' => (string) $sequence,
                'public_fee' => '0',
                'settlement_time' => (string) $settlementTime,
            ],
        ];
    }

    public function confirmSettlementBatch(string $root): int
    {
        $updated = ClobTrade::query()
            ->where('settlement_root', $root)
            ->where('settlement_status', 'submitted')
            ->update(['settlement_status' => 'confirmed']);
        if ($updated === 0) {
            throw new RuntimeException('Settlement batch is not awaiting confirmation.');
        }

        return $updated;
    }

    public function releaseSettlementBatch(string $root): int
    {
        $updated = ClobTrade::query()
            ->where('settlement_root', $root)
            ->where('settlement_status', 'submitted')
            ->update(['settlement_status' => 'pending', 'settlement_root' => null]);
        if ($updated === 0) {
            throw new RuntimeException('Settlement batch is not awaiting confirmation.');
        }

        return $updated;
    }

    /** @param Collection<int, ClobOrder> $orders @return Collection<int, ClobOrder> */
    private function priceTimeSorted(Collection $orders, string $incomingSide): Collection
    {
        return $orders->sort(function (ClobOrder $left, ClobOrder $right) use ($incomingSide): int {
            $priceComparison = bccomp(
                $left->encrypted_envelope['price'],
                $right->encrypted_envelope['price'],
            );
            if ($priceComparison !== 0) {
                return $incomingSide === 'buy' ? $priceComparison : -$priceComparison;
            }

            return $left->id <=> $right->id;
        })->values();
    }

    /** @param array<string, mixed> $incoming @param array<string, mixed> $resting */
    private function crosses(array $incoming, array $resting): bool
    {
        return $incoming['side'] === 'buy'
            ? bccomp($incoming['price'], $resting['price']) >= 0
            : bccomp($incoming['price'], $resting['price']) <= 0;
    }

    /** @param array<string, mixed> $envelope */
    private function validateEnvelope(array $envelope): void
    {
        foreach (['order_hash', 'market_id'] as $hash) {
            if (! isset($envelope[$hash]) || ! is_string($envelope[$hash])
                || ! preg_match('/^[a-f0-9]{64}$/', $envelope[$hash])) {
                throw new InvalidArgumentException("Invalid {$hash}.");
            }
        }
        foreach (['token_id', 'amount', 'price', 'nonce'] as $integer) {
            if (! isset($envelope[$integer]) || ! is_string($envelope[$integer])
                || ! preg_match('/^(0|[1-9][0-9]{0,77})$/', $envelope[$integer])) {
                throw new InvalidArgumentException("Invalid {$integer}.");
            }
        }
        if ($envelope['amount'] === '0' || $envelope['price'] === '0'
            || ! in_array($envelope['side'] ?? null, ['buy', 'sell'], true)
            || ! preg_match('/^0x[a-fA-F0-9]{40}$/', $envelope['maker'] ?? '')
            || ! preg_match('/^[a-fA-F0-9]{64}$/', $envelope['public_key_x'] ?? '')
            || ! preg_match('/^[a-fA-F0-9]{64}$/', $envelope['public_key_y'] ?? '')
            || ! preg_match('/^[a-fA-F0-9]{128}$/', $envelope['signature'] ?? '')
            || ! is_int($envelope['expiry'] ?? null) || $envelope['expiry'] <= now()->timestamp) {
            throw new InvalidArgumentException('Invalid order envelope.');
        }
        $this->fieldValue($envelope['market_id'], 'market id');
        $this->unsignedValue($envelope['token_id'], 254, 'token id');
        if ($envelope['token_id'] === '1') {
            throw new InvalidArgumentException('Outcome token cannot be the RAY quote asset.');
        }
        $this->unsignedValue($envelope['amount'], 128, 'amount');
        $this->unsignedValue($envelope['price'], 128, 'price');
        $this->unsignedValue($envelope['nonce'], 64, 'nonce');
    }

    /** @param array<string, mixed> $envelope @return array<string, mixed> */
    private function proofOrder(array $envelope): array
    {
        return [
            'data' => [
                'market_id' => $this->fieldValue($envelope['market_id'], 'market id'),
                'token_id' => $envelope['token_id'],
                'amount' => $envelope['amount'],
                'price' => $envelope['price'],
                'nonce' => $envelope['nonce'],
                'expiry' => (string) $envelope['expiry'],
            ],
            'public_key_x' => $this->hexBytes($envelope['public_key_x']),
            'public_key_y' => $this->hexBytes($envelope['public_key_y']),
            'signature' => $this->hexBytes($envelope['signature']),
        ];
    }

    /** @return array<string, mixed> */
    private function emptyProofOrder(): array
    {
        return [
            'data' => [
                'market_id' => '0',
                'token_id' => '0',
                'amount' => '0',
                'price' => '0',
                'nonce' => '0',
                'expiry' => '0',
            ],
            'public_key_x' => array_fill(0, 32, 0),
            'public_key_y' => array_fill(0, 32, 0),
            'signature' => array_fill(0, 64, 0),
        ];
    }

    /** @param array<string, mixed> $transition @return array<string, mixed> */
    private function proofStateTransition(array $transition): array
    {
        $normalized = [];
        foreach (['buyer_quote', 'seller_outcome', 'buyer_outcome', 'seller_quote'] as $balance) {
            if (! isset($transition[$balance]) || ! is_array($transition[$balance])) {
                throw new InvalidArgumentException("Missing {$balance} state witness.");
            }
            $normalized[$balance] = $this->proofBalanceWitness($transition[$balance]);
        }

        return $normalized;
    }

    /** @param array<string, mixed> $witness @return array<string, mixed> */
    private function proofBalanceWitness(array $witness): array
    {
        if (! isset($witness['balance'], $witness['blinding'], $witness['new_blinding'], $witness['index'], $witness['siblings'])
            || ! is_string($witness['balance'])
            || ! is_string($witness['blinding'])
            || ! is_string($witness['new_blinding'])
            || ! is_int($witness['index'])
            || $witness['index'] < 0 || $witness['index'] > 65_535
            || ! is_array($witness['siblings'])
            || count($witness['siblings']) !== 16
            || array_any($witness['siblings'], fn (mixed $sibling): bool => ! is_string($sibling))) {
            throw new InvalidArgumentException('Invalid balance state witness.');
        }
        $this->unsignedValue($witness['balance'], 128, 'balance');

        return [
            'balance' => $witness['balance'],
            'blinding' => $this->fieldValue($witness['blinding'], 'balance blinding'),
            'new_blinding' => $this->fieldValue($witness['new_blinding'], 'new balance blinding'),
            'index' => (string) $witness['index'],
            'siblings' => array_map(
                fn (string $sibling): string => $this->fieldValue($sibling, 'balance sibling'),
                $witness['siblings'],
            ),
        ];
    }

    /** @return array<string, mixed> */
    private function emptyStateTransition(): array
    {
        $balance = [
            'balance' => '0',
            'blinding' => '0',
            'new_blinding' => '0',
            'index' => '0',
            'siblings' => array_fill(0, 16, '0'),
        ];

        return [
            'buyer_quote' => $balance,
            'seller_outcome' => $balance,
            'buyer_outcome' => $balance,
            'seller_quote' => $balance,
        ];
    }

    /** @return array<int, int> */
    private function hexBytes(string $hex): array
    {
        return array_map(hexdec(...), str_split($hex, 2));
    }

    private function fieldValue(string $hex, string $name): string
    {
        if (! preg_match('/^[a-f0-9]{64}$/', $hex)) {
            throw new InvalidArgumentException("Invalid {$name}.");
        }
        $value = BigInteger::fromBase($hex, 16);
        $field = BigInteger::of('21888242871839275222246405745257275088548364400416034343698204186575808495617');
        if ($value->isGreaterThanOrEqualTo($field)) {
            throw new InvalidArgumentException("Invalid {$name}.");
        }

        return $value->toBase(10);
    }

    private function unsignedValue(string $value, int $bits, string $name): void
    {
        if (BigInteger::of($value)->isGreaterThan(BigInteger::of(2)->power($bits)->minus(1))) {
            throw new InvalidArgumentException("Invalid {$name}.");
        }
    }

    private function fieldDigest(string $payload): string
    {
        $field = BigInteger::of('21888242871839275222246405745257275088548364400416034343698204186575808495617');
        $digest = BigInteger::fromBase(hash('sha256', $payload), 16)->mod($field)->toBase(16);

        return str_pad($digest, 64, '0', STR_PAD_LEFT);
    }
}
