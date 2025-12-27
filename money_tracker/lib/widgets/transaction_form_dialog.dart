import 'dart:io';
import 'package:flutter/material.dart';
import 'package:money_tracker/services/api_service.dart';
import '../models/transaction.dart';

//Maulana
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../pages/pick_location_page.dart';

class TransactionFormDialog extends StatefulWidget {
  final Transaction? transaction;
  final Function(Transaction, File?) onSubmit;

  const TransactionFormDialog({
    super.key,
    this.transaction,
    required this.onSubmit,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TransactionType _selectedType;

  // MAULANA
  double? _latitude;
  double? _longitude;
  String? _locationName;
  File? _image;

  @override
  void initState() {
    super.initState();
    // MAULANA
    _latitude = widget.transaction?.latitude;
    _longitude = widget.transaction?.longitude;
    _locationName = widget.transaction?.locationName;

    _titleController = TextEditingController(
      text: widget.transaction?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(0) ?? '',
    );
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.transaction == null
                    ? 'Tambah Transaksi'
                    : 'Edit Transaksi',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Pemasukan',
                      Icons.arrow_downward,
                      TransactionType.income,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'Pengeluaran',
                      Icons.arrow_upward,
                      TransactionType.expense,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Masukkan angka yang valid';
                  }

                  return null;
                },
              ),

              // MAULANA
              if (_selectedType == TransactionType.expense) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    _locationName ?? 'Pilih Lokasi Pengeluaran',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _pickLocation,
                ),
              ],

              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tambah Foto Bukti'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              Text(
                'Tips: Pastikan foto fokus dan pencahayaan cukup',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              _imagePreview(),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.transaction == null ? 'Tambah' : 'Simpan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // MAULANA
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickLocationPage()),
    );

    if (result == null) return;

    _latitude = result.latitude;
    _longitude = result.longitude;

    final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);

    final place = placemarks.first;

    setState(() {
      _locationName =
          '${place.street}, ${place.subLocality}, ${place.locality}';
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress sedikit untuk stabilitas
        maxWidth: 1920, // Batasi resolusi
        maxHeight: 1920,
      );

      if (picked == null) {
        debugPrint('No image selected');
        return;
      }

      debugPrint('Image picked: ${picked.path}');

      // CRITICAL: Tunggu file benar-benar tersimpan
      await Future.delayed(const Duration(milliseconds: 500));

      final file = File(picked.path);

      // Validasi file exists
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File gambar tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validasi file size
      final fileSize = await file.length();
      debugPrint('Image size: $fileSize bytes');

      if (fileSize == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File gambar kosong, coba ambil foto lagi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validasi file bisa dibaca
      try {
        await file.readAsBytes();
      } catch (e) {
        debugPrint('Cannot read image file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar tidak bisa dibaca, coba lagi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _image = file;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil dipilih'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // FIXED: Method ini sekarang return Widget yang proper
  Widget _imagePreview() {
    // Jika ada image yang baru dipilih
    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _image!,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // Jika ada image dari transaction yang sedang diedit
    if (widget.transaction?.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.transaction!.imageUrl!,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image Load Error: $error');
            debugPrint('Image URL: ${widget.transaction!.imageUrl}');
            return Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Gambar gagal dimuat',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    // Jika tidak ada image sama sekali, return empty widget
    return const SizedBox.shrink();
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    TransactionType type,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[200],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600], size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() != true) return;

    final amount = double.parse(_amountController.text);

    final transaction = Transaction(
      // Generate ID jika baru, gunakan existing ID jika edit
      id:
          widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: amount,
      date: widget.transaction?.date ?? DateTime.now(),
      type: _selectedType,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
      imagePath: widget.transaction?.imagePath,
      imageUrl: widget.transaction?.imageUrl,
    );

    widget.onSubmit(transaction, _image);
  }
}
