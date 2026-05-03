import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergy_model.dart';
import '../models/medical_condition_model.dart';
import '../models/medication_model.dart';
import '../services/allergy_service.dart';
import '../services/medical_condition_service.dart';
import '../services/medication_service.dart';
import '../widgets/allergy_card.dart';
import '../widgets/medication_card.dart';
import '../widgets/verification_badge.dart';

class MedicalSummaryScreen extends StatefulWidget {
  const MedicalSummaryScreen({super.key});

  @override
  State<MedicalSummaryScreen> createState() => _MedicalSummaryScreenState();
}

class _MedicalSummaryScreenState extends State<MedicalSummaryScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  final _allergyService = AllergyService();
  final _medicationService = MedicationService();
  final _conditionService = MedicalConditionService();

  late TabController _tabController;

  String? _patientId;
  String? _appUserId;
  bool _canEdit = true;

  bool _isLoading = true;
  String? _errorMessage;

  List<AllergyModel> _allergies = [];
  List<MedicationModel> _medications = [];
  List<MedicalConditionModel> _conditions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();
      if (userRow == null) return;
      _appUserId = userRow['id'] as String;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (profileRow == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Please complete your profile before adding medical data.';
          });
        }
        return;
      }

      _patientId = profileRow['id'] as String;

      final permRow = await _supabase
          .from('caregiver_permissions')
          .select('permission')
          .eq('patient_id', _patientId!)
          .eq('caregiver_user_id', _appUserId!)
          .eq('status', 'active')
          .maybeSingle();

      if (permRow != null) {
        _canEdit = permRow['permission'] == 'edit';
      }

      final results = await Future.wait([
        _allergyService.fetchAllergies(_patientId!),
        _medicationService.fetchMedications(_patientId!),
        _conditionService.fetchConditions(_patientId!),
        _supabase
            .from('verification_labels')
            .select()
            .eq('patient_id', _patientId!),
      ]);

      final verificationRows = List<Map<String, dynamic>>.from(results[3] as List);
      final verMap = <String, String>{};
      for (final row in verificationRows) {
        final entityId = row['entity_id'] as String?;
        final status = row['status'] as String?;
        if (entityId != null && status != null) {
          verMap[entityId] = status;
        }
      }

      final allergies = results[0] as List<AllergyModel>;
      final medications = results[1] as List<MedicationModel>;
      final conditions = results[2] as List<MedicalConditionModel>;

      for (final a in allergies) {
        a.verificationStatus = verMap[a.id];
      }
      for (final m in medications) {
        m.verificationStatus = verMap[m.id];
      }
      for (final c in conditions) {
        c.verificationStatus = verMap[c.id];
      }

      if (mounted) {
        setState(() {
          _allergies = allergies;
          _medications = medications;
          _conditions = conditions;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load data: ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unexpected error while loading data.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAllergyDialog({AllergyModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.allergenName ?? '');
    final reactionCtrl = TextEditingController(text: existing?.reaction ?? '');
    final severityCtrl = TextEditingController(text: existing?.severity ?? '');
    String selectedType = existing?.allergyType ?? 'other';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Allergy' : 'Edit Allergy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Allergen Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reactionCtrl,
                  decoration: const InputDecoration(labelText: 'Reaction'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: severityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    hintText: 'e.g. mild, moderate, severe, anaphylaxis',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final allergy = AllergyModel(
                  id: existing?.id ?? '',
                  patientId: _patientId!,
                  allergenName: nameCtrl.text.trim(),
                  allergyType: selectedType,
                  reaction: reactionCtrl.text.trim().isEmpty ? null : reactionCtrl.text.trim(),
                  severity: severityCtrl.text.trim().isEmpty ? null : severityCtrl.text.trim(),
                  source: existing?.source ?? 'user',
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await _allergyService.saveAllergy(
                  allergy: allergy,
                  performedByUserId: _appUserId!,
                  existingId: existing?.id,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    reactionCtrl.dispose();
    severityCtrl.dispose();
  }

  Future<void> _showMedicationDialog({MedicationModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.medicationName ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final frequencyCtrl = TextEditingController(text: existing?.frequency ?? '');
    final purposeCtrl = TextEditingController(text: existing?.purpose ?? '');
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Medication' : 'Edit Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Medication Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500 mg'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyCtrl,
                  decoration: const InputDecoration(labelText: 'Frequency', hintText: 'e.g. twice daily'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose / Reason'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        startDate == null
                            ? 'Start: not set'
                            : 'Start: ${startDate!.toIso8601String().split('T').first}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (p != null) {
                          setDialogState(() => startDate = p);
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endDate == null
                            ? 'End: not set'
                            : 'End: ${endDate!.toIso8601String().split('T').first}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (p != null) {
                          setDialogState(() => endDate = p);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final medication = MedicationModel(
                  id: existing?.id ?? '',
                  patientId: _patientId!,
                  medicationName: nameCtrl.text.trim(),
                  dosage: dosageCtrl.text.trim().isEmpty ? null : dosageCtrl.text.trim(),
                  frequency: frequencyCtrl.text.trim().isEmpty ? null : frequencyCtrl.text.trim(),
                  purpose: purposeCtrl.text.trim().isEmpty ? null : purposeCtrl.text.trim(),
                  source: existing?.source ?? 'user',
                  startDate: startDate,
                  endDate: endDate,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await _medicationService.saveMedication(
                  medication: medication,
                  performedByUserId: _appUserId!,
                  existingId: existing?.id,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    purposeCtrl.dispose();
  }

  Future<void> _showConditionDialog({MedicalConditionModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.conditionName ?? '');
    final placeCtrl = TextEditingController(text: existing?.diagnosisPlace ?? '');
    final doctorCtrl = TextEditingController(text: existing?.followUpDoctor ?? '');
    final treatmentCtrl = TextEditingController(text: existing?.treatment ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String selectedType = existing?.type ?? 'chronic';
    DateTime? diagnosisDate = existing?.diagnosisDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Condition' : 'Edit Condition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Condition Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'chronic', child: Text('Chronic')),
                    DropdownMenuItem(value: 'acute', child: Text('Acute')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        diagnosisDate == null
                            ? 'Diagnosed: not set'
                            : 'Diagnosed: ${diagnosisDate!.toIso8601String().split('T').first}',
                      ),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: diagnosisDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (p != null) {
                          setDialogState(() => diagnosisDate = p);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeCtrl,
                  decoration: const InputDecoration(labelText: 'Diagnosis Place'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(labelText: 'Follow-up Doctor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: treatmentCtrl,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final condition = MedicalConditionModel(
                  id: existing?.id ?? '',
                  patientId: _patientId!,
                  conditionName: nameCtrl.text.trim(),
                  type: selectedType,
                  diagnosisDate: diagnosisDate,
                  diagnosisPlace: placeCtrl.text.trim().isEmpty ? null : placeCtrl.text.trim(),
                  followUpDoctor: doctorCtrl.text.trim().isEmpty ? null : doctorCtrl.text.trim(),
                  treatment: treatmentCtrl.text.trim().isEmpty ? null : treatmentCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await _conditionService.saveCondition(
                  condition: condition,
                  performedByUserId: _appUserId!,
                  existingId: existing?.id,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    placeCtrl.dispose();
    doctorCtrl.dispose();
    treatmentCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medical Summary')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Summary'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Allergies'),
            Tab(text: 'Medications'),
            Tab(text: 'Conditions'),
          ],
        ),
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton(
        onPressed: () {
          final tab = _tabController.index;
          if (tab == 0) _showAllergyDialog();
          if (tab == 1) _showMedicationDialog();
          if (tab == 2) _showConditionDialog();
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _allergies.isEmpty
              ? const Center(child: Text('No allergies recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _allergies.length,
            itemBuilder: (ctx, i) => AllergyCard(
              allergy: _allergies[i],
              canEdit: _canEdit,
              onEdit: () => _showAllergyDialog(existing: _allergies[i]),
              onDelete: () async {
                await _allergyService.deleteAllergy(
                  id: _allergies[i].id,
                  patientId: _patientId!,
                  performedByUserId: _appUserId!,
                  allergenName: _allergies[i].allergenName,
                );
                await _loadData();
              },
            ),
          ),
          _medications.isEmpty
              ? const Center(child: Text('No medications recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _medications.length,
            itemBuilder: (ctx, i) => MedicationCard(
              medication: _medications[i],
              canEdit: _canEdit,
              onEdit: () => _showMedicationDialog(existing: _medications[i]),
              onDelete: () async {
                await _medicationService.deleteMedication(
                  id: _medications[i].id,
                  patientId: _patientId!,
                  performedByUserId: _appUserId!,
                  medicationName: _medications[i].medicationName,
                );
                await _loadData();
              },
            ),
          ),
          _conditions.isEmpty
              ? const Center(child: Text('No conditions recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _conditions.length,
            itemBuilder: (ctx, i) {
              final c = _conditions[i];
              final isChronic = c.type == 'chronic';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            color: isChronic ? Colors.red : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.conditionName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_canEdit) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _showConditionDialog(existing: c),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () async {
                                await _conditionService.deleteCondition(
                                  id: c.id,
                                  patientId: _patientId!,
                                  performedByUserId: _appUserId!,
                                  conditionName: c.conditionName,
                                );
                                await _loadData();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(c.type, style: const TextStyle(fontSize: 12)),
                          if (c.diagnosisDate != null)
                            Text(
                              'since ${c.diagnosisDate!.toIso8601String().split('T').first}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          if (c.treatment != null)
                            Text(
                              c.treatment!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      VerificationBadge(status: c.verificationStatus ?? 'user_entered'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}