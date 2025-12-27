import 'package:money_tracker/config/app_config.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;

  // MAULANA
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? photoUrl;
  final String? imagePath;
  final String? imageUrl;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    // MAULANA
    this.latitude,
    this.longitude,
    this.locationName,
    this.photoUrl,
    this.imagePath,
    this.imageUrl,
  });

  // MAULANA
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(), // Pastikan selalu ada
      title: json['title'] ?? '',
      amount: double.parse(json['amount'].toString()),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.parse(json['date']),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      locationName: json['location_name'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Tambahkan id di toJson juga
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    double? latitude,
    double? longitude,
    String? locationName,
    String? imagePath,
    String? imageUrl,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
