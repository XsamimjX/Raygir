<?php

namespace Database\Factories;

use App\Models\ClobTrade;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ClobTrade>
 */
class ClobTradeFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'market_id' => hash('sha256', fake()->uuid()),
            'token_id' => '2',
            'buy_order_hash' => hash('sha256', fake()->uuid()),
            'sell_order_hash' => hash('sha256', fake()->uuid()),
            'amount' => '1000000000000000000',
            'price' => '500000000000000000',
            'settlement_status' => 'pending',
            'matched_at' => now(),
        ];
    }
}
