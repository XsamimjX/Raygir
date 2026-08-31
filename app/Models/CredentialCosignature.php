<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class CredentialCosignature extends Model
{
    use HasUuids;

    protected $fillable = [
        'issuer_did',
        'policy',
        'epoch',
        'commitment_hash',
        'issuer_signature_hash',
        'raygir_signature',
    ];

    protected $hidden = ['raygir_signature'];

    protected function casts(): array
    {
        return ['epoch' => 'integer'];
    }
}
