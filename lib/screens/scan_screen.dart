import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

/// Halaman untuk scan QR Code menggunakan kamera device.
/// Menggunakan package mobile_scanner untuk live camera preview.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _scanResult;
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Cek apakah hasil scan berupa URL
  bool _isUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Buka URL di browser
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka URL')),
        );
      }
    }
  }

  /// Copy hasil scan ke clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks berhasil disalin!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Tampilkan dialog hasil scan
  void _showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Scan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_isUrl(result)) ...[
              const SizedBox(height: 12),
              Text(
                'URL terdeteksi',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Tombol copy ke clipboard
          TextButton.icon(
            onPressed: () => _copyToClipboard(result),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
          // Tombol buka URL (hanya muncul jika hasil scan berupa URL)
          if (_isUrl(result))
            TextButton.icon(
              onPressed: () => _launchUrl(result),
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Buka URL'),
            ),
          // Tombol scan ulang
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scanResult = null;
                _isScanning = true;
              });
              _scannerController.start();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Scan Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Tombol toggle flash
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          // Tombol switch kamera depan/belakang
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live camera preview untuk scan QR code
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  // Callback saat QR code terdeteksi
                  onDetect: (BarcodeCapture capture) {
                    if (!_isScanning) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final String code = barcodes.first.rawValue!;
                      setState(() {
                        _scanResult = code;
                        _isScanning = false;
                      });
                      _scannerController.stop();
                      _showResultDialog(code);
                    }
                  },
                ),
                // Overlay frame pemindai
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),

          // Panel bawah: instruksi dan hasil terakhir
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                if (_scanResult == null)
                  const Text(
                    'Arahkan kamera ke QR Code untuk memindai',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'Hasil scan terakhir:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                _scanResult!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () => _copyToClipboard(_scanResult!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
