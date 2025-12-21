import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../config/app_config.dart';
import '../data/dummy_transactions.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.xxx.xxx:8000/api'; //Ganti Ke IP Sendiri, CMD > ipconfig > Cari IPv4 Address . . . . . . . . . . : 192.168.xxx.xxx

  static Future<List<Transaction>> fetchTransactions() async {
    if (AppConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List<Transaction>.from(dummyTransactions);
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Transaction.fromJson(e)).toList();
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      throw Exception('Koneksi ke server gagal');
    }
  }

  static Future<void> addTransaction(Transaction transaction) async {
    if (AppConfig.demoMode) {
      dummyTransactions.insert(0, transaction);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Gagal menambah transaksi');
      }
    } catch (e) {
      throw Exception('Koneksi ke server gagal');
    }
  }

  static Future<void> updateTransaction(
    String id,
    Transaction transaction,
  ) async {
    if (AppConfig.demoMode) {
      final index = dummyTransactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        dummyTransactions[index] = transaction;
      }
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui transaksi');
      }
    } catch (e) {
      throw Exception('Koneksi ke server gagal');
    }
  }

  static Future<void> deleteTransaction(String id) async {
    // ===== DEMO MODE =====
    if (AppConfig.demoMode) {
      dummyTransactions.removeWhere((t) => t.id == id);
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus transaksi');
      }
    } catch (e) {
      throw Exception('Koneksi ke server gagal');
    }
  }
}
