<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class RelayerSubmission extends Model
{
    use HasUuids;

    protected $fillable = [
        'nullifier',
        'proof_hash',
        'call_data',
        'expires_at',
        'status',
        'transaction_hash',
    ];

    protected function casts(): array
    {
        return ['expires_at' => 'immutable_datetime'];
    }
}
