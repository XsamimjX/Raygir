<?php

namespace Database\Factories;

use App\Models\ClobOrder;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ClobOrder>
 */
class ClobOrderFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'order_hash' => hash('sha256', fake()->uuid()),
            'market_id' => hash('sha256', fake()->uuid()),
            'token_id' => '2',
            'side' => 'buy',
            'encrypted_envelope' => [
                'maker' => '0x'.str_repeat('1', 40),
                'amount' => '1000000000000000000',
                'price' => '500000000000000000',
                'filled_amount' => '0',
                'nonce' => '1',
                'signature' => '0x'.str_repeat('a', 130),
            ],
            'status' => ClobOrder::Open,
            'expires_at' => now()->addHour(),
        ];
    }
}
