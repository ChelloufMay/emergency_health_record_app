import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergy_model.dart';
import '../models/medication_model.dart';
import '../services/allergy_service.dart';
import '../services/medication_service.dart';
import '../services/patient_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _patientService = PatientService();
  final _allergyService = AllergyService();
  final _medicationService = MedicationService();
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _name;
  String? _dob;
  String? _age;
  String? _bloodType;
  String? _emergencyContact;
  String? _addressSummary;
  List<AllergyModel> _allergies = [];
  List<MedicationModel> _medications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _formatDobAndAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age.toString();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _buildAddressSummary(Map<String, dynamic>? row) {
    if (row == null) return null;

    final parts = <String>[
      row['country']?.toString().trim() ?? '',
      row['governorate']?.toString().trim() ?? '',
      row['city']?.toString().trim() ?? '',
      row['avenue']?.toString().trim() ?? '',
      row['street']?.toString().trim() ?? '',
      row['postal_code']?.toString().trim() ?? '',
      row['extra_details']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final row = await _patientService.fetchPatientProfile(identity.patientId);

    if (row != null) {
      _name = '${row['first_name'] ?? ''} ${row['family_name'] ?? ''}'.trim();

      final dobRaw = row['date_of_birth']?.toString();
      final dob = dobRaw == null || dobRaw.isEmpty
          ? null
          : DateTime.tryParse(dobRaw);

      _dob = dob == null ? null : _formatDate(dob);
      _age = _formatDobAndAge(dob);

      _bloodType = row['blood_type']?.toString();
      _emergencyContact =
          '${row['emergency_contact_name'] ?? ''} ${row['emergency_contact_phone'] ?? ''}'
              .trim();

      // Address is stored separately in public.addresses, so load it explicitly.
      final addressId = row['address_id']?.toString();
      if (addressId != null && addressId.isNotEmpty) {
        final addressRow = await _supabase
            .from('addresses')
            .select()
            .eq('id', addressId)
            .maybeSingle();

        _addressSummary = _buildAddressSummary(addressRow);
      }
    }

    _allergies = await _allergyService.fetchAllergies(identity.patientId);
    _medications = await _medicationService.fetchMedications(identity.patientId);

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency view')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('DOB: ${_dob ?? '-'}'),
          Text('Age: ${_age ?? '-'}'),
          Text('Blood type: ${_bloodType ?? '-'}'),
          const SizedBox(height: 12),
          Text(
            'Address: ${_addressSummary ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          const Text(
            'Allergies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_allergies.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No allergies recorded'),
            )
          else
            ..._allergies.map(
                  (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.allergenName),
                subtitle: Text(
                  [
                    if ((a.reaction ?? '').trim().isNotEmpty) a.reaction!,
                    if ((a.severity ?? '').trim().isNotEmpty) a.severity!,
                  ].join(' • '),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Medications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_medications.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No medications recorded'),
            )
          else
            ..._medications.map(
                  (m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.medicationName),
                subtitle: Text(
                  [
                    if ((m.dosage ?? '').trim().isNotEmpty) m.dosage!,
                    if ((m.frequency ?? '').trim().isNotEmpty) m.frequency!,
                  ].join(' • '),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Emergency contact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(_emergencyContact ?? '-'),
        ],
      ),
    );
  }
}