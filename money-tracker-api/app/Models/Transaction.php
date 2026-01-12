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

    protected $appends = [
        'image_url',
        'image_path',
        'location_name',
        'latitude',
        'longitude'
    ];

    public function detail()
    {
        return $this->hasOne(TransactionDetail::class);
    }

    public function media()
    {
        return $this->hasMany(TransactionMedia::class);
    }

    public function getImageUrlAttribute(): ?string
    {
        $firstMedia = $this->media->first();
        if ($firstMedia && $firstMedia->file_path) {
            $path = ltrim($firstMedia->file_path, '/');
            return url('storage/' . $path);
        }
        return null;
    }

    public function getImagePathAttribute(): ?string
    {
        $firstMedia = $this->media->first();
        return $firstMedia?->file_path;
    }

    public function getLocationNameAttribute(): ?string
    {
        return $this->detail?->location_name;
    }

    public function getLatitudeAttribute(): ?float
    {
        return $this->detail?->latitude;
    }

    public function getLongitudeAttribute(): ?float
    {
        return $this->detail?->longitude;
    }

    public function scopeIncome($query)
    {
        return $query->where('type', 'income');
    }

    public function scopeExpense($query)
    {
        return $query->where('type', 'expense');
    }
}