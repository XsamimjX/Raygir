<?php

use App\Actions\RecordCreatorViolation;
use App\Models\CreatorEnforcement;
use Illuminate\Support\Carbon;

test('a non malicious upheld violation records a warning without a ban', function () {
    $enforcement = app(RecordCreatorViolation::class)->handle(
        str_repeat('ab', 32),
        RecordCreatorViolation::NonMalicious,
        str_repeat('cd', 48),
    );

    expect($enforcement->banned_until)->toBeNull()
        ->and($enforcement->violation_type)->toBe(RecordCreatorViolation::NonMalicious);
    $this->assertModelExists($enforcement);
});

test('deliberate deception applies thirty days then one year for a repeat within 180 days', function () {
    Carbon::setTestNow('2026-09-01 00:00:00');
    $action = app(RecordCreatorViolation::class);
    $credentialHash = str_repeat('ab', 32);

    $first = $action->handle(
        $credentialHash,
        RecordCreatorViolation::DeliberateDeception,
        str_repeat('cd', 48),
    );
    expect($first->occurred_at->diffInDays($first->banned_until))->toBe(30.0);

    Carbon::setTestNow(now()->addDays(179));
    $repeat = $action->handle(
        $credentialHash,
        RecordCreatorViolation::DeliberateDeception,
        str_repeat('ef', 48),
    );

    expect($repeat->occurred_at->diffInDays($repeat->banned_until))->toBe(365.0)
        ->and(CreatorEnforcement::query()->where('credential_hash', $credentialHash)->count())->toBe(2);
});

test('a deception after the 180 day window starts a new thirty day ban', function () {
    Carbon::setTestNow('2026-09-01 00:00:00');
    $action = app(RecordCreatorViolation::class);
    $credentialHash = str_repeat('ab', 32);
    $action->handle(
        $credentialHash,
        RecordCreatorViolation::DeliberateDeception,
        str_repeat('cd', 48),
    );

    Carbon::setTestNow(now()->addDays(181));
    $later = $action->handle(
        $credentialHash,
        RecordCreatorViolation::DeliberateDeception,
        str_repeat('ef', 48),
    );

    expect($later->occurred_at->diffInDays($later->banned_until))->toBe(30.0);
});
