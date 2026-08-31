<?php

use App\Models\EligibilityChallenge;
use App\Models\IssuedCredential;
use App\Models\IssuerRootSnapshot;

test('issuer roots are auditable snapshots and revocations create a new version', function () {
    $challenge = EligibilityChallenge::query()->create([
        'policy' => 'adult-citizen-v1',
        'subject_reference_hash' => hash('sha256', 'fictional-person'),
        'challenge_hash' => hash('sha256', 'challenge'),
        'expires_at' => now()->addHour(),
    ]);
    $credential = IssuedCredential::query()->create([
        'eligibility_challenge_id' => $challenge->id,
        'policy' => 'adult-citizen-v1',
        'epoch' => 7,
        'commitment_hash' => str_repeat('ab', 32),
        'issuer_signature' => 'test-signature',
    ]);

    $first = $this->getJson('/api/v1/issuer-roots/adult-citizen-v1/7')
        ->assertSuccessful()
        ->assertJsonPath('count', 1)
        ->json();
    $second = $this->getJson('/api/v1/issuer-roots/adult-citizen-v1/7')
        ->assertSuccessful()
        ->json();

    expect($second['snapshot_id'])->toBe($first['snapshot_id'])
        ->and(IssuerRootSnapshot::query()->count())->toBe(1);

    $emptyRevocations = $this->getJson('/api/v1/revocation-roots/adult-citizen-v1/7')
        ->assertSuccessful()
        ->assertJsonPath('count', 0)
        ->json();
    $credential->update(['revoked_at' => now()]);
    $revoked = $this->getJson('/api/v1/revocation-roots/adult-citizen-v1/7')
        ->assertSuccessful()
        ->assertJsonPath('count', 1)
        ->json();

    expect($revoked['snapshot_id'])->not->toBe($emptyRevocations['snapshot_id'])
        ->and($revoked['root'])->not->toBe($emptyRevocations['root'])
        ->and(IssuerRootSnapshot::query()->where('kind', 'revocation')->count())->toBe(2);
});
