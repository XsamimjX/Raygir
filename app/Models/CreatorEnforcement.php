<?php

namespace App\Models;

use Database\Factories\CreatorEnforcementFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CreatorEnforcement extends Model
{
    /** @use HasFactory<CreatorEnforcementFactory> */
    use HasFactory;

    use HasUuids;

    protected $fillable = [
        'credential_hash',
        'violation_type',
        'reason_hash',
        'occurred_at',
        'banned_until',
    ];

    protected function casts(): array
    {
        return [
            'occurred_at' => 'immutable_datetime',
            'banned_until' => 'immutable_datetime',
        ];
    }
}
