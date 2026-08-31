<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\PublicContentReviewer;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMarketReviewRequest;
use App\Models\MarketReview;
use App\Models\OracleEvidence;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Throwable;

class MarketReviewController extends Controller
{
    public function __construct(private PublicContentReviewer $reviewer) {}

    public function __invoke(StoreMarketReviewRequest $request): JsonResponse
    {
        $publicContent = $request->validated();
        $payloadHash = hash('sha384', $this->canonicalJson($publicContent));

        try {
            $result = $this->reviewer->review($publicContent);
            $allowedSources = collect($publicContent['sources'])->pluck('url');

            if (collect($result['cited_sources'])->diff($allowedSources)->isNotEmpty()) {
                throw new \UnexpectedValueException('Reviewer cited a source outside the market allowlist.');
            }
        } catch (Throwable) {
            $result = [
                'decision' => 'provider_failure',
                'reason_codes' => ['provider_unavailable_or_invalid'],
                'confidence' => null,
                'cited_sources' => [],
                'model_id' => null,
                'prompt_hash' => hash('sha384', 'raygir-market-review-v1:'.$payloadHash),
            ];
        }

        $review = DB::transaction(function () use ($publicContent, $payloadHash, $result): MarketReview {
            $review = MarketReview::query()->create([
                'market_id' => $publicContent['market_id'],
                'decision' => $result['decision'],
                'confidence_basis_points' => $result['confidence'] === null
                    ? null
                    : (int) round($result['confidence'] * 10_000),
                'reason_codes' => $result['reason_codes'],
                'cited_sources' => $result['cited_sources'],
                'model_id' => $result['model_id'],
                'public_payload_hash' => $payloadHash,
                'prompt_hash' => $result['prompt_hash'],
                'schema_version' => 1,
                'reviewed_at' => now(),
            ]);

            foreach ($publicContent['sources'] as $source) {
                OracleEvidence::query()->firstOrCreate([
                    'market_id' => $publicContent['market_id'],
                    'content_hash' => hash('sha384', $source['content']),
                ], [
                    'source_url' => $source['url'],
                    'observed_at' => now(),
                    'evidence_cutoff_at' => $publicContent['evidence_cutoff_at'],
                ]);
            }

            return $review;
        });

        return response()->json([
            'data' => Arr::only($review->toArray(), [
                'id',
                'market_id',
                'decision',
                'confidence_basis_points',
                'reason_codes',
                'cited_sources',
                'model_id',
                'public_payload_hash',
                'prompt_hash',
                'schema_version',
                'reviewed_at',
            ]),
            'escrow_action' => match ($review->decision) {
                'approved' => 'release_to_treasury',
                'content_rejected' => 'refund_90_percent',
                default => 'refund_100_percent',
            },
            'settlement_authorized' => false,
        ], 201);
    }

    /** @param array<string, mixed> $payload */
    private function canonicalJson(array $payload): string
    {
        array_walk_recursive($payload, static function (&$value): void {
            if (is_string($value)) {
                $value = trim($value);
            }
        });
        ksort($payload);

        return json_encode($payload, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }
}
