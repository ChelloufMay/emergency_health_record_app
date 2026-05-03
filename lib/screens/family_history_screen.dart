import 'package:flutter/material.dart';
import '../models/family_history_model.dart';
import '../services/family_history_service.dart';
import '../services/patient_service.dart';
import '../widgets/verification_badge.dart';

class FamilyHistoryScreen extends StatefulWidget {
  const FamilyHistoryScreen({super.key});

  @override
  State<FamilyHistoryScreen> createState() => _FamilyHistoryScreenState();
}

class _FamilyHistoryScreenState extends State<FamilyHistoryScreen> {
  final _service = FamilyHistoryService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<FamilyHistoryModel> _items = [];

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
    _items = await _service.fetchFamilyHistory(_patientId!);
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final relationController = TextEditingController();
    final conditionController = TextEditingController();
    final categoryController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add family history'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relation')),
              TextField(controller: conditionController, decoration: const InputDecoration(labelText: 'Condition name')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true || _patientId == null || _userId == null) return;

    final item = FamilyHistoryModel(
      id: 'temp',
      patientId: _patientId!,
      relation: relationController.text.trim(),
      conditionName: conditionController.text.trim(),
      category: categoryController.text.trim(),
      isGenetic: null,
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _service.saveFamilyHistory(
      item: item,
      performedByUserId: _userId!,
    );
    await _load();
  }

  Future<void> _deleteItem(FamilyHistoryModel item) async {
    if (_patientId == null || _userId == null) return;
    await _service.deleteFamilyHistory(
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
      appBar: AppBar(title: const Text('Family history')),
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
                  Expanded(child: Text(item.conditionName)),
                  const SizedBox(width: 8),
                  const VerificationBadge(status: 'user_entered'),
                ],
              ),
              subtitle: Text('${item.relation ?? ''}${item.category != null && item.category!.isNotEmpty ? ' • ${item.category}' : ''}'),
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