<?php

use App\Models\User;

test('operators can access the administration dashboard', function () {
    $operator = User::factory()->create();

    $this->actingAs($operator)->get('/dashboard')->assertOk();
});

test('anonymous protocol users cannot access the administration dashboard', function () {
    $user = User::factory()->nonOperator()->create();

    $this->actingAs($user)->get('/dashboard')->assertForbidden();
});

test('guests are redirected to operator authentication', function () {
    $this->get('/dashboard')->assertRedirect('/login');
});
