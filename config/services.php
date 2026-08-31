<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'market_review' => [
        'endpoint' => env('MARKET_REVIEW_ENDPOINT'),
        'token' => env('MARKET_REVIEW_TOKEN'),
    ],

    'evidence' => [
        'allowed_hosts' => array_values(array_filter(array_map(
            static fn (string $host): string => mb_strtolower(trim($host)),
            explode(',', (string) env('EVIDENCE_ALLOWED_HOSTS', '')),
        ))),
    ],

    'eligibility' => [
        'issuer_did' => env('ELIGIBILITY_ISSUER_DID'),
        'issuer_public_key' => env('ELIGIBILITY_ISSUER_PUBLIC_KEY'),
        'raygir_signing_secret' => env('ELIGIBILITY_RAYGIR_SIGNING_SECRET'),
    ],

    'clob' => [
        'prover_command' => env('CLOB_PROVER_COMMAND'),
        'prover_timeout' => env('CLOB_PROVER_TIMEOUT', 120),
        'gateway_endpoint' => env('CLOB_GATEWAY_ENDPOINT'),
        'gateway_token' => env('CLOB_GATEWAY_TOKEN'),
    ],

];
