<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreRelayerSubmissionRequest;
use App\Models\RelayerSubmission;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class RelayerSubmissionController extends Controller
{
    public function store(StoreRelayerSubmissionRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $submission = RelayerSubmission::create([
            'nullifier' => Str::lower($validated['nullifier']),
            'proof_hash' => hash('sha3-384', $validated['proof']),
            'call_data' => Str::lower($validated['call_data']),
            'expires_at' => $validated['expires_at'],
            'status' => 'pending',
        ]);

        return response()->json([
            'submission_id' => $submission->id,
            'status' => $submission->status,
        ], 202);
    }

    public function show(RelayerSubmission $relayerSubmission): JsonResponse
    {
        return response()->json([
            'submission_id' => $relayerSubmission->id,
            'status' => $relayerSubmission->status,
            'transaction_hash' => $relayerSubmission->transaction_hash,
        ]);
    }
}
