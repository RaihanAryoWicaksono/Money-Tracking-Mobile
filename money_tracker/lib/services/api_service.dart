import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/transaction.dart';

class ApiService {
  static const String baseUrl =
      'http://xxx.xxx.xxx.xxx:8000/api'; // CEK CMD > IPCONFIG >  IPv4 Address
  static const String imageUrl =
      'http://xxx.xxx.xxx.xxx:8000/storage'; // CEK CMD > IPCONFIG >  IPv4 Address

  static Future<List<Transaction>> fetchTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Accept': 'application/json'},
    );
    debugPrint('FETCH STATUS: ${response.statusCode}');
    debugPrint('FETCH BODY: ${response.body}');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Transaction.fromJson(e)).toList();
    } else {
      throw Exception('Gagal load transaksi');
    }
  }

  static Future<void> addTransaction(
    Transaction transaction,
    File? image,
  ) async {
    final uri = Uri.parse('$baseUrl/transactions');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    request.fields['title'] = transaction.title;
    request.fields['amount'] = transaction.amount.toString();
    request.fields['type'] = transaction.type.name;
    request.fields['date'] = transaction.date!.toIso8601String();
    request.fields['location_name'] = transaction.locationName ?? '';

    debugPrint('ADD REQUEST FIELDS: ${request.fields}');

    if (image != null) {
      debugPrint('IMAGE PATH: ${image.path}');

      if (!await image.exists()) {
        throw Exception('File tidak ditemukan di: ${image.path}');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        List<int>? bytes;
        int retries = 3;

        for (int i = 0; i < retries; i++) {
          try {
            bytes = await image.readAsBytes();
            if (bytes.isNotEmpty) break;

            debugPrint('Retry reading file... attempt ${i + 1}');
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          } catch (e) {
            debugPrint('Read attempt ${i + 1} failed: $e');
            if (i == retries - 1) rethrow;
          }
        }

        if (bytes == null || bytes.isEmpty) {
          throw Exception('File kosong atau corrupt');
        }

        final fileSize = bytes.length;
        debugPrint('IMAGE SIZE: $fileSize bytes');

        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Ukuran gambar terlalu besar (max 10MB)');
        }

        String extension = image.path.split('.').last.toLowerCase();
        if (extension.isEmpty ||
            !['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          extension = 'jpg';
        }

        MediaType mediaType;
        switch (extension) {
          case 'png':
            mediaType = MediaType('image', 'png');
            break;
          case 'gif':
            mediaType = MediaType('image', 'gif');
            break;
          default:
            mediaType = MediaType('image', 'jpeg');
        }

        debugPrint('IMAGE EXTENSION: $extension');
        debugPrint('MEDIA TYPE: ${mediaType.mimeType}');

        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename:
              'upload_${DateTime.now().millisecondsSinceEpoch}.$extension',
          contentType: mediaType,
        );

        request.files.add(multipartFile);
        debugPrint('IMAGE ADDED TO REQUEST (${bytes.length} bytes)');
      } catch (e) {
        debugPrint('ERROR PREPARING IMAGE: $e');
        throw Exception('Gagal memproses gambar: $e');
      }
    } else {
      debugPrint('NO IMAGE PROVIDED');
    }

    try {
      debugPrint('SENDING REQUEST...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('ADD STATUS: ${response.statusCode}');
      debugPrint('ADD BODY: ${response.body}');

      if (response.statusCode != 201) {
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('ERROR DETAILS: $errorData');
        } catch (e) {
          debugPrint('Cannot parse error response');
        }
        throw Exception('Gagal upload transaksi: ${response.body}');
      }

      debugPrint('TRANSACTION ADDED SUCCESSFULLY');
    } catch (e) {
      debugPrint('ADD ERROR: $e');
      rethrow;
    }
  }

  static Future<void> updateTransaction(
    String id,
    Transaction transaction,
    File? image,
  ) async {
    final uri = Uri.parse('$baseUrl/transactions/$id');
    debugPrint('UPDATE URL: $uri');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';

    request.fields['_method'] = 'PUT';
    request.fields['title'] = transaction.title;
    request.fields['amount'] = transaction.amount.toString();
    request.fields['type'] = transaction.type.name;
    request.fields['date'] = transaction.date.toIso8601String();
    request.fields['location_name'] = transaction.locationName ?? '';

    debugPrint('UPDATE REQUEST FIELDS: ${request.fields}');

    if (image != null) {
      debugPrint('IMAGE PATH: ${image.path}');

      if (!await image.exists()) {
        throw Exception('File tidak ditemukan di: ${image.path}');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        List<int>? bytes;
        int retries = 3;

        for (int i = 0; i < retries; i++) {
          try {
            bytes = await image.readAsBytes();
            if (bytes.isNotEmpty) break;

            debugPrint('Retry reading file... attempt ${i + 1}');
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          } catch (e) {
            debugPrint('Read attempt ${i + 1} failed: $e');
            if (i == retries - 1) rethrow;
          }
        }

        if (bytes == null || bytes.isEmpty) {
          throw Exception('File kosong atau corrupt');
        }

        final fileSize = bytes.length;
        debugPrint('IMAGE SIZE: $fileSize bytes');

        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Ukuran gambar terlalu besar (max 10MB)');
        }

        String extension = image.path.split('.').last.toLowerCase();
        if (extension.isEmpty ||
            !['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          extension = 'jpg';
        }

        MediaType mediaType;
        switch (extension) {
          case 'png':
            mediaType = MediaType('image', 'png');
            break;
          case 'gif':
            mediaType = MediaType('image', 'gif');
            break;
          default:
            mediaType = MediaType('image', 'jpeg');
        }

        debugPrint('IMAGE EXTENSION: $extension');
        debugPrint('MEDIA TYPE: ${mediaType.mimeType}');

        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename:
              'upload_${DateTime.now().millisecondsSinceEpoch}.$extension',
          contentType: mediaType,
        );

        request.files.add(multipartFile);
        debugPrint('IMAGE ADDED TO REQUEST (${bytes.length} bytes)');
      } catch (e) {
        debugPrint('ERROR PREPARING IMAGE: $e');
        throw Exception('Gagal memproses gambar: $e');
      }
    }

    try {
      debugPrint('SENDING UPDATE REQUEST...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UPDATE STATUS: ${response.statusCode}');
      debugPrint('UPDATE BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Gagal update transaksi: ${response.body}');
      }

      debugPrint('TRANSACTION UPDATED SUCCESSFULLY');
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');
      rethrow;
    }
  }

  static Future<void> deleteTransaction(String id) async {
    final uri = Uri.parse('$baseUrl/transactions/$id');
    debugPrint('=== DELETE TRANSACTION START ===');
    debugPrint('DELETE ID: $id');
    debugPrint('DELETE URL: $uri');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('DELETE STATUS CODE: ${response.statusCode}');
      debugPrint('DELETE RESPONSE BODY: ${response.body}');
      debugPrint('DELETE RESPONSE HEADERS: ${response.headers}');

      // Status 200 atau 204 = success
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('=== DELETE SUCCESS ===');
        return;
      }

      // Jika bukan 200/204, throw error
      String errorMessage = 'Status ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        // Jika tidak bisa parse JSON, gunakan raw body
        errorMessage = response.body;
      }

      throw Exception('Gagal menghapus: $errorMessage');
    } catch (e) {
      debugPrint('=== DELETE ERROR ===');
      debugPrint('ERROR: $e');
      rethrow;
    }
  }
}
