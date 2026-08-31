<?php

use App\Models\EligibilityChallenge;
use App\Models\IssuedCredential;

beforeEach(function () {
    $keyPair = sodium_crypto_sign_keypair();
    config()->set('issuer.signing_secret', sodium_bin2base64(
        sodium_crypto_sign_secretkey($keyPair),
        SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
    ));
});

test('issuer metadata contains no wallet or voter callback', function () {
    $this->getJson('/.well-known/raygir-issuer')
        ->assertSuccessful()
        ->assertJsonMissingPath('wallet')
        ->assertJsonMissingPath('voting_callback')
        ->assertJsonStructure(['version', 'did', 'blind_issue_endpoint', 'challenge_endpoint']);
});

test('a blinded commitment can be issued once without storing its person reference', function () {
    $challenge = $this->postJson('/api/v1/eligibility/challenges', [
        'policy' => 'adult-citizen-v1',
        'person_reference' => 'fictional-person-42',
    ])->assertCreated()->json();

    $this->postJson('/api/v1/credentials/blind-issue', [
        'challenge_id' => $challenge['challenge_id'],
        'challenge' => $challenge['challenge'],
        'policy' => 'adult-citizen-v1',
        'blinded_commitment' => str_repeat('ab', 32),
    ])->assertCreated()->assertJsonStructure([
        'credential_id', 'policy', 'epoch', 'issuer_did', 'issuer_signature',
    ]);

    expect(EligibilityChallenge::query()->firstOrFail()->subject_reference_hash)
        ->not->toBe('fictional-person-42')
        ->and(IssuedCredential::query()->firstOrFail()->commitment_hash)
        ->toBe(str_repeat('ab', 32));

    $this->postJson('/api/v1/credentials/blind-issue', [
        'challenge_id' => $challenge['challenge_id'],
        'challenge' => $challenge['challenge'],
        'policy' => 'adult-citizen-v1',
        'blinded_commitment' => str_repeat('cd', 32),
    ])->assertUnprocessable();
});

test('root endpoints expose aggregate hashes rather than identities', function () {
    $this->getJson('/api/v1/issuer-roots/adult-citizen-v1/1')
        ->assertSuccessful()
        ->assertJsonStructure(['policy', 'epoch', 'algorithm', 'root', 'count'])
        ->assertJsonMissingPath('identities');
});

test('only configured policies issue credentials and expose credit limits', function () {
    $this->getJson('/api/v1/eligibility-policies/adult-citizen-v1')
        ->assertSuccessful()
        ->assertJsonPath('credit_limit', 1);

    $this->getJson('/api/v1/eligibility-policies/unknown-policy')->assertNotFound();
    $this->postJson('/api/v1/eligibility/challenges', [
        'policy' => 'unknown-policy',
        'person_reference' => 'fictional-person-42',
    ])->assertUnprocessable();
});
