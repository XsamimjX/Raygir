<?php

namespace App\Services\Oracle;

use Carbon\CarbonInterface;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class AllowedEvidenceCrawler
{
    /**
     * @param  array<int, string>  $urls
     * @return array<int, array{url: string, content_hash: string, content: string, observed_at: string}>
     */
    public function crawl(array $urls, CarbonInterface $evidenceCutoff): array
    {
        if (now()->isAfter($evidenceCutoff)) {
            throw new RuntimeException('Evidence cutoff has passed.');
        }

        $allowedHosts = config('services.evidence.allowed_hosts', []);
        if (! is_array($allowedHosts) || $allowedHosts === []) {
            throw new RuntimeException('No evidence hosts are allowlisted.');
        }

        return collect($urls)->unique()->map(function (string $url) use ($allowedHosts): array {
            $scheme = parse_url($url, PHP_URL_SCHEME);
            $host = parse_url($url, PHP_URL_HOST);
            if ($scheme !== 'https' || ! is_string($host) || ! in_array(mb_strtolower($host), $allowedHosts, true)) {
                throw new RuntimeException('Evidence URL is not allowlisted.');
            }

            try {
                $response = Http::accept('text/plain, application/json')
                    ->connectTimeout(3)
                    ->timeout(15)
                    ->retry([200, 500])
                    ->get($url)
                    ->throw();
            } catch (ConnectionException|RequestException $exception) {
                throw new RuntimeException('Evidence source failed.', previous: $exception);
            }

            $content = $response->body();
            if ($content === '' || strlen($content) > 1_000_000) {
                throw new RuntimeException('Evidence body is empty or too large.');
            }

            return [
                'url' => $url,
                'content_hash' => hash('sha384', $content),
                'content' => $content,
                'observed_at' => now()->toIso8601String(),
            ];
        })->values()->all();
    }
}
