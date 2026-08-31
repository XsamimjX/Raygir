<?php

namespace Database\Factories;

use App\Actions\RecordCreatorViolation;
use App\Models\CreatorEnforcement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CreatorEnforcement>
 */
class CreatorEnforcementFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'credential_hash' => hash('sha256', fake()->uuid()),
            'violation_type' => RecordCreatorViolation::NonMalicious,
            'reason_hash' => hash('sha384', fake()->sentence()),
            'occurred_at' => now(),
            'banned_until' => null,
        ];
    }
}
