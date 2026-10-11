
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'emergency_qr_scanner_screen.dart';

class EmergencyQrScannerScreen extends StatefulWidget {
  const EmergencyQrScannerScreen({super.key});

  @override
  State<EmergencyQrScannerScreen> createState() =>
      _EmergencyQrScannerScreenState();
}

class _EmergencyQrScannerScreenState
    extends State<EmergencyQrScannerScreen> {
  String? scannedText;
  bool alreadyScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (alreadyScanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        alreadyScanned = true;

        setState(() {
          scannedText = value;
        });

        break;
      }
    }
  }

  void _scanAgain() {
    setState(() {
      scannedText = null;
      alreadyScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00897B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Emergency QR'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
      ),
      body: scannedText == null
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Point the camera at the patient’s '
                    'LifePlus Emergency QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Camera unavailable.\n'
                                'Allow camera permission and try again.\n\n'
                                '${error.errorCode.name}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Works offline for QR codes containing text.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : SafeArea(
              child: SingleChildScrollView(   
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      color: teal,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency Information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectableText(
                        scannedText!,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This information was read from the QR code. '
                      'It has not been verified medically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _scanAgain,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Another QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
