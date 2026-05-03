import 'package:flutter/material.dart';
import '../models/vaccination_model.dart';
import '../services/patient_service.dart';
import '../services/vaccination_service.dart';
import '../widgets/verification_badge.dart';

class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final _service = VaccinationService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<VaccinationModel> _items = [];

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
    _items = await _service.fetchVaccinations(_patientId!);
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final dateController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'other';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add vaccination'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Vaccine name')),
                TextField(controller: doseController, decoration: const InputDecoration(labelText: 'Dose number')),
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date administered (YYYY-MM-DD)')),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: const [
                    DropdownMenuItem(value: 'covid', child: Text('COVID')),
                    DropdownMenuItem(value: 'pnv', child: Text('PNV')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setStateDialog(() => category = v ?? 'other'),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok != true || _patientId == null || _userId == null) return;

    final item = VaccinationModel(
      id: 'temp',
      patientId: _patientId!,
      vaccineName: nameController.text.trim(),
      category: category,
      doseNumber: int.tryParse(doseController.text.trim()),
      dateAdministered: dateController.text.trim().isEmpty ? null : DateTime.tryParse(dateController.text.trim()),
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _service.saveVaccination(
      vaccination: item,
      performedByUserId: _userId!,
    );
    await _load();
  }

  Future<void> _deleteItem(VaccinationModel item) async {
    if (_patientId == null || _userId == null) return;
    await _service.deleteVaccination(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      vaccineName: item.vaccineName,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              title: Row(
                children: [
                  Expanded(child: Text(item.vaccineName)),
                  const SizedBox(width: 8),
                  const VerificationBadge(status: 'user_entered'),
                ],
              ),
              subtitle: Text(
                '${item.category}'
                    '${item.doseNumber != null ? ' • dose ${item.doseNumber}' : ''}'
                    '${item.dateAdministered != null ? '\n${item.dateAdministered!.toIso8601String().split("T").first}' : ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteItem(item),
              ),
            ),
          );
        },
      ),
    );
  }
}