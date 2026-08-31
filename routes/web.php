<?php

use App\Http\Controllers\Api\V1\MarketReviewController;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\Support\Facades\Route;
use Illuminate\View\Middleware\ShareErrorsFromSession;

Route::redirect('/', '/fa')->name('home');

Route::middleware('locale')->prefix('{locale}')->whereIn('locale', ['fa', 'en'])->group(function () {
    Route::inertia('/', 'welcome')
        ->withoutMiddleware([
            StartSession::class,
            ShareErrorsFromSession::class,
            PreventRequestForgery::class,
        ])
        ->name('discovery');
    Route::inertia('/markets', 'markets/index', ['locale' => fn () => app()->getLocale()])
        ->withoutMiddleware([
            StartSession::class,
            ShareErrorsFromSession::class,
            PreventRequestForgery::class,
        ])
        ->name('markets');
    Route::inertia('/wallet/onboarding', 'wallet/onboarding')
        ->withoutMiddleware([
            StartSession::class,
            ShareErrorsFromSession::class,
            PreventRequestForgery::class,
        ])
        ->name('wallet.onboarding');

    foreach ([
        'civic' => 'civic',
        'prediction' => 'prediction',
        'exchange' => 'exchange',
        'create' => 'create',
        'portfolio' => 'portfolio',
        'reports' => 'reports',
        'evidence' => 'evidence',
        'challenges' => 'challenges',
        'refunds' => 'refunds',
    ] as $path => $surface) {
        Route::inertia("/{$path}", 'research-surface', ['surface' => $surface])
            ->withoutMiddleware([
                StartSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
            ])
            ->name("raygir.{$surface}");
    }
});

Route::middleware(['auth', 'verified', 'operator'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');
    Route::post('api/v1/market-reviews', MarketReviewController::class)
        ->middleware('throttle:10,1')
        ->name('api.market-reviews.store');
});

require __DIR__.'/settings.php';
