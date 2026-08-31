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
        Schema::create('issuer_root_snapshots', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('policy', 100);
            $table->unsignedBigInteger('epoch');
            $table->string('kind', 20);
            $table->char('root', 96);
            $table->unsignedBigInteger('entry_count');
            $table->char('source_version', 96);
            $table->timestamps();
            $table->unique(['policy', 'epoch', 'kind', 'source_version']);
            $table->index(['policy', 'epoch', 'kind']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('issuer_root_snapshots');
    }
};
