import 'package:flutter/material.dart';
import '../models/hospitalization_model.dart';
import '../services/hospitalization_service.dart';
import '../services/patient_service.dart';
import '../widgets/verification_badge.dart';

class HospitalizationsScreen extends StatefulWidget {
  const HospitalizationsScreen({super.key});

  @override
  State<HospitalizationsScreen> createState() => _HospitalizationsScreenState();
}

class _HospitalizationsScreenState extends State<HospitalizationsScreen> {
  final _service = HospitalizationService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<HospitalizationModel> _items = [];

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
    _items = await _service.fetchHospitalizations(_patientId!);
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final hospitalController = TextEditingController();
    final admissionController = TextEditingController();
    final dischargeController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add hospitalization'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: hospitalController, decoration: const InputDecoration(labelText: 'Hospital name')),
              TextField(controller: admissionController, decoration: const InputDecoration(labelText: 'Admission date (YYYY-MM-DD)')),
              TextField(controller: dischargeController, decoration: const InputDecoration(labelText: 'Discharge date (YYYY-MM-DD)')),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
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

    final item = HospitalizationModel(
      id: 'temp',
      patientId: _patientId!,
      hospitalName: hospitalController.text.trim(),
      admissionDate: admissionController.text.trim().isEmpty ? null : DateTime.tryParse(admissionController.text.trim()),
      dischargeDate: dischargeController.text.trim().isEmpty ? null : DateTime.tryParse(dischargeController.text.trim()),
      reason: reasonController.text.trim(),
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _service.saveHospitalization(
      hospitalization: item,
      performedByUserId: _userId!,
    );
    await _load();
  }

  Future<void> _deleteItem(HospitalizationModel item) async {
    if (_patientId == null || _userId == null) return;
    await _service.deleteHospitalization(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      hospitalName: item.hospitalName ?? '',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospitalizations')),
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
                  Expanded(child: Text(item.hospitalName ?? 'Hospitalization')),
                  const SizedBox(width: 8),
                  const VerificationBadge(status: 'user_entered'),
                ],
              ),
              subtitle: Text(
                '${item.admissionDate?.toIso8601String().split("T").first ?? '-'} → ${item.dischargeDate?.toIso8601String().split("T").first ?? '-'}'
                    '${item.reason != null && item.reason!.isNotEmpty ? '\n${item.reason}' : ''}',
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