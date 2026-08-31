<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/.well-known/raygir-issuer', function () {
    return response()->json([
        'version' => '1',
        'did' => config('issuer.did'),
        'blind_issue_endpoint' => url('/api/v1/credentials/blind-issue'),
        'challenge_endpoint' => url('/api/v1/eligibility/challenges'),
    ]);
});
