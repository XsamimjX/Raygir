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
        Schema::create('clob_settlement_batches', function (Blueprint $table) {
            $table->id();
            $table->char('batch_id', 64)->unique();
            $table->char('previous_root', 64);
            $table->char('next_root', 64)->nullable();
            $table->unsignedBigInteger('sequence');
            $table->unsignedTinyInteger('match_count');
            $table->unsignedBigInteger('settlement_time');
            $table->longText('encrypted_witness')->nullable();
            $table->longText('proof')->nullable();
            $table->jsonb('public_inputs')->nullable();
            $table->char('transaction_hash', 64)->nullable();
            $table->unsignedBigInteger('confirmed_block_number')->nullable();
            $table->char('confirmed_block_hash', 64)->nullable();
            $table->string('status', 24)->default('queued');
            $table->text('last_error')->nullable();
            $table->timestampTz('witness_erased_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clob_settlement_batches');
    }
};
