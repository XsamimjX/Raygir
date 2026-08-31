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
        Schema::create('issued_credentials', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('eligibility_challenge_id')
                ->constrained()
                ->cascadeOnDelete();
            $table->string('policy', 100);
            $table->unsignedBigInteger('epoch');
            $table->char('commitment_hash', 64)->unique();
            $table->text('issuer_signature');
            $table->timestampTz('revoked_at')->nullable();
            $table->timestamps();
            $table->index(['policy', 'epoch']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('issued_credentials');
    }
};
