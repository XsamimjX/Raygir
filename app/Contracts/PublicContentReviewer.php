<?php

namespace App\Contracts;

interface PublicContentReviewer
{
    /**
     * @param  array<string, mixed>  $publicContent
     * @return array{decision: string, reason_codes: array<int, string>, confidence: float, cited_sources: array<int, string>, model_id: string, prompt_hash: string}
     */
    public function review(array $publicContent): array;
}
