import 'package:flutter/material.dart';
import '../models/allergy_model.dart';
import '../services/allergy_service.dart';
import '../services/patient_service.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final _service = AllergyService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<AllergyModel> _allergies = [];

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
    _allergies = await _service.fetchAllergies(_patientId!);

    setState(() => _loading = false);
  }

  Future<void> _addAllergy() async {
    final allergenController = TextEditingController();
    final reactionController = TextEditingController();
    final severityController = TextEditingController();
    String type = 'other';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add allergy'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: allergenController, decoration: const InputDecoration(labelText: 'Allergen name')),
              TextField(controller: reactionController, decoration: const InputDecoration(labelText: 'Reaction')),
              TextField(controller: severityController, decoration: const InputDecoration(labelText: 'Severity')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'food', child: Text('Food')),
                  DropdownMenuItem(value: 'medication', child: Text('Medication')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => type = v ?? 'other',
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

    final allergy = AllergyModel(
      id: 'temp',
      patientId: _patientId!,
      allergenName: allergenController.text.trim(),
      allergyType: type,
      reaction: reactionController.text.trim(),
      severity: severityController.text.trim(),
      source: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.saveAllergy(
      allergy: allergy,
      performedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _deleteAllergy(AllergyModel allergy) async {
    if (_userId == null) return;

    await _service.deleteAllergy(
      id: allergy.id,
      patientId: allergy.patientId,
      performedByUserId: _userId!,
      allergenName: allergy.allergenName,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allergies')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAllergy,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _allergies.length,
        itemBuilder: (context, index) {
          final item = _allergies[index];
          return Card(
            child: ListTile(
              title: Text(item.allergenName),
              subtitle: Text('${item.allergyType} • ${item.severity ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteAllergy(item),
              ),
            ),
          );
        },
      ),
    );
  }
}