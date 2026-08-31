<?php

namespace App\Models;

use Database\Factories\ClobTradeFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClobTrade extends Model
{
    /** @use HasFactory<ClobTradeFactory> */
    use HasFactory;

    protected $fillable = [
        'market_id',
        'token_id',
        'buy_order_hash',
        'sell_order_hash',
        'amount',
        'price',
        'settlement_status',
        'settlement_root',
        'matched_at',
    ];

    protected $attributes = ['settlement_status' => 'pending'];

    protected function casts(): array
    {
        return ['matched_at' => 'immutable_datetime'];
    }
}
