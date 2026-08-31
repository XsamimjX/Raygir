<?php

namespace App\Actions;

use App\Models\CreatorEnforcement;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class RecordCreatorViolation
{
    public const string NonMalicious = 'non_malicious';

    public const string DeliberateDeception = 'deliberate_deception';

    public function handle(string $credentialHash, string $violationType, string $reasonHash): CreatorEnforcement
    {
        if (! preg_match('/^[a-f0-9]{64}$/', $credentialHash)
            || ! preg_match('/^[a-f0-9]{96}$/', $reasonHash)
            || ! in_array($violationType, [self::NonMalicious, self::DeliberateDeception], true)) {
            throw new InvalidArgumentException('Invalid creator enforcement input.');
        }

        return DB::transaction(function () use ($credentialHash, $violationType, $reasonHash): CreatorEnforcement {
            $occurredAt = now();
            $bannedUntil = null;

            if ($violationType === self::DeliberateDeception) {
                $recentDeception = CreatorEnforcement::query()
                    ->where('credential_hash', $credentialHash)
                    ->where('violation_type', self::DeliberateDeception)
                    ->where('occurred_at', '>=', $occurredAt->copy()->subDays(180))
                    ->lockForUpdate()
                    ->exists();
                $bannedUntil = $occurredAt->copy()->addDays($recentDeception ? 365 : 30);
            }

            return CreatorEnforcement::query()->create([
                'credential_hash' => $credentialHash,
                'violation_type' => $violationType,
                'reason_hash' => $reasonHash,
                'occurred_at' => $occurredAt,
                'banned_until' => $bannedUntil,
            ]);
        }, attempts: 3);
    }
}
