import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';

class OrderScannerScreen extends ConsumerStatefulWidget {
  const OrderScannerScreen({super.key});

  @override
  ConsumerState<OrderScannerScreen> createState() => _OrderScannerScreenState();
}

class _OrderScannerScreenState extends ConsumerState<OrderScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isNavigating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => _isNavigating = true);
        _handleScannedCode(code);
        break;
      }
    }
  }

  void _handleScannedCode(String code) {
    // Attempt to find the order among shop orders
    final orders = ref.read(orderProvider).activeOrders;
    
    // Scanned code could be full ID or the last few characters
    final order = orders.where((o) => 
      o.id == code || 
      o.id.endsWith(code) || 
      (o.pickupCode.isNotEmpty && o.pickupCode == code)
    ).firstOrNull;

    if (order != null) {
      Navigator.pushReplacementNamed(
        context, 
        '/owner-order-details', 
        arguments: order
      );
    } else {
      setState(() => _isNavigating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order not found: $code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Order QR'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.white);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                   // Corners (optional aesthetics)
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point camera at the Order QR code',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
