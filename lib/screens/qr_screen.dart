import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// generates a QR code encoding the patient's profile ID
// a scanner would use this ID to look up the emergency data
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _supabase = Supabase.instance.client;

  String? _patientId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatientId();
  }

  Future<void> _loadPatientId() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) {
        setState(() => _errorMessage = 'User not found.');
        return;
      }

      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (profileRow == null) {
        setState(() => _errorMessage =
        'Please complete your profile before generating a QR code.');
        return;
      }

      setState(() => _patientId = profileRow['id'] as String);
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Error: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency QR Code')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Show this to emergency responders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scanning it will open your emergency medical information.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // QR code with a white padded background for readability
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: QrImageView(
                data: _patientId!,
                version: QrVersions.auto,
                size: 250,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Patient ID: $_patientId',
              style:
              const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                'Keep your phone accessible in emergencies. '
                    'You can also screenshot or print this QR and carry it in your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}