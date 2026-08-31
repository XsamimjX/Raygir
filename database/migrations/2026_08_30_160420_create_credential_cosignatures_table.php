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
        Schema::create('credential_cosignatures', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('issuer_did', 255);
            $table->string('policy', 100);
            $table->unsignedBigInteger('epoch');
            $table->char('commitment_hash', 64)->unique();
            $table->char('issuer_signature_hash', 96);
            $table->text('raygir_signature');
            $table->timestamps();
            $table->index(['policy', 'epoch']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('credential_cosignatures');
    }
};
