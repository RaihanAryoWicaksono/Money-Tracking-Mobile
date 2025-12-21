<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->double('amount');
            $table->enum('type', ['income', 'expense']);
            $table->double('latitude')->nullable();
            $table->double('longitude')->nullable();
            $table->string('location_name')->nullable();
            $table->timestamps();
        });

    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
