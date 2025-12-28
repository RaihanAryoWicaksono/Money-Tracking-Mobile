<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use App\Models\TransactionMedia;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index()
    {
        $transactions = Transaction::with(['detail', 'media'])
            ->latest('date')
            ->get()
            ->map(function ($transaction) {
                // Manually append attributes
                $data = $transaction->toArray();

                // Get first media
                $firstMedia = $transaction->media->first();

                if ($firstMedia) {
                    $data['image_url'] = url('storage/' . ltrim($firstMedia->file_path, '/'));
                    $data['image_path'] = $firstMedia->file_path;
                } else {
                    $data['image_url'] = null;
                    $data['image_path'] = null;
                }

                // Get detail data
                if ($transaction->detail) {
                    $data['location_name'] = $transaction->detail->location_name;
                    $data['latitude'] = $transaction->detail->latitude;
                    $data['longitude'] = $transaction->detail->longitude;
                } else {
                    $data['location_name'] = null;
                    $data['latitude'] = null;
                    $data['longitude'] = null;
                }

                return $data;
            });

        return response()->json($transactions);
    }

    public function store(Request $request)
    {
        Log::info('=== STORE REQUEST START ===');
        Log::info('All Request Data:', $request->all());

        $validator = Validator::make($request->all(), [
            'title' => 'required|string',
            'amount' => 'required|numeric',
            'type' => 'required|in:income,expense',
            'date' => 'required|date',
            'location_name' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image' => 'nullable|file|image|mimes:jpg,jpeg,png,gif|max:10240',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed:', $validator->errors()->toArray());
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();

        try {
            // 1. Simpan transaction utama
            $transaction = Transaction::create([
                'title' => $request->title,
                'amount' => $request->amount,
                'type' => $request->type,
                'date' => $request->date ?? now(),
            ]);

            Log::info('Transaction created with ID: ' . $transaction->id);

            // 2. Simpan detail lokasi (jika ada)
            if ($request->location_name || $request->latitude || $request->longitude) {
                TransactionDetail::create([
                    'transaction_id' => $transaction->id,
                    'latitude' => $request->latitude,
                    'longitude' => $request->longitude,
                    'location_name' => $request->location_name,
                ]);
                Log::info('Transaction detail created');
            }

            // 3. Simpan media/image (jika ada)
            if ($request->hasFile('image') && $request->file('image')->isValid()) {
                $file = $request->file('image');
                $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', $file->getClientOriginalName());
                $filePath = $file->storeAs('transactions', $filename, 'public');

                TransactionMedia::create([
                    'transaction_id' => $transaction->id,
                    'file_path' => $filePath,
                    'file_type' => $file->getMimeType(),
                    'file_size' => $file->getSize(),
                    'original_name' => $file->getClientOriginalName(),
                ]);

                Log::info('Transaction media created: ' . $filePath);
            }

            DB::commit();

            // Load relasi untuk response
            $transaction->load(['detail', 'media']);

            Log::info('=== STORE REQUEST END - SUCCESS ===');
            return response()->json($transaction, 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Store Exception:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'message' => 'Failed to create transaction',
                'errors' => ['general' => [$e->getMessage()]]
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        Log::info('=== UPDATE REQUEST START ===');
        Log::info('Transaction ID: ' . $id);

        $transaction = Transaction::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'title' => 'required|string',
            'amount' => 'required|numeric',
            'type' => 'required|in:income,expense',
            'date' => 'required',
            'location_name' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image' => 'nullable|file|image|mimes:jpg,jpeg,png,gif|max:10240',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed:', $validator->errors()->toArray());
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();

        try {
            // 1. Update transaction utama
            $date = Carbon::parse($request->date)->format('Y-m-d H:i:s');
            $transaction->update([
                'title' => $request->title,
                'amount' => $request->amount,
                'type' => $request->type,
                'date' => $date,
            ]);

            Log::info('Transaction updated');

            // 2. Update atau create detail
            if ($request->location_name || $request->latitude || $request->longitude) {
                $transaction->detail()->updateOrCreate(
                    ['transaction_id' => $transaction->id],
                    [
                        'latitude' => $request->latitude,
                        'longitude' => $request->longitude,
                        'location_name' => $request->location_name,
                    ]
                );
                Log::info('Transaction detail updated');
            }

            // 3. Handle image update
            if ($request->hasFile('image') && $request->file('image')->isValid()) {
                $file = $request->file('image');

                // Hapus media lama
                $oldMedia = $transaction->media()->first();
                if ($oldMedia) {
                    if (Storage::disk('public')->exists($oldMedia->file_path)) {
                        Storage::disk('public')->delete($oldMedia->file_path);
                    }
                    $oldMedia->delete();
                    Log::info('Old media deleted');
                }

                // Upload media baru
                $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', $file->getClientOriginalName());
                $filePath = $file->storeAs('transactions', $filename, 'public');

                TransactionMedia::create([
                    'transaction_id' => $transaction->id,
                    'file_path' => $filePath,
                    'file_type' => $file->getMimeType(),
                    'file_size' => $file->getSize(),
                    'original_name' => $file->getClientOriginalName(),
                ]);

                Log::info('New media created: ' . $filePath);
            }

            DB::commit();

            // Load relasi untuk response
            $transaction->load(['detail', 'media']);

            Log::info('=== UPDATE REQUEST END - SUCCESS ===');

            return response()->json([
                'success' => true,
                'message' => 'Transaksi berhasil diperbarui',
                'data' => $transaction
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Update Exception:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'message' => 'Update failed',
                'errors' => ['general' => [$e->getMessage()]]
            ], 500);
        }
    }

    public function destroy($id)
    {
        Log::info('=== DELETE REQUEST ===');
        Log::info('Transaction ID: ' . $id);

        DB::beginTransaction();

        try {
            $transaction = Transaction::with(['detail', 'media'])->findOrFail($id);

            // Hapus semua file media
            foreach ($transaction->media as $media) {
                if (Storage::disk('public')->exists($media->file_path)) {
                    Storage::disk('public')->delete($media->file_path);
                    Log::info('Media file deleted: ' . $media->file_path);
                }
            }

            // Delete transaction (cascade akan hapus detail dan media dari DB)
            $transaction->delete();

            DB::commit();

            Log::info('Transaction deleted successfully');

            return response()->json([
                'success' => true,
                'message' => 'Transaction deleted successfully'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Delete Exception:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete transaction',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}