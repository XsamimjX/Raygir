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
        Schema::create('clob_orders', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->char('order_hash', 64)->unique();
            $table->char('market_id', 64);
            $table->decimal('token_id', total: 78, places: 0);
            $table->string('side', 4);
            $table->text('encrypted_envelope');
            $table->string('status', 16)->default('open');
            $table->timestampTz('expires_at');
            $table->timestamps();
            $table->index(['market_id', 'token_id', 'side', 'status'], 'clob_orders_book_index');
            $table->index(['status', 'expires_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clob_orders');
    }
};
