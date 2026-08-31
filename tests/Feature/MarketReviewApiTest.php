<?php

use App\Contracts\PublicContentReviewer;
use App\Models\MarketReview;
use App\Models\OracleEvidence;
use App\Models\User;

function validMarketReviewPayload(): array
{
    return [
        'market_id' => str_repeat('ab', 32),
        'question' => ['fa' => 'آیا رویداد رخ می‌دهد؟', 'en' => 'Will the event happen?'],
        'options' => [
            ['fa' => 'بله', 'en' => 'Yes'],
            ['fa' => 'خیر', 'en' => 'No'],
        ],
        'opens_at' => '2026-09-01T00:00:00Z',
        'closes_at' => '2026-09-03T00:00:00Z',
        'reveal_closes_at' => '2026-09-04T00:00:00Z',
        'evidence_cutoff_at' => '2026-09-05T00:00:00Z',
        'sources' => [[
            'url' => 'https://example.com/public-result',
            'content' => 'Public evidence content.',
        ]],
    ];
}

test('an operator records a structured advisory review and evidence hashes', function () {
    $reviewer = Mockery::mock(PublicContentReviewer::class);
    $reviewer->shouldReceive('review')->once()->andReturn([
        'decision' => 'approved',
        'reason_codes' => ['clear_outcomes'],
        'confidence' => 0.91,
        'cited_sources' => ['https://example.com/public-result'],
        'model_id' => 'local-reviewer-v1',
        'prompt_hash' => str_repeat('cd', 48),
    ]);
    app()->instance(PublicContentReviewer::class, $reviewer);

    $response = $this->actingAs(User::factory()->create())
        ->postJson(route('api.market-reviews.store'), validMarketReviewPayload());

    $response->assertCreated()
        ->assertJsonPath('data.decision', 'approved')
        ->assertJsonPath('data.confidence_basis_points', 9100)
        ->assertJsonPath('escrow_action', 'release_to_treasury')
        ->assertJsonPath('settlement_authorized', false)
        ->assertJsonMissingPath('transaction')
        ->assertJsonMissingPath('sources.0.content');

    expect(MarketReview::query()->count())->toBe(1)
        ->and(OracleEvidence::query()->count())->toBe(1)
        ->and(OracleEvidence::query()->sole()->content_hash)
        ->toBe(hash('sha384', 'Public evidence content.'));
});

test('provider failure produces the full refund action and cannot authorize settlement', function () {
    $reviewer = Mockery::mock(PublicContentReviewer::class);
    $reviewer->shouldReceive('review')->once()->andThrow(new RuntimeException('offline'));
    app()->instance(PublicContentReviewer::class, $reviewer);

    $this->actingAs(User::factory()->create())
        ->postJson(route('api.market-reviews.store'), validMarketReviewPayload())
        ->assertCreated()
        ->assertJsonPath('data.decision', 'provider_failure')
        ->assertJsonPath('escrow_action', 'refund_100_percent')
        ->assertJsonPath('settlement_authorized', false);
});

test('review rejects unsafe ambiguous or inconsistent public market terms before calling a provider', function () {
    $reviewer = Mockery::mock(PublicContentReviewer::class);
    $reviewer->shouldNotReceive('review');
    app()->instance(PublicContentReviewer::class, $reviewer);

    $payload = validMarketReviewPayload();
    $payload['question']['en'] = '<script>alert(1)</script>';
    $payload['options'][1]['en'] = 'Yes';
    $payload['closes_at'] = '2026-08-01T00:00:00Z';
    $payload['sources'] = [];

    $this->actingAs(User::factory()->create())
        ->postJson(route('api.market-reviews.store'), $payload)
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['content', 'options', 'closes_at', 'sources']);

    expect(MarketReview::query()->count())->toBe(0);
});

test('anonymous protocol users cannot submit moderation decisions', function () {
    $this->postJson(route('api.market-reviews.store'), validMarketReviewPayload())
        ->assertUnauthorized();

    $this->actingAs(User::factory()->nonOperator()->create())
        ->postJson(route('api.market-reviews.store'), validMarketReviewPayload())
        ->assertForbidden();
});
