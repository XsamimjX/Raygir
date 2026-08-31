<?php

namespace App\Models;

use Database\Factories\MarketReviewFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MarketReview extends Model
{
    /** @use HasFactory<MarketReviewFactory> */
    use HasFactory;

    use HasUuids;

    protected $fillable = [
        'market_id',
        'decision',
        'confidence_basis_points',
        'reason_codes',
        'cited_sources',
        'model_id',
        'public_payload_hash',
        'prompt_hash',
        'schema_version',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'reason_codes' => 'array',
            'cited_sources' => 'array',
            'reviewed_at' => 'immutable_datetime',
        ];
    }
}
