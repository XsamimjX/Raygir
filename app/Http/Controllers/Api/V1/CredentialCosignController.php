<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\CosignCredentialRequest;
use App\Models\CredentialCosignature;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\HttpException;

class CredentialCosignController extends Controller
{
    public function __invoke(CosignCredentialRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $commitment = Str::lower($validated['blinded_commitment']);
        $message = implode(':', [
            'raygir-eligibility-v1',
            $validated['issuer_did'],
            $validated['policy'],
            $validated['epoch'],
            $commitment,
        ]);
        $issuerPublicKey = $this->issuerPublicKey($validated['issuer_did']);
        $issuerSignature = $this->decode($validated['issuer_signature']);
        if (! sodium_crypto_sign_verify_detached($issuerSignature, $message, $issuerPublicKey)) {
            throw new HttpException(422, 'The issuer signature is invalid.');
        }

        $raygirSignature = sodium_crypto_sign_detached($message, $this->raygirSigningSecret());
        $record = CredentialCosignature::create([
            'issuer_did' => $validated['issuer_did'],
            'policy' => $validated['policy'],
            'epoch' => $validated['epoch'],
            'commitment_hash' => $commitment,
            'issuer_signature_hash' => hash('sha3-384', $issuerSignature),
            'raygir_signature' => sodium_bin2base64(
                $raygirSignature,
                SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
            ),
        ]);

        return response()->json([
            'credential_id' => $record->id,
            'raygir_signature' => $record->getRawOriginal('raygir_signature'),
        ], 201);
    }

    private function issuerPublicKey(string $did): string
    {
        if (! hash_equals((string) config('services.eligibility.issuer_did'), $did)) {
            throw new HttpException(422, 'The issuer is not trusted.');
        }
        $configured = config('services.eligibility.issuer_public_key');
        if (! is_string($configured) || $configured === '') {
            throw new HttpException(422, 'The issuer is not trusted.');
        }
        $key = $this->decode($configured);
        if (strlen($key) !== SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES) {
            throw new HttpException(503, 'The issuer key is misconfigured.');
        }

        return $key;
    }

    private function raygirSigningSecret(): string
    {
        $configured = config('services.eligibility.raygir_signing_secret');
        if (! is_string($configured) || $configured === '') {
            throw new HttpException(503, 'Raygir credential signing is not configured.');
        }
        $key = $this->decode($configured);
        if (strlen($key) !== SODIUM_CRYPTO_SIGN_SECRETKEYBYTES) {
            throw new HttpException(503, 'Raygir credential signing is not configured.');
        }

        return $key;
    }

    private function decode(string $value): string
    {
        try {
            return sodium_base642bin($value, SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
        } catch (\SodiumException) {
            throw new HttpException(422, 'The signature encoding is invalid.');
        }
    }
}
