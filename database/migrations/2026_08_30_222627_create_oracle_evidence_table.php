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
        Schema::create('oracle_evidence', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->char('market_id', 64);
            $table->text('source_url');
            $table->char('content_hash', 96);
            $table->timestampTz('observed_at');
            $table->timestampTz('evidence_cutoff_at');
            $table->timestamps();
            $table->unique(['market_id', 'content_hash']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('oracle_evidence');
    }
};
