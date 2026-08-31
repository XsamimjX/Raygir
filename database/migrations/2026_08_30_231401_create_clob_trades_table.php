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
        Schema::create('clob_trades', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->char('market_id', 64);
            $table->decimal('token_id', total: 78, places: 0);
            $table->char('buy_order_hash', 64);
            $table->char('sell_order_hash', 64);
            $table->decimal('amount', total: 78, places: 0);
            $table->decimal('price', total: 78, places: 0);
            $table->string('settlement_status', 16)->default('pending');
            $table->char('settlement_root', 64)->nullable();
            $table->timestampTz('matched_at');
            $table->timestamps();
            $table->index(['market_id', 'token_id', 'id']);
            $table->index(['settlement_status', 'id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clob_trades');
    }
};
