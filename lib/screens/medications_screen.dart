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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _medications = await _service.fetchMedications(_patientId!);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addMedication() async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final purposeController = TextEditingController();

    DateTime? startDate;
    DateTime? endDate;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => startDate = picked);
              }
            }

            Future<void> pickEndDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate ?? (startDate ?? DateTime.now()),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => endDate = picked);
              }
            }

            return AlertDialog(
              title: const Text('Add medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Medication name'),
                    ),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(labelText: 'Dosage'),
                    ),
                    TextField(
                      controller: frequencyController,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                    ),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(_formatDate(startDate)),
                      trailing: TextButton(
                        onPressed: pickStartDate,
                        child: const Text('Pick'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End date'),
                      subtitle: Text(_formatDate(endDate)),
                      trailing: TextButton(
                        onPressed: pickEndDate,
                        child: const Text('Pick'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || _patientId == null || _userId == null) return;

    final medicationName = nameController.text.trim();
    if (medicationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication name is required')),
      );
      return;
    }

    final item = MedicationModel(
      id: 'temp',
      patientId: _patientId!,
      medicationName: medicationName,
      dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
      frequency: frequencyController.text.trim().isEmpty ? null : frequencyController.text.trim(),
      purpose: purposeController.text.trim().isEmpty ? null : purposeController.text.trim(),
      startDate: startDate,
      endDate: endDate,
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
          : _medications.isEmpty
          ? const Center(child: Text('No medications found'))
          : ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final item = _medications[index];
          final details = <String>[
            if (item.dosage != null && item.dosage!.isNotEmpty) 'Dosage: ${item.dosage}',
            if (item.frequency != null && item.frequency!.isNotEmpty) 'Frequency: ${item.frequency}',
            if (item.purpose != null && item.purpose!.isNotEmpty) 'Purpose: ${item.purpose}',
            'Start date: ${_formatDate(item.startDate)}',
            'End date: ${_formatDate(item.endDate)}',
            'Source: ${item.source}',
          ];

          return Card(
            child: ListTile(
              title: Text(item.medicationName),
              subtitle: Text(details.join('\n')),
              isThreeLine: true,
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