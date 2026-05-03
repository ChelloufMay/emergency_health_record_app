import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/patient_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _service = MedicationService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<MedicationModel> _medications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _medications = await _service.fetchMedications(_patientId!);

    setState(() => _loading = false);
  }

  Future<void> _addMedication() async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final purposeController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add medication'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medication name')),
              TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage')),
              TextField(controller: frequencyController, decoration: const InputDecoration(labelText: 'Frequency')),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (save != true || _patientId == null || _userId == null) return;

    final item = MedicationModel(
      id: 'temp',
      patientId: _patientId!,
      medicationName: nameController.text.trim(),
      dosage: dosageController.text.trim(),
      frequency: frequencyController.text.trim(),
      purpose: purposeController.text.trim(),
      source: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.saveMedication(
      medication: item,
      performedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _deleteMedication(MedicationModel item) async {
    if (_userId == null) return;

    await _service.deleteMedication(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      medicationName: item.medicationName,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final item = _medications[index];
          return Card(
            child: ListTile(
              title: Text(item.medicationName),
              subtitle: Text('${item.dosage ?? ''} • ${item.frequency ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteMedication(item),
              ),
            ),
          );
        },
      ),
    );
  }
}