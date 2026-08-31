<?php

test('public operator registration is unavailable', function () {
    $this->get('/register')->assertNotFound();
});

test('public registration submissions are rejected', function () {
    $this->post('/register', [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
    ])->assertNotFound();

    $this->assertGuest();
});
