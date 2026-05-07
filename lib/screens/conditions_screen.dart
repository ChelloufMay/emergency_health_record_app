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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatFollowUpDoctor(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not set';
    return value;
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
    _conditions = await _service.fetchConditions(_patientId!);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addCondition() async {
    final nameController = TextEditingController();
    final placeController = TextEditingController();
    final followUpDoctorNameController = TextEditingController();
    final followUpDoctorPhoneController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();

    String type = 'chronic';
    DateTime? diagnosisDate;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDiagnosisDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: diagnosisDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => diagnosisDate = picked);
              }
            }

            return AlertDialog(
              title: const Text('Add condition'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Condition name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: placeController,
                      decoration: const InputDecoration(labelText: 'Diagnosis place'),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Diagnosis date'),
                      subtitle: Text(_formatDate(diagnosisDate)),
                      trailing: TextButton(
                        onPressed: pickDiagnosisDate,
                        child: const Text('Pick'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: followUpDoctorNameController,
                      decoration: const InputDecoration(labelText: 'Follow-up doctor name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: followUpDoctorPhoneController,
                      decoration: const InputDecoration(labelText: 'Follow-up doctor phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: treatmentController,
                      decoration: const InputDecoration(labelText: 'Treatment'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      items: const [
                        DropdownMenuItem(value: 'chronic', child: Text('Chronic')),
                        DropdownMenuItem(value: 'acute', child: Text('Acute')),
                      ],
                      onChanged: (v) => setDialogState(() => type = v ?? 'chronic'),
                      decoration: const InputDecoration(labelText: 'Type'),
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

    final doctorName = followUpDoctorNameController.text.trim();
    final doctorPhone = followUpDoctorPhoneController.text.trim();

    final item = MedicalConditionModel(
      id: 'temp',
      patientId: _patientId!,
      conditionName: nameController.text.trim(),
      type: type,
      diagnosisDate: diagnosisDate,
      diagnosisPlace: placeController.text.trim().isEmpty ? null : placeController.text.trim(),
      followUpDoctor: (doctorName.isEmpty && doctorPhone.isEmpty)
          ? null
          : [
        if (doctorName.isNotEmpty) doctorName,
        if (doctorPhone.isNotEmpty) doctorPhone,
      ].join(' • '),
      treatment: treatmentController.text.trim().isEmpty ? null : treatmentController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
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
          : _conditions.isEmpty
          ? const Center(child: Text('No conditions found'))
          : ListView.builder(
        itemCount: _conditions.length,
        itemBuilder: (context, index) {
          final item = _conditions[index];

          final details = <String>[
            'Type: ${item.type}',
            'Diagnosis date: ${_formatDate(item.diagnosisDate)}',
            'Diagnosis place: ${item.diagnosisPlace ?? 'Not set'}',
            'Follow-up doctor: ${_formatFollowUpDoctor(item.followUpDoctor)}',
            'Treatment: ${item.treatment ?? 'Not set'}',
            'Notes: ${item.notes ?? 'Not set'}',
          ];

          return Card(
            child: ListTile(
              title: Text(item.conditionName),
              subtitle: Text(details.join('\n')),
              isThreeLine: true,
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