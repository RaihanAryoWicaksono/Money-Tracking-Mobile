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
  });

  // MAULANA
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),

      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      locationName: json['location_name'],
    );
  }

  // MAULANA
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }
}
