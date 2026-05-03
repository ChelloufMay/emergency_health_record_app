import 'package:flutter/material.dart';
import '../models/medical_condition_model.dart';
import '../services/patient_service.dart';
import '../services/medical_condition_service.dart';

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key});

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  final _service = MedicalConditionService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<MedicalConditionModel> _conditions = [];

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
    _conditions = await _service.fetchConditions(_patientId!);

    setState(() => _loading = false);
  }

  Future<void> _addCondition() async {
    final nameController = TextEditingController();
    final placeController = TextEditingController();
    final notesController = TextEditingController();
    String type = 'chronic';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add condition'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Condition name')),
              TextField(controller: placeController, decoration: const InputDecoration(labelText: 'Diagnosis place')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'chronic', child: Text('Chronic')),
                  DropdownMenuItem(value: 'acute', child: Text('Acute')),
                ],
                onChanged: (v) => type = v ?? 'chronic',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
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

    final item = MedicalConditionModel(
      id: 'temp',
      patientId: _patientId!,
      conditionName: nameController.text.trim(),
      type: type,
      diagnosisPlace: placeController.text.trim(),
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.saveCondition(
      condition: item,
      performedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _deleteCondition(MedicalConditionModel item) async {
    if (_userId == null) return;

    await _service.deleteCondition(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      conditionName: item.conditionName,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCondition,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _conditions.length,
        itemBuilder: (context, index) {
          final item = _conditions[index];
          return Card(
            child: ListTile(
              title: Text(item.conditionName),
              subtitle: Text(item.type),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteCondition(item),
              ),
            ),
          );
        },
      ),
    );
  }
}