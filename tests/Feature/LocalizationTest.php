<?php

use Inertia\Testing\AssertableInertia as Assert;

test('the root redirects to the default Persian discovery page', function () {
    $this->get('/')->assertRedirect('/fa');
});

test('localized discovery pages expose their locale and direction', function (string $locale, string $direction) {
    $this->get("/{$locale}")
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->component('welcome')
            ->where('locale', $locale)
            ->where('direction', $direction));
})->with([
    'Persian' => ['fa', 'rtl'],
    'English' => ['en', 'ltr'],
]);

test('unsupported locales are not routed', function () {
    $this->get('/de')->assertNotFound();
});
