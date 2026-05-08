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

  final List<String> _categoryOptions = const [
    'Cardiovascular',
    'Endocrine',
    'Respiratory',
    'Neurological',
    'Cancer',
    'Autoimmune',
    'Gastrointestinal',
    'Renal',
    'Mental health',
    'Infectious',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _normalizeCategory(String? value) {
    if (value == null || value.trim().isEmpty) return 'Other';
    final lower = value.trim().toLowerCase();

    for (final option in _categoryOptions) {
      if (option.toLowerCase() == lower) return option;
    }
    return 'Other';
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
    final notesController = TextEditingController();

    String selectedCategory = 'Other';
    bool isGenetic = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add family history'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: relationController,
                      decoration: const InputDecoration(
                        labelText: 'Relation',
                        hintText: 'Family member with the condition',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: conditionController,
                      decoration: const InputDecoration(
                        labelText: 'Condition name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: _categoryOptions
                          .map(
                            (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value ?? 'Other';
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isGenetic,
                      onChanged: (value) {
                        setDialogState(() {
                          isGenetic = value;
                        });
                      },
                      title: const Text('Genetic'),
                      subtitle: const Text('Indicate whether it is inherited'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || _patientId == null || _userId == null) return;

    final item = FamilyHistoryModel(
      id: 'temp',
      patientId: _patientId!,
      relation: relationController.text.trim().isEmpty
          ? null
          : relationController.text.trim(),
      conditionName: conditionController.text.trim(),
      category: _normalizeCategory(selectedCategory),
      isGenetic: isGenetic,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: null,
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
              subtitle: Text(
                [
                  if (item.relation != null &&
                      item.relation!.trim().isNotEmpty)
                    'Relation: ${item.relation}',
                  if (item.category != null &&
                      item.category!.trim().isNotEmpty)
                    'Category: ${item.category}',
                  if (item.isGenetic != null)
                    'Genetic: ${item.isGenetic! ? "Yes" : "No"}',
                  if (item.notes != null && item.notes!.trim().isNotEmpty)
                    'Notes: ${item.notes}',
                ].join('\n'),
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