<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transaction_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')
                  ->constrained('transactions')
                  ->onDelete('cascade');
            $table->double('latitude')->nullable()->comment('Koordinat latitude');
            $table->double('longitude')->nullable()->comment('Koordinat longitude');
            $table->string('location_name', 500)->nullable()->comment('Nama lokasi');
            $table->text('notes')->nullable()->comment('Catatan tambahan');
            $table->timestamps();
            
            $table->unique('transaction_id');
            $table->index('transaction_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transaction_details');
    }
};