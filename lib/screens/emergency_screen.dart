import 'package:flutter/material.dart';
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

  bool _loading = true;
  String? _name;
  String? _dob;
  String? _bloodType;
  String? _emergencyContact;
  List<AllergyModel> _allergies = [];
  List<MedicationModel> _medications = [];

  @override
  void initState() {
    super.initState();
    _load();
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
      _dob = row['date_of_birth']?.toString();
      _bloodType = row['blood_type']?.toString();
      _emergencyContact =
          '${row['emergency_contact_name'] ?? ''} ${row['emergency_contact_phone'] ?? ''}'.trim();
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('DOB: ${_dob ?? '-'}'),
          Text('Blood type: ${_bloodType ?? '-'}'),
          const SizedBox(height: 20),
          const Text('Allergies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._allergies.map(
                (a) => ListTile(
              title: Text(a.allergenName),
              subtitle: Text('${a.reaction ?? ''} • ${a.severity ?? ''}'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._medications.map(
                (m) => ListTile(
              title: Text(m.medicationName),
              subtitle: Text('${m.dosage ?? ''} • ${m.frequency ?? ''}'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Emergency contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_emergencyContact ?? '-'),
        ],
      ),
    );
  }
}