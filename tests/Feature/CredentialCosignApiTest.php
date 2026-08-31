<?php

use App\Models\CredentialCosignature;

test('raygir co-signs a valid blinded issuer credential without wallet data', function () {
    $issuerKeyPair = sodium_crypto_sign_keypair();
    $raygirKeyPair = sodium_crypto_sign_keypair();
    $did = 'did:web:issuer-demo.local';
    $policy = 'adult-citizen-v1';
    $epoch = 1;
    $commitment = str_repeat('ab', 32);
    $message = implode(':', ['raygir-eligibility-v1', $did, $policy, $epoch, $commitment]);
    config()->set('services.eligibility.issuer_did', $did);
    config()->set('services.eligibility.issuer_public_key', sodium_bin2base64(
        sodium_crypto_sign_publickey($issuerKeyPair),
        SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
    ));
    config()->set('services.eligibility.raygir_signing_secret', sodium_bin2base64(
        sodium_crypto_sign_secretkey($raygirKeyPair),
        SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
    ));

    $this->postJson('/api/v1/credentials/co-sign', [
        'issuer_did' => $did,
        'policy' => $policy,
        'epoch' => $epoch,
        'blinded_commitment' => $commitment,
        'issuer_signature' => sodium_bin2base64(
            sodium_crypto_sign_detached($message, sodium_crypto_sign_secretkey($issuerKeyPair)),
            SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
        ),
    ])->assertCreated()->assertJsonStructure(['credential_id', 'raygir_signature']);

    $record = CredentialCosignature::query()->firstOrFail();
    expect($record->getAttributes())
        ->not->toHaveKeys(['wallet', 'wallet_address', 'person_reference', 'identity']);
});

test('raygir rejects a forged issuer signature', function () {
    $issuerKeyPair = sodium_crypto_sign_keypair();
    $attackerKeyPair = sodium_crypto_sign_keypair();
    config()->set('services.eligibility.issuer_did', 'did:web:issuer-demo.local');
    config()->set('services.eligibility.issuer_public_key', sodium_bin2base64(
        sodium_crypto_sign_publickey($issuerKeyPair),
        SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
    ));
    config()->set('services.eligibility.raygir_signing_secret', sodium_bin2base64(
        sodium_crypto_sign_secretkey($issuerKeyPair),
        SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
    ));

    $this->postJson('/api/v1/credentials/co-sign', [
        'issuer_did' => 'did:web:issuer-demo.local',
        'policy' => 'adult-citizen-v1',
        'epoch' => 1,
        'blinded_commitment' => str_repeat('ab', 32),
        'issuer_signature' => sodium_bin2base64(
            sodium_crypto_sign_detached('forged', sodium_crypto_sign_secretkey($attackerKeyPair)),
            SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
        ),
    ])->assertUnprocessable();
});
