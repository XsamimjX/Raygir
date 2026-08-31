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
        Schema::create('relayer_submissions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->char('nullifier', 64)->unique();
            $table->char('proof_hash', 96);
            $table->text('call_data');
            $table->timestampTz('expires_at');
            $table->string('status', 20)->default('pending')->index();
            $table->char('transaction_hash', 64)->nullable()->unique();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('relayer_submissions');
    }
};
