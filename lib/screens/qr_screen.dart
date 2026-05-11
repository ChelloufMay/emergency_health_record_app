import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/patient_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _patientService = PatientService();
  final _supabase = Supabase.instance.client;

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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _data = 'No profile found';
      });
      return;
    }

    try {
      // Use a token-based QR instead of raw patient ID.
      // This matches the emergency_access_tokens table and makes the QR safer.
      final existingToken = await _supabase
          .from('emergency_access_tokens')
          .select('token')
          .eq('patient_id', identity.patientId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .maybeSingle();

      String token;

      if (existingToken != null && existingToken['token'] != null) {
        token = existingToken['token'].toString();
      } else {
        final inserted = await _supabase
            .from('emergency_access_tokens')
            .insert({
          'patient_id': identity.patientId,
          'created_by_user_id': identity.appUserId,
          'is_active': true,
        }).select('token').single();

        token = inserted['token'].toString();
      }

      // Keep the custom scheme you already chose.
      // The deep-link route handler in the native app must map this to the emergency screen.
      _data = 'healthapp://emergency/$token';

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _data = 'Failed to load QR: $e';
      });
    }
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