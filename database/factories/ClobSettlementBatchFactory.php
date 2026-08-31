<?php

namespace Database\Factories;

use App\Models\ClobSettlementBatch;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ClobSettlementBatch>
 */
class ClobSettlementBatchFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'batch_id' => hash('sha256', fake()->uuid()),
            'previous_root' => str_pad('1', 64, '0', STR_PAD_LEFT),
            'sequence' => fake()->numberBetween(1, 1_000_000),
            'match_count' => 1,
            'settlement_time' => now()->timestamp,
            'encrypted_witness' => ['fixture' => true],
            'status' => ClobSettlementBatch::Queued,
        ];
    }
}
