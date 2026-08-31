<?php

use Illuminate\Session\Middleware\StartSession;
use Inertia\Testing\AssertableInertia as Assert;

test('every bilingual Raygir research surface is public, sessionless, and data honest', function (string $locale, string $surface) {
    $this->get("/{$locale}/{$surface}")
        ->assertOk()
        ->assertCookieMissing(config('session.cookie'))
        ->assertInertia(fn (Assert $page) => $page
            ->component('research-surface')
            ->where('locale', $locale)
            ->where('surface', $surface)
            ->where('auth.user', null)
            ->missing('records'));
})->with([
    ['fa', 'civic'], ['en', 'civic'],
    ['fa', 'prediction'], ['en', 'prediction'],
    ['fa', 'exchange'], ['en', 'exchange'],
    ['fa', 'create'], ['en', 'create'],
    ['fa', 'portfolio'], ['en', 'portfolio'],
    ['fa', 'reports'], ['en', 'reports'],
    ['fa', 'evidence'], ['en', 'evidence'],
    ['fa', 'challenges'], ['en', 'challenges'],
    ['fa', 'refunds'], ['en', 'refunds'],
]);

test('all Raygir research routes exclude session middleware', function (string $surface) {
    $middleware = app('router')->getRoutes()->getByName("raygir.{$surface}")?->gatherMiddleware();

    expect($middleware)->not->toContain(StartSession::class);
})->with(['civic', 'prediction', 'exchange', 'create', 'portfolio', 'reports', 'evidence', 'challenges', 'refunds']);
