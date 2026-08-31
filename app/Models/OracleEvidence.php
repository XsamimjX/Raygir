<?php

namespace App\Models;

use Database\Factories\OracleEvidenceFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OracleEvidence extends Model
{
    /** @use HasFactory<OracleEvidenceFactory> */
    use HasFactory;

    use HasUuids;

    protected $fillable = [
        'market_id',
        'source_url',
        'content_hash',
        'observed_at',
        'evidence_cutoff_at',
    ];

    protected function casts(): array
    {
        return [
            'observed_at' => 'immutable_datetime',
            'evidence_cutoff_at' => 'immutable_datetime',
        ];
    }
}
