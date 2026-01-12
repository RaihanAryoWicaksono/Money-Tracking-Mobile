<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TransactionMedia extends Model
{
    use HasFactory;

    protected $fillable = [
        'transaction_id',
        'file_path',
        'file_type',
        'file_size',
        'original_name',
    ];

    protected $casts = [
        'file_size' => 'integer',
    ];

    public function transaction()
    {
        return $this->belongsTo(Transaction::class);
    }

    public function getFileUrlAttribute(): string
    {
        return url('storage/' . ltrim($this->file_path, '/'));
    }
}