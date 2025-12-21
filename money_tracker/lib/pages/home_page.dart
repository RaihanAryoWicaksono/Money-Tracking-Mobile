import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_form_dialog.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await ApiService.fetchTransactions();
      setState(() {
        _transactions
          ..clear()
          ..addAll(data);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  double get totalBalance {
    return _transactions.fold(0, (sum, t) {
      return t.type == TransactionType.income ? sum + t.amount : sum - t.amount;
    });
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _addTransaction(Transaction transaction) async {
    await ApiService.addTransaction(transaction);
    await _loadTransactions();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    await ApiService.deleteTransaction(transaction.id);
    setState(() {
      _transactions.removeWhere((t) => t.id == transaction.id);
    });
  }

  void _updateTransaction(String id, Transaction updatedTransaction) async {
    await ApiService.updateTransaction(id, updatedTransaction);
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayo Menabung'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          BalanceCard(
            totalBalance: totalBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _transactions.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];

                      return TransactionCard(
                        transaction: t,
                        onEdit: (updated) {
                          _updateTransaction(t.id, updated);
                        },
                        onDelete: () {
                          _deleteTransaction(t);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: TransactionFormDialog(
          onSubmit: (transaction) async {
            await _addTransaction(transaction);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
}
