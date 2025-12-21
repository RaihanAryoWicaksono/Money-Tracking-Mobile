<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;

class TransactionController extends Controller
{
    public function index()
    {
        return response()->json(Transaction::latest()->get());
    }


    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'amount' => 'required|numeric',
            'type' => 'required|in:income,expense',
        ]);

        $transaction = Transaction::create([
            'title' => $request->title,
            'amount' => $request->amount,
            'type' => $request->type,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'location_name' => $request->location_name,
        ]);

        return response()->json($transaction, 201);
    }

    public function update(Request $request, $id)
    {
        $transaction = Transaction::findOrFail($id);
        $transaction->update($request->all());
        return response()->json($transaction);
    }

    public function destroy($id)
    {
        Transaction::findOrFail($id)->delete();
        return response()->json(['message' => 'Deleted']);
    }
}
