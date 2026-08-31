<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class IssuerRootSnapshot extends Model
{
    use HasUuids;

    protected $fillable = [
        'policy',
        'epoch',
        'kind',
        'root',
        'entry_count',
        'source_version',
    ];

    protected function casts(): array
    {
        return [
            'epoch' => 'integer',
            'entry_count' => 'integer',
        ];
    }
}
