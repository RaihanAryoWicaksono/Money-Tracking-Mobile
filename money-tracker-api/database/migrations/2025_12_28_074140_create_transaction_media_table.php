<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transaction_media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')
                  ->constrained('transactions')
                  ->onDelete('cascade');
            $table->string('file_path')->comment('Path file di storage');
            $table->string('file_type', 50)->comment('MIME type file');
            $table->bigInteger('file_size')->comment('Ukuran file dalam bytes');
            $table->string('original_name')->nullable()->comment('Nama file asli');
            $table->timestamps();
            
            $table->index('transaction_id');
            $table->index('file_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transaction_media');
    }
};