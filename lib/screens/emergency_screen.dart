import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// read-only emergency view — shows only what a paramedic needs
// every time this screen opens, a break_glass event is written to audit_logs
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _allergies = [];
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) return;
      final appUserId = userRow['id'] as String;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', appUserId)
          .maybeSingle();

      if (profileRow == null) {
        setState(() => _errorMessage =
        'No profile found. Please complete your profile first.');
        return;
      }

      _profile = profileRow;
      final patientId = profileRow['id'] as String;

      // load allergies and medications in parallel
      final results = await Future.wait([
        _supabase
            .from('allergies')
            .select()
            .eq('patient_id', patientId)
            .order('created_at'),
        _supabase
            .from('medications')
            .select()
            .eq('patient_id', patientId)
            .order('created_at'),
      ]);

      _allergies = List<Map<String, dynamic>>.from(results[0] as List);
      _medications = List<Map<String, dynamic>>.from(results[1] as List);

      // log that the emergency view was opened
      // we wrap this in try-catch so a logging failure never blocks emergency access
      try {
        await _supabase.from('audit_logs').insert({
          'patient_id': patientId,
          'performed_by_user_id': appUserId,
          'action': 'break_glass',
          'entity_type': 'patient_profiles',
          'entity_id': patientId,
          'break_glass_reason': 'Emergency view opened from app',
        });
      } catch (_) {
        // audit failure is not critical here — never block emergency access
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Failed to load data: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // calculates current age from a date of birth string
  int? _calculateAge(String? dobString) {
    if (dobString == null) return null;
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('⚠ Emergency View'),
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // clear warning that this is read-only and logged
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'READ-ONLY — For emergency use only. Access is logged.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // ------------------------------- Identity -------------------------------
            _EmergencySection(
              title: 'Patient',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EmergencyRow(
                    'Name',
                    '${_profile!['first_name']} ${_profile!['family_name']}',
                  ),
                  if (_calculateAge(
                      _profile!['date_of_birth']?.toString()) !=
                      null)
                    _EmergencyRow(
                      'Age',
                      '${_calculateAge(_profile!['date_of_birth']?.toString())} years old',
                    ),
                  if (_profile!['sex'] != null &&
                      _profile!['sex'] != 'unknown')
                    _EmergencyRow('Sex', _profile!['sex']),
                  if (_profile!['blood_type'] != null)
                    _EmergencyRow(
                      'Blood Type',
                      _profile!['blood_type'],
                      highlight: true,
                    ),
                ],
              ),
            ),

            // ------------------------------- Allergies -------------------------------
            _EmergencySection(
              title: 'Allergies',
              child: _allergies.isEmpty
                  ? const Text('None recorded.')
                  : Column(
                children: _allergies.map((a) {
                  final severity =
                  (a['severity'] ?? '') as String;
                  final isSerious = severity
                      .toLowerCase()
                      .contains('severe') ||
                      severity
                          .toLowerCase()
                          .contains('anaphylaxis');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSerious
                          ? Colors.red.shade100
                          : Colors.orange.shade50,
                      borderRadius:
                      BorderRadius.circular(6),
                      border: Border.all(
                        color: isSerious
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isSerious)
                          const Icon(Icons.warning,
                              color: Colors.red, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${a['allergen_name']}${severity.isNotEmpty ? ' — $severity' : ''}',
                            style: TextStyle(
                              fontWeight: isSerious
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ------------------------------- Medications -------------------------------
            _EmergencySection(
              title: 'Current Medications',
              child: _medications.isEmpty
                  ? const Text('None recorded.')
                  : Column(
                children: _medications.map((m) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 4),
                    child: _EmergencyRow(
                      m['medication_name'] ?? '',
                      [
                        if (m['dosage'] != null)
                          m['dosage'],
                        if (m['frequency'] != null)
                          m['frequency'],
                      ].join(' — '),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ------------------------------- Emergency contact -------------------------------
            if (_profile!['emergency_contact_name'] != null ||
                _profile!['emergency_contact_phone'] != null)
              _EmergencySection(
                title: 'Emergency Contact',
                child: Column(
                  children: [
                    if (_profile!['emergency_contact_name'] !=
                        null)
                      _EmergencyRow(
                        'Name',
                        _profile!['emergency_contact_name'],
                      ),
                    if (_profile!['emergency_contact_phone'] !=
                        null)
                      _EmergencyRow(
                        'Phone',
                        _profile!['emergency_contact_phone'],
                        highlight: true,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            const Text(
              'This information is user-entered and may not be clinician-verified. '
                  'Use clinical judgment accordingly.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// card wrapper for each section in the emergency view
class _EmergencySection extends StatelessWidget {
  final String title;
  final Widget child;

  const _EmergencySection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// a single label + value line used inside emergency sections
class _EmergencyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _EmergencyRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? Colors.red.shade800 : null,
                fontWeight: highlight ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}