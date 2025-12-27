<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'amount',
        'type',
        'date',
        'latitude',
        'longitude',
        'location_name',
        'image_path',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'date' => 'datetime',
    ];

    protected $appends = ['image_url'];

    public function getImageUrlAttribute()
    {
        if ($this->image_path) {
            // Pastikan path tidak dimulai dengan slash
            $path = ltrim($this->image_path, '/');
            return url('storage/' . $path);
        }
        return null;
    }
}