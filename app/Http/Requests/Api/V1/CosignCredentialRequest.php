<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class CosignCredentialRequest extends FormRequest
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
            'issuer_did' => ['required', 'string', 'max:255'],
            'policy' => ['required', 'string', 'max:100', 'regex:/^[a-z0-9._-]+$/'],
            'epoch' => ['required', 'integer', 'min:0'],
            'blinded_commitment' => ['required', 'string', 'size:64', 'regex:/^[a-fA-F0-9]{64}$/'],
            'issuer_signature' => ['required', 'string', 'max:200'],
        ];
    }
}
