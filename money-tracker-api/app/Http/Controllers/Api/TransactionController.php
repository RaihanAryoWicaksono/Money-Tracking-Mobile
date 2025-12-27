<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
    public function index()
    {
        $transactions = Transaction::latest()->get();

        foreach ($transactions as $transaction) {
            if ($transaction->image_path) {
                \Log::info('Transaction Image:', [
                    'id' => $transaction->id,
                    'image_path' => $transaction->image_path,
                    'image_url' => $transaction->image_url,
                    'file_exists' => Storage::disk('public')->exists($transaction->image_path)
                ]);
            }
        }

        return response()->json($transactions);
    }

    public function store(Request $request)
    {
        Log::info('=== STORE REQUEST START ===');
        Log::info('All Request Data:', $request->all());
        Log::info('All Files:', $request->allFiles());

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            Log::info('Image File Details:', [
                'original_name' => $file->getClientOriginalName(),
                'size' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
                'extension' => $file->getClientOriginalExtension(),
                'is_valid' => $file->isValid(),
                'error' => $file->getError(),
            ]);
        } else {
            Log::info('No image file in request');
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string',
            'amount' => 'required|numeric',
            'type' => 'required|in:income,expense',
            'date' => 'required|date',
            'location_name' => 'nullable|string',
            'image' => 'nullable|file|image|mimes:jpg,jpeg,png,gif|max:10240',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed:', $validator->errors()->toArray());
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $imagePath = null;

        if ($request->hasFile('image') && $request->file('image')->isValid()) {
            try {
                $file = $request->file('image');
                $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', $file->getClientOriginalName());

                // Store dengan path yang jelas
                $imagePath = $file->storeAs('transactions', $filename, 'public');

                Log::info('Image stored:', [
                    'path' => $imagePath,
                    'full_path' => storage_path('app/public/' . $imagePath),
                    'exists' => file_exists(storage_path('app/public/' . $imagePath))
                ]);
            } catch (\Exception $e) {
                Log::error('Image Store Exception:', [
                    'message' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                return response()->json([
                    'message' => 'The image failed to upload.',
                    'errors' => ['image' => [$e->getMessage()]]
                ], 422);
            }
        }

        $transaction = Transaction::create([
            'title' => $request->title,
            'amount' => $request->amount,
            'type' => $request->type,
            'date' => $request->date ?? now(),
            'location_name' => $request->location_name,
            'image_path' => $imagePath,
        ]);

        return response()->json($transaction, 201);
    }

    public function update(Request $request, $id)
    {
        Log::info('=== UPDATE REQUEST START ===');
        Log::info('Transaction ID: ' . $id);
        Log::info('Request Method: ' . $request->method());
        Log::info('All Request Data:', $request->all());
        Log::info('Has Files: ' . ($request->hasFile('image') ? 'YES' : 'NO'));

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            Log::info('Image Details:', [
                'name' => $file->getClientOriginalName(),
                'size' => $file->getSize(),
                'mime' => $file->getMimeType(),
                'extension' => $file->getClientOriginalExtension(),
                'valid' => $file->isValid(),
                'error' => $file->getError(),
                'temp_path' => $file->getPathname(),
            ]);

            if (!is_readable($file->getPathname())) {
                Log::error('File is not readable');
            }

            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mimeType = finfo_file($finfo, $file->getPathname());
            finfo_close($finfo);
            Log::info('Detected MIME type: ' . $mimeType);
        }

        $transaction = Transaction::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'title' => 'required|string',
            'amount' => 'required|numeric',
            'type' => 'required|in:income,expense',
            'date' => 'required',
            'location_name' => 'nullable|string',
            'image' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:10240',
        ], [
            'image.mimes' => 'Format gambar harus jpg, jpeg, png, atau gif',
            'image.max' => 'Ukuran gambar maksimal 10MB',
            'image.file' => 'File yang diupload harus berupa file gambar',
        ]);

        if ($validator->fails()) {
            Log::error('Validation Failed:', $validator->errors()->toArray());
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $date = Carbon::parse($request->date)->format('Y-m-d H:i:s');

            $transaction->title = $request->title;
            $transaction->amount = $request->amount;
            $transaction->type = $request->type;
            $transaction->date = $date;
            $transaction->location_name = $request->location_name;
            $transaction->save();

            Log::info('Basic data updated successfully');

            if ($request->hasFile('image')) {
                $file = $request->file('image');

                if (!$file->isValid()) {
                    $errorMessage = $this->getUploadErrorMessage($file->getError());
                    Log::error('Invalid file: ' . $errorMessage);
                    return response()->json([
                        'message' => 'The image failed to upload.',
                        'errors' => ['image' => [$errorMessage]]
                    ], 422);
                }

                try {
                    // Hapus gambar lama
                    if ($transaction->image_path) {
                        $oldPath = $transaction->image_path;
                        if (Storage::disk('public')->exists($oldPath)) {
                            Storage::disk('public')->delete($oldPath);
                            Log::info('Old image deleted: ' . $oldPath);
                        }
                    }

                    $originalName = $file->getClientOriginalName();
                    $extension = $file->getClientOriginalExtension();
                    $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', pathinfo($originalName, PATHINFO_FILENAME)) . '.' . $extension;

                    Log::info('Attempting to store file: ' . $filename);

                    $path = $file->storeAs('transactions', $filename, 'public');

                    if (!$path) {
                        throw new \Exception('Failed to store file - storeAs returned false');
                    }

                    if (!Storage::disk('public')->exists($path)) {
                        throw new \Exception('File was not saved to storage');
                    }

                    $transaction->image_path = $path;
                    $transaction->save();

                    Log::info('New image stored successfully at: ' . $path);
                    Log::info('File size on disk: ' . Storage::disk('public')->size($path));

                } catch (\Exception $e) {
                    Log::error('Image Upload Exception:', [
                        'message' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                    return response()->json([
                        'message' => 'The image failed to upload.',
                        'errors' => ['image' => ['Storage error: ' . $e->getMessage()]]
                    ], 422);
                }
            }

            Log::info('=== UPDATE REQUEST END ===');

            $transaction->refresh();

            return response()->json([
                'success' => true,
                'message' => 'Transaksi berhasil diperbarui',
                'data' => $transaction
            ], 200);

        } catch (\Exception $e) {
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
    
    try {
        $transaction = Transaction::findOrFail($id);
        
        Log::info('Transaction found:', [
            'title' => $transaction->title,
            'image_path' => $transaction->image_path
        ]);
        
        // Hapus gambar jika ada
        if ($transaction->image_path) {
            if (Storage::disk('public')->exists($transaction->image_path)) {
                Storage::disk('public')->delete($transaction->image_path);
                Log::info('Image deleted: ' . $transaction->image_path);
            }
        }
        
        $transaction->delete();
        Log::info('Transaction deleted successfully');
        
        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully'
        ], 200);
        
    } catch (\Exception $e) {
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

    private function getUploadErrorMessage($errorCode)
    {
        $errors = [
            UPLOAD_ERR_OK => 'No error',
            UPLOAD_ERR_INI_SIZE => 'File exceeds upload_max_filesize in php.ini',
            UPLOAD_ERR_FORM_SIZE => 'File exceeds MAX_FILE_SIZE in HTML form',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'PHP extension stopped file upload',
        ];

        return $errors[$errorCode] ?? 'Unknown upload error';
    }
}