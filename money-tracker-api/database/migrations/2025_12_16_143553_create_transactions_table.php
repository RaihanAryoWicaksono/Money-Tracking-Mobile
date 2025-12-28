<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('title')->comment('Judul transaksi');
            $table->double('amount')->comment('Jumlah uang');
            $table->enum('type', ['income', 'expense'])->comment('Tipe transaksi');
            $table->dateTime('date')->comment('Tanggal transaksi');
            $table->timestamps();
            
            $table->index('type');
            $table->index('date');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};