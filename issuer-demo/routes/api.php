<?php

use App\Http\Controllers\Api\V1\EligibilityController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:60,1')->group(function (): void {
    Route::post('eligibility/challenges', [EligibilityController::class, 'challenge']);
    Route::post('credentials/blind-issue', [EligibilityController::class, 'issue']);
    Route::get('eligibility-policies/{policy}', [EligibilityController::class, 'policy']);
    Route::get('issuer-roots/{policy}/{epoch}', [EligibilityController::class, 'issuerRoot']);
    Route::get('revocation-roots/{policy}/{epoch}', [EligibilityController::class, 'revocationRoot']);
});
