import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/attendance_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      String sessionId = '';
      String token = '';

      // Try parsing JSON payload from QR
      try {
        final data = jsonDecode(rawCode);
        sessionId = data['sessionId'] ?? '';
        token = data['token'] ?? '';
      } catch (_) {
        // If not standard JSON, check if format is sessionId:token
        final parts = rawCode.split(':');
        if (parts.length >= 2) {
          sessionId = parts[0];
          token = parts[1];
        } else {
          throw 'Invalid QR code format for Smart Attendance';
        }
      }

      if (sessionId.isEmpty || token.isEmpty) {
        throw 'Invalid QR code data';
      }

      final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attProvider.scanQr(sessionId, token);

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(attProvider.errorMessage ?? 'Failed to mark attendance.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 56),
            ).animate().scale(begin: const Offset(0,0), end: const Offset(1,1), duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text(
              'Attendance Marked!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            const Text(
              'Your presence has been recorded and verified successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Back to Dashboard'),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attendance Rejected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _isProcessing = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ).animate().shakeX(amount: 5, duration: 400.ms),
      ),
    );
  }

  // Emulator-friendly manual entry dialog for testing without physical camera
  void _showManualEntryDialog() {
    final sessionController = TextEditingController();
    final tokenController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Code Entry (Testing)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the session ID and token from the teacher QR screen:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sessionController,
              decoration: const InputDecoration(labelText: 'Session ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(labelText: 'Token'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final raw = jsonEncode({
                'sessionId': sessionController.text.trim(),
                'token': tokenController.text.trim(),
              });
              _handleScannedCode(raw);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            tooltip: 'Manual Code Entry',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scan Overlay Frame
          const Center(
            child: AnimatedScanFrame(size: 260, color: AppTheme.primaryLight),
          ),

          // Instruction Text
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Align the dynamic QR code within the frame to authenticate and mark attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}
