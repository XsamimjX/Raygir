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
        Schema::create('market_reviews', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->char('market_id', 64);
            $table->string('decision', 32);
            $table->unsignedSmallInteger('confidence_basis_points')->nullable();
            $table->jsonb('reason_codes');
            $table->jsonb('cited_sources');
            $table->string('model_id', 160)->nullable();
            $table->char('public_payload_hash', 96);
            $table->char('prompt_hash', 96);
            $table->unsignedSmallInteger('schema_version')->default(1);
            $table->timestampTz('reviewed_at');
            $table->timestamps();
            $table->index(['market_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('market_reviews');
    }
};
