<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $firstMedia = $this->media->first();
        
        return [
            'id' => $this->id,
            'title' => $this->title,
            'amount' => $this->amount,
            'type' => $this->type,
            'date' => $this->date,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            
            // Image data
            'image_path' => $firstMedia?->file_path,
            'image_url' => $firstMedia 
                ? url('storage/' . ltrim($firstMedia->file_path, '/'))
                : null,
            
            // Location data
            'latitude' => $this->detail?->latitude,
            'longitude' => $this->detail?->longitude,
            'location_name' => $this->detail?->location_name,
        ];
    }
}