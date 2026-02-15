import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/database_service.dart';
import 'add_item_screen.dart';

/// Barcode scanner screen using mobile_scanner package.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScanned;
  Product? _foundProduct;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
            ),
          ),

          // Result area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: _buildResultArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Looking up product...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // Navigate to add screen with barcode pre-filled
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddItemScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Add Manually'),
            ),
          ],
        ),
      );
    }

    if (_foundProduct != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _foundProduct!.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_foundProduct!.brand != null)
            Text(
              _foundProduct!.brand!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          Chip(label: Text('Barcode: ${_foundProduct!.barcode}')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddItemScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Pantry'),
          ),
        ],
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Point camera at a barcode',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Supports EAN-13, UPC-A, Code-128, QR codes',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastScanned) return;

    _lastScanned = barcode;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _foundProduct = null;
    });

    try {
      // 1. Check local cache
      final db = DatabaseService();
      Product? product = await db.findProductByBarcode(barcode);

      if (product != null) {
        setState(() {
          _foundProduct = product;
          _isProcessing = false;
        });
        return;
      }

      // 2. Query backend
      try {
        final response = await ApiClient().getProductByBarcode(barcode);
        product = Product.fromJson(response.data);
        await db.cacheProduct(product);

        setState(() {
          _foundProduct = product;
          _isProcessing = false;
        });
      } catch (_) {
        setState(() {
          _errorMessage =
              'Product not found for barcode: $barcode\n\nYou can add it manually.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error looking up barcode: $e';
        _isProcessing = false;
      });
    }
  }
}
