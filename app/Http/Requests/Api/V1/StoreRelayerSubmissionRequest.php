<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRelayerSubmissionRequest extends FormRequest
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
            'nullifier' => [
                'required',
                'string',
                'size:64',
                'regex:/^[a-fA-F0-9]{64}$/',
                Rule::unique('relayer_submissions', 'nullifier'),
            ],
            'proof' => ['required', 'string', 'max:100000'],
            'call_data' => ['required', 'string', 'max:100000', 'regex:/^0x[a-fA-F0-9]+$/'],
            'expires_at' => ['required', 'date', 'after:now'],
        ];
    }
}
