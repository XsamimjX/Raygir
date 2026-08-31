<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\CreateChallengeRequest;
use App\Http\Requests\Api\V1\IssueCredentialRequest;
use App\Models\EligibilityChallenge;
use App\Models\IssuedCredential;
use App\Models\IssuerRootSnapshot;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\HttpException;

class EligibilityController extends Controller
{
    public function challenge(CreateChallengeRequest $request): JsonResponse
    {
        $challenge = random_bytes(32);
        $validated = $request->validated();
        $record = EligibilityChallenge::create([
            'policy' => $validated['policy'],
            'subject_reference_hash' => hash_hmac(
                'sha256',
                $validated['person_reference'],
                config('app.key'),
            ),
            'challenge_hash' => hash('sha256', $challenge),
            'expires_at' => now()->addSeconds(config('issuer.challenge_ttl_seconds')),
        ]);

        return response()->json([
            'challenge_id' => $record->id,
            'challenge' => sodium_bin2base64($challenge, SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING),
            'expires_at' => $record->expires_at->toIso8601String(),
        ], 201);
    }

    public function issue(IssueCredentialRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $secretKey = $this->signingSecret();

        $credential = DB::transaction(function () use ($validated, $secretKey): IssuedCredential {
            $challenge = EligibilityChallenge::query()
                ->lockForUpdate()
                ->findOrFail($validated['challenge_id']);
            $decodedChallenge = sodium_base642bin(
                $validated['challenge'],
                SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
            );

            if (
                $challenge->policy !== $validated['policy'] || $challenge->used_at !== null
                || $challenge->expires_at->isPast()
                || ! hash_equals($challenge->challenge_hash, hash('sha256', $decodedChallenge))
            ) {
                throw new HttpException(422, 'The eligibility challenge is invalid or expired.');
            }

            $epoch = intdiv(now()->timestamp, config('issuer.epoch_seconds'));
            $message = implode(':', [
                'raygir-eligibility-v1',
                config('issuer.did'),
                $validated['policy'],
                $epoch,
                Str::lower($validated['blinded_commitment']),
            ]);
            $signature = sodium_crypto_sign_detached($message, $secretKey);
            $challenge->update(['used_at' => now()]);

            return IssuedCredential::create([
                'eligibility_challenge_id' => $challenge->id,
                'policy' => $validated['policy'],
                'epoch' => $epoch,
                'commitment_hash' => Str::lower($validated['blinded_commitment']),
                'issuer_signature' => sodium_bin2base64(
                    $signature,
                    SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING,
                ),
            ]);
        });

        return response()->json([
            'credential_id' => $credential->id,
            'policy' => $credential->policy,
            'epoch' => $credential->epoch,
            'issuer_did' => config('issuer.did'),
            'issuer_signature' => $credential->getRawOriginal('issuer_signature'),
        ], 201);
    }

    public function policy(string $policy): JsonResponse
    {
        $configuration = config("issuer.policies.{$policy}");
        abort_unless(is_array($configuration), 404);

        return response()->json([
            'policy' => $policy,
            'version' => $configuration['version'],
            'credit_limit' => $configuration['credit_limit'],
            'credential_type' => 'blinded-commitment',
            'issuer_did' => config('issuer.did'),
        ]);
    }

    public function issuerRoot(string $policy, int $epoch): JsonResponse
    {
        return $this->rootResponse($policy, $epoch, false);
    }

    public function revocationRoot(string $policy, int $epoch): JsonResponse
    {
        return $this->rootResponse($policy, $epoch, true);
    }

    private function rootResponse(string $policy, int $epoch, bool $revoked): JsonResponse
    {
        abort_unless(preg_match('/^[a-z0-9._-]+$/', $policy) === 1 && $epoch >= 0, 404);

        $commitments = IssuedCredential::query()
            ->where('policy', $policy)
            ->where('epoch', $epoch)
            ->when($revoked, fn ($query) => $query->whereNotNull('revoked_at'))
            ->orderBy('commitment_hash')
            ->pluck('commitment_hash');
        $serialized = $commitments->implode(':');
        $kind = $revoked ? 'revocation' : 'issuer';
        $root = hash('sha3-384', $serialized);
        $snapshot = IssuerRootSnapshot::query()->firstOrCreate([
            'policy' => $policy,
            'epoch' => $epoch,
            'kind' => $kind,
            'source_version' => hash('sha3-384', $kind.':'.$serialized),
        ], [
            'root' => $root,
            'entry_count' => $commitments->count(),
        ]);

        return response()->json([
            'snapshot_id' => $snapshot->id,
            'policy' => $policy,
            'epoch' => $epoch,
            'algorithm' => 'sha3-384',
            'root' => $snapshot->root,
            'count' => $snapshot->entry_count,
        ]);
    }

    private function signingSecret(): string
    {
        $configured = config('issuer.signing_secret');
        if (! is_string($configured) || $configured === '') {
            throw new HttpException(503, 'Issuer signing is not configured.');
        }
        $secretKey = sodium_base642bin($configured, SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
        if (strlen($secretKey) !== SODIUM_CRYPTO_SIGN_SECRETKEYBYTES) {
            throw new HttpException(503, 'Issuer signing is not configured.');
        }

        return $secretKey;
    }
}
