<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;

class EligibilityChallenge extends Model
{
    use HasUuids;

    protected $fillable = [
        'policy',
        'subject_reference_hash',
        'challenge_hash',
        'expires_at',
        'used_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'immutable_datetime',
            'used_at' => 'immutable_datetime',
        ];
    }

    public function credential(): HasOne
    {
        return $this->hasOne(IssuedCredential::class);
    }
}
