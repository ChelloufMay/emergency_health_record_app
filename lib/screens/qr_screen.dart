import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/patient_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _patientService = PatientService();
  bool _loading = true;
  String _data = 'loading...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() {
        _loading = false;
        _data = 'No profile found';
      });
      return;
    }

    _data = 'emergency://patient/${identity.patientId}';
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR code')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: _data,
              size: 220,
            ),
            const SizedBox(height: 20),
            SelectableText(_data),
          ],
        ),
      ),
    );
  }
}