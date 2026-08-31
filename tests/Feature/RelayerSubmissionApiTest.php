<?php

use App\Models\RelayerSubmission;

test('anonymous relay stores only public execution material and hashes the proof', function () {
    $proof = str_repeat('proof-material-', 20);
    $response = $this->postJson('/api/v1/relay/submissions', [
        'nullifier' => str_repeat('ab', 32),
        'proof' => $proof,
        'call_data' => '0x1234abcd',
        'expires_at' => now()->addMinutes(5)->toIso8601String(),
    ])->assertAccepted()->assertJson(['status' => 'pending']);

    $submission = RelayerSubmission::query()->findOrFail($response->json('submission_id'));
    expect($submission->proof_hash)
        ->toBe(hash('sha3-384', $proof))
        ->and($submission->getAttributes())
        ->not->toHaveKeys([
            'proof', 'wallet', 'wallet_address', 'ip_address', 'user_agent', 'identity',
        ]);
});

test('nullifiers cannot be submitted twice', function () {
    $payload = [
        'nullifier' => str_repeat('ab', 32),
        'proof' => 'proof',
        'call_data' => '0x1234',
        'expires_at' => now()->addMinutes(5)->toIso8601String(),
    ];
    $this->postJson('/api/v1/relay/submissions', $payload)->assertAccepted();
    $this->postJson('/api/v1/relay/submissions', $payload)->assertUnprocessable();
});
