<?php

namespace App\Models;

use Database\Factories\ClobSettlementBatchFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClobSettlementBatch extends Model
{
    /** @use HasFactory<ClobSettlementBatchFactory> */
    use HasFactory;

    public const Queued = 'queued';

    public const Proving = 'proving';

    public const Proven = 'proven';

    public const Submitted = 'submitted';

    public const Confirmed = 'confirmed';

    protected $fillable = [
        'batch_id',
        'previous_root',
        'next_root',
        'sequence',
        'match_count',
        'settlement_time',
        'encrypted_witness',
        'proof',
        'public_inputs',
        'transaction_hash',
        'confirmed_block_number',
        'confirmed_block_hash',
        'status',
        'last_error',
        'witness_erased_at',
    ];

    protected $hidden = ['encrypted_witness', 'proof'];

    protected function casts(): array
    {
        return [
            'encrypted_witness' => 'encrypted:array',
            'public_inputs' => 'array',
            'witness_erased_at' => 'immutable_datetime',
        ];
    }
}
