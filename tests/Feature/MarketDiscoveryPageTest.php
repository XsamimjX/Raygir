<?php

use App\Models\User;
use Illuminate\Session\Middleware\StartSession;
use Inertia\Testing\AssertableInertia as Assert;

test('localized market discovery is public sessionless and contains no fabricated records', function (string $locale, string $direction) {
    $this->get("/{$locale}/markets")
        ->assertOk()
        ->assertCookieMissing(config('session.cookie'))
        ->assertInertia(fn (Assert $page) => $page
            ->component('markets/index')
            ->where('locale', $locale)
            ->where('direction', $direction)
            ->where('auth.user', null)
            ->missing('markets'));
})->with([
    'Persian' => ['fa', 'rtl'],
    'English' => ['en', 'ltr'],
]);

test('operator identity is not exposed on public discovery surfaces', function () {
    $operator = User::factory()->create(['is_operator' => true]);

    $this->actingAs($operator)
        ->get('/fa/markets')
        ->assertInertia(fn (Assert $page) => $page->where('auth.user', null));
});

test('public discovery routes exclude Laravel session middleware', function (string $route) {
    $middleware = app('router')->getRoutes()->getByName($route)?->gatherMiddleware();

    expect($middleware)->not->toContain(StartSession::class);
})->with(['discovery', 'markets']);
