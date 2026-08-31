<?php

test('the versioned eligibility contract documents every public endpoint', function () {
    $contract = file_get_contents(base_path('openapi.yaml'));

    expect($contract)
        ->toBeString()
        ->toContain('openapi: 3.1.0')
        ->toContain('version: 1.0.0')
        ->toContain('/.well-known/raygir-issuer:')
        ->toContain('/api/v1/eligibility/challenges:')
        ->toContain('/api/v1/credentials/blind-issue:')
        ->toContain('/api/v1/credentials/co-sign:')
        ->toContain('/api/v1/eligibility-policies/{policy}:')
        ->toContain('/api/v1/issuer-roots/{policy}/{epoch}:')
        ->toContain('/api/v1/revocation-roots/{policy}/{epoch}:')
        ->toContain('additionalProperties: false');
});
