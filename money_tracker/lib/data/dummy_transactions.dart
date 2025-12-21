import '../models/transaction.dart';

final List<Transaction> dummyTransactions = [
  Transaction(
    id: '1',
    title: 'Makan Siang',
    amount: 25000,
    date: DateTime.now(),
    type: TransactionType.expense,
    locationName: 'Kantin Kampus',
  ),
  Transaction(
    id: '2',
    title: 'Uang Saku',
    amount: 500000,
    date: DateTime.now(),
    type: TransactionType.income,
    locationName: 'ATM BNI',
  ),
];
