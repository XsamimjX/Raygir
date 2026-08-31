<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IssuedCredential extends Model
{
    use HasUuids;

    protected $fillable = [
        'eligibility_challenge_id',
        'policy',
        'epoch',
        'commitment_hash',
        'issuer_signature',
        'revoked_at',
    ];

    protected $hidden = ['issuer_signature'];

    protected function casts(): array
    {
        return [
            'epoch' => 'integer',
            'revoked_at' => 'immutable_datetime',
        ];
    }

    public function challenge(): BelongsTo
    {
        return $this->belongsTo(EligibilityChallenge::class, 'eligibility_challenge_id');
    }
}
