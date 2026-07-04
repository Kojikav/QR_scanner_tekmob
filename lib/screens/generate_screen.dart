import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Halaman untuk generate QR Code dari teks atau URL yang diinput user.
/// Menggunakan package qr_flutter untuk merender QR code.
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _qrData;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Validasi input dan generate QR code
  void _generateQrCode() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _qrData = _textController.text.trim();
      });
      // Tutup keyboard setelah generate
      FocusScope.of(context).unfocus();
    }
  }

  /// Hapus QR code dan reset input
  void _clearQrCode() {
    setState(() {
      _qrData = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form input teks/URL
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Masukkan teks atau URL',
                  hintText: 'Contoh: https://flutter.dev',
                  prefixIcon: const Icon(Icons.text_fields),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearQrCode,
                        )
                      : null,
                ),
                maxLines: 3,
                minLines: 1,
                // Validasi: input tidak boleh kosong
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Input tidak boleh kosong!';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _generateQrCode(),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Generate
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateQrCode,
                icon: const Icon(Icons.qr_code),
                label: const Text(
                  'Generate QR Code',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tampilkan QR Code hasil generate
            if (_qrData != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // QR Code widget dari package qr_flutter
                      QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 250.0,
                        gapless: true,
                        errorStateBuilder: (context, error) {
                          return const Center(
                            child: Text(
                              'Terjadi kesalahan saat membuat QR Code',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Tampilkan data yang di-encode
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _qrData!,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Tombol copy data ke clipboard
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy teks',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _qrData!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Teks berhasil disalin!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
