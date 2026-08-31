<?php

return [
    'did' => env('ISSUER_DID', 'did:web:issuer-demo.local'),
    'signing_secret' => env('ISSUER_SIGNING_SECRET'),
    'challenge_ttl_seconds' => 300,
    'epoch_seconds' => 86_400,
    'policies' => [
        'adult-citizen-v1' => [
            'version' => 1,
            'credit_limit' => 1,
        ],
    ],
];
