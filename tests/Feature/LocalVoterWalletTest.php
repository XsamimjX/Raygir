<?php

use App\Models\User;
use Illuminate\Session\Middleware\StartSession;
use Inertia\Testing\AssertableInertia as Assert;

test('localized voter wallet onboarding is public and sessionless', function (string $locale, string $direction) {
    $this->get("/{$locale}/wallet/onboarding")
        ->assertOk()
        ->assertCookieMissing(config('session.cookie'))
        ->assertInertia(fn (Assert $page) => $page
            ->component('wallet/onboarding')
            ->where('locale', $locale)
            ->where('direction', $direction)
            ->where('auth.user', null));
})->with([
    'Persian' => ['fa', 'rtl'],
    'English' => ['en', 'ltr'],
]);

test('operator identity is not exposed to the voter wallet route', function () {
    $operator = User::factory()->create(['is_operator' => true]);

    $this->actingAs($operator)
        ->get('/fa/wallet/onboarding')
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('auth.user', null));
});

test('voter wallet route excludes Laravel session middleware', function () {
    $middleware = app('router')->getRoutes()->getByName('wallet.onboarding')?->gatherMiddleware();

    expect($middleware)->not->toContain(StartSession::class);
});
