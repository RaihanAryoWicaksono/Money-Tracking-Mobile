<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'amount',
        'type',
        'date',
    ];

    protected $casts = [
        'amount' => 'double',
        'date' => 'datetime',
    ];

    // PENTING: Tambahkan accessor ini ke appends
    protected $appends = [
        'image_url',
        'image_path',
        'location_name',
        'latitude',
        'longitude'
    ];

    /**
     * Relasi ke transaction_details (One-to-One)
     */
    public function detail()
    {
        return $this->hasOne(TransactionDetail::class);
    }

    /**
     * Relasi ke transaction_media (One-to-Many)
     */
    public function media()
    {
        return $this->hasMany(TransactionMedia::class);
    }

    /**
     * Accessor untuk image_url (ambil media pertama)
     */
    public function getImageUrlAttribute(): ?string
    {
        $firstMedia = $this->media->first();
        if ($firstMedia && $firstMedia->file_path) {
            $path = ltrim($firstMedia->file_path, '/');
            return url('storage/' . $path);
        }
        return null;
    }

    /**
     * Accessor untuk image_path (backward compatibility)
     */
    public function getImagePathAttribute(): ?string
    {
        $firstMedia = $this->media->first();
        return $firstMedia?->file_path;
    }

    /**
     * Accessor untuk location_name
     */
    public function getLocationNameAttribute(): ?string
    {
        return $this->detail?->location_name;
    }

    /**
     * Accessor untuk latitude
     */
    public function getLatitudeAttribute(): ?float
    {
        return $this->detail?->latitude;
    }

    /**
     * Accessor untuk longitude
     */
    public function getLongitudeAttribute(): ?float
    {
        return $this->detail?->longitude;
    }

    /**
     * Scope untuk filter by type
     */
    public function scopeIncome($query)
    {
        return $query->where('type', 'income');
    }

    public function scopeExpense($query)
    {
        return $query->where('type', 'expense');
    }
}