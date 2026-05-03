import 'package:flutter/material.dart';
import '../models/surgery_model.dart';
import '../services/patient_service.dart';
import '../services/surgery_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/verification_badge.dart';

class SurgeriesScreen extends StatefulWidget {
  const SurgeriesScreen({super.key});

  @override
  State<SurgeriesScreen> createState() => _SurgeriesScreenState();
}

class _SurgeriesScreenState extends State<SurgeriesScreen> {
  final _service = SurgeryService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<SurgeryModel> _items = [];

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
    _items = await _service.fetchSurgeries(_patientId!);
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    final placeController = TextEditingController();
    final implantController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add surgery'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: nameController,
                  labelText: 'Surgery name',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: dateController,
                  labelText: 'Date (YYYY-MM-DD)',
                  validator: (v) => null,
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: placeController, labelText: 'Place'),
                const SizedBox(height: 12),
                CustomTextField(controller: implantController, labelText: 'Prosthetic / implant'),
                const SizedBox(height: 12),
                CustomTextField(controller: notesController, labelText: 'Notes', maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true || _patientId == null || _userId == null) return;

    final item = SurgeryModel(
      id: 'temp',
      patientId: _patientId!,
      surgeryName: nameController.text.trim(),
      surgeryDate: dateController.text.trim().isEmpty ? null : DateTime.tryParse(dateController.text.trim()),
      place: placeController.text.trim(),
      prostheticOrImplant: implantController.text.trim(),
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _service.saveSurgery(
      surgery: item,
      performedByUserId: _userId!,
    );
    await _load();
  }

  Future<void> _deleteItem(SurgeryModel item) async {
    if (_patientId == null || _userId == null) return;
    await _service.deleteSurgery(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      surgeryName: item.surgeryName,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surgeries')),
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
                  Expanded(child: Text(item.surgeryName)),
                  const SizedBox(width: 8),
                  const VerificationBadge(status: 'user_entered'),
                ],
              ),
              subtitle: Text(
                '${item.surgeryDate?.toIso8601String().split("T").first ?? '-'}'
                    '${item.place != null && item.place!.isNotEmpty ? ' • ${item.place}' : ''}',
              ),
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