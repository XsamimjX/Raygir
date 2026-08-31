<?php

namespace App\Models;

use Database\Factories\ClobOrderFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClobOrder extends Model
{
    /** @use HasFactory<ClobOrderFactory> */
    use HasFactory;

    public const string Open = 'open';

    public const string Filled = 'filled';

    public const string Cancelled = 'cancelled';

    protected $fillable = [
        'order_hash',
        'market_id',
        'token_id',
        'side',
        'encrypted_envelope',
        'status',
        'expires_at',
    ];

    protected $hidden = ['encrypted_envelope'];

    protected $attributes = ['status' => self::Open];

    protected function casts(): array
    {
        return [
            'encrypted_envelope' => 'encrypted:array',
            'expires_at' => 'immutable_datetime',
        ];
    }
}
