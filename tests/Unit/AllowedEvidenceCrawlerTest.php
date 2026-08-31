<?php

use App\Services\Oracle\AllowedEvidenceCrawler;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

uses(TestCase::class);

test('it fetches only public allowlisted evidence and returns a reproducible hash', function () {
    Http::preventStrayRequests();
    Http::fake([
        'https://news.example/result' => Http::response('official public result'),
    ]);
    config()->set('services.evidence.allowed_hosts', ['news.example']);

    $evidence = app(AllowedEvidenceCrawler::class)->crawl(
        ['https://news.example/result'],
        now()->addHour(),
    );

    expect($evidence)->toHaveCount(1)
        ->and($evidence[0]['content_hash'])->toBe(hash('sha384', 'official public result'));
    Http::assertSentCount(1);
});

test('it rejects non https and non allowlisted sources before making a request', function (string $url) {
    Http::preventStrayRequests();
    config()->set('services.evidence.allowed_hosts', ['news.example']);

    expect(fn () => app(AllowedEvidenceCrawler::class)->crawl([$url], now()->addHour()))
        ->toThrow(RuntimeException::class, 'not allowlisted');
    Http::assertNothingSent();
})->with([
    'plain HTTP' => 'http://news.example/result',
    'unknown host' => 'https://private.example/result',
    'IP literal' => 'https://127.0.0.1/result',
]);

test('it refuses to collect evidence after the declared cutoff', function () {
    Http::preventStrayRequests();
    config()->set('services.evidence.allowed_hosts', ['news.example']);

    expect(fn () => app(AllowedEvidenceCrawler::class)->crawl(
        ['https://news.example/result'],
        Carbon::now()->subSecond(),
    ))->toThrow(RuntimeException::class, 'cutoff');
    Http::assertNothingSent();
});
