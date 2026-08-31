<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('creator_enforcements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->char('credential_hash', 64);
            $table->string('violation_type', 32);
            $table->char('reason_hash', 96);
            $table->timestampTz('occurred_at');
            $table->timestampTz('banned_until')->nullable();
            $table->timestamps();
            $table->index(['credential_hash', 'occurred_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('creator_enforcements');
    }
};
