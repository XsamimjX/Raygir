<?php

namespace App\Services\Moderation;

use App\Contracts\PublicContentReviewer;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use RuntimeException;

class HttpPublicContentReviewer implements PublicContentReviewer
{
    public function review(array $publicContent): array
    {
        $endpoint = config('services.market_review.endpoint');

        if (! is_string($endpoint) || $endpoint === '') {
            throw new RuntimeException('Market review endpoint is not configured.');
        }

        try {
            $response = Http::acceptJson()
                ->withToken((string) config('services.market_review.token'))
                ->connectTimeout(3)
                ->timeout(20)
                ->retry(2, 200)
                ->post($endpoint, [
                    'schema_version' => 1,
                    'public_content' => $publicContent,
                ])
                ->throw();
        } catch (ConnectionException $exception) {
            throw new RuntimeException('Market review provider is unavailable.', previous: $exception);
        }

        $result = $response->json();
        $validated = Validator::make(is_array($result) ? $result : [], [
            'decision' => ['required', 'in:approved,content_rejected'],
            'reason_codes' => ['required', 'array'],
            'reason_codes.*' => ['string', 'max:100'],
            'confidence' => ['required', 'numeric', 'between:0,1'],
            'cited_sources' => ['required', 'array'],
            'cited_sources.*' => ['url', 'max:2048'],
            'model_id' => ['required', 'string', 'max:160'],
            'prompt_hash' => ['required', 'regex:/^[a-f0-9]{96}$/'],
        ])->validate();

        /** @var array{decision: string, reason_codes: array<int, string>, confidence: float, cited_sources: array<int, string>, model_id: string, prompt_hash: string} $validated */
        return $validated;
    }
}
