<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class IssueCredentialRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'challenge_id' => ['required', 'uuid'],
            'challenge' => ['required', 'string', 'max:200'],
            'policy' => [
                'required',
                'string',
                'max:100',
                Rule::in(array_keys(config('issuer.policies'))),
            ],
            'blinded_commitment' => ['required', 'string', 'size:64', 'regex:/^[a-fA-F0-9]{64}$/'],
        ];
    }
}
