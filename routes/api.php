<?php

use App\Http\Controllers\Api\V1\CredentialCosignController;
use App\Http\Controllers\Api\V1\RelayerSubmissionController;
use Illuminate\Support\Facades\Route;

Route::post('/v1/credentials/co-sign', CredentialCosignController::class)
    ->middleware('throttle:30,1');

Route::post('/v1/relay/submissions', [RelayerSubmissionController::class, 'store'])
    ->middleware('throttle:20,1');
Route::get('/v1/relay/submissions/{relayerSubmission}', [RelayerSubmissionController::class, 'show'])
    ->middleware('throttle:60,1');
