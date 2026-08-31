<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreMarketReviewRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()?->is_operator === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'market_id' => ['required', 'regex:/^[a-f0-9]{64}$/'],
            'question' => ['required', 'array:fa,en'],
            'question.fa' => ['required', 'string', 'max:500'],
            'question.en' => ['required', 'string', 'max:500'],
            'options' => ['required', 'array', 'min:2', 'max:8'],
            'options.*' => ['required', 'array:fa,en'],
            'options.*.fa' => ['required', 'string', 'max:240'],
            'options.*.en' => ['required', 'string', 'max:240'],
            'opens_at' => ['required', 'date'],
            'closes_at' => ['required', 'date', 'after:opens_at'],
            'reveal_closes_at' => ['required', 'date', 'after_or_equal:closes_at'],
            'evidence_cutoff_at' => ['required', 'date', 'after_or_equal:closes_at'],
            'sources' => ['required', 'array', 'min:1', 'max:20'],
            'sources.*' => ['required', 'array:url,content'],
            'sources.*.url' => ['required', 'url:http,https', 'max:2048', 'distinct'],
            'sources.*.content' => ['required', 'string', 'max:50000'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            $texts = [
                data_get($this->all(), 'question.fa'),
                data_get($this->all(), 'question.en'),
                ...collect($this->input('options', []))->flatMap(fn (mixed $option): array => is_array($option)
                    ? [$option['fa'] ?? null, $option['en'] ?? null]
                    : [null])->all(),
            ];

            foreach ($texts as $text) {
                if (is_string($text) && $text !== strip_tags($text)) {
                    $validator->errors()->add('content', 'HTML is not allowed in public market content.');
                    break;
                }
            }

            foreach (['fa', 'en'] as $locale) {
                $normalized = collect($this->input('options', []))
                    ->pluck($locale)
                    ->filter(fn (mixed $value): bool => is_string($value))
                    ->map(fn (string $value): string => mb_strtolower(trim($value)));

                if ($normalized->unique()->count() !== $normalized->count()) {
                    $validator->errors()->add('options', "Options must be distinct in {$locale}.");
                }
            }
        }];
    }
}
