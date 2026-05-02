import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// shows allergies, medications, and medical conditions in three tabs each tab supports add, edit, and delete
class MedicalSummaryScreen extends StatefulWidget {
  const MedicalSummaryScreen({super.key});

  @override
  State<MedicalSummaryScreen> createState() => _MedicalSummaryScreenState();
}

class _MedicalSummaryScreenState extends State<MedicalSummaryScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  String? _patientId;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allergies = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _conditions = [];

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
    setState(() => _isLoading = true);

    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) return;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (profileRow == null) {
        setState(() => _errorMessage =
        'Please complete your profile before adding medical data.');
        return;
      }

      _patientId = profileRow['id'] as String;

      // fetch all three lists at the same time to save round trips
      final results = await Future.wait([
        _supabase
            .from('allergies')
            .select()
            .eq('patient_id', _patientId!)
            .order('created_at', ascending: false),
        _supabase
            .from('medications')
            .select()
            .eq('patient_id', _patientId!)
            .order('created_at', ascending: false),
        _supabase
            .from('medical_conditions')
            .select()
            .eq('patient_id', _patientId!)
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _allergies = List<Map<String, dynamic>>.from(results[0] as List);
          _medications = List<Map<String, dynamic>>.from(results[1] as List);
          _conditions = List<Map<String, dynamic>>.from(results[2] as List);
        });
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Failed to load data: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error while loading data.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------------------------------- Allergy dialog -------------------------------

  Future<void> _showAllergyDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl =
    TextEditingController(text: existing?['allergen_name'] ?? '');
    final reactionCtrl =
    TextEditingController(text: existing?['reaction'] ?? '');
    final severityCtrl =
    TextEditingController(text: existing?['severity'] ?? '');
    String selectedType = existing?['allergy_type'] ?? 'other';

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
                  decoration:
                  const InputDecoration(labelText: 'Allergen Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(
                        value: 'medication', child: Text('Medication')),
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

                final data = {
                  'patient_id': _patientId,
                  'allergen_name': nameCtrl.text.trim(),
                  'allergy_type': selectedType,
                  'reaction': reactionCtrl.text.trim().isEmpty
                      ? null
                      : reactionCtrl.text.trim(),
                  'severity': severityCtrl.text.trim().isEmpty
                      ? null
                      : severityCtrl.text.trim(),
                  'source': 'user',
                };

                if (existing == null) {
                  await _supabase.from('allergies').insert(data);
                } else {
                  await _supabase
                      .from('allergies')
                      .update(data)
                      .eq('id', existing['id']);
                }

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

  Future<void> _deleteAllergy(String id) async {
    await _supabase.from('allergies').delete().eq('id', id);
    await _loadData();
  }

  // ------------------------------- Medication dialog -------------------------------

  Future<void> _showMedicationDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl =
    TextEditingController(text: existing?['medication_name'] ?? '');
    final dosageCtrl =
    TextEditingController(text: existing?['dosage'] ?? '');
    final frequencyCtrl =
    TextEditingController(text: existing?['frequency'] ?? '');
    final purposeCtrl =
    TextEditingController(text: existing?['purpose'] ?? '');

    DateTime? startDate = existing?['start_date'] != null
        ? DateTime.tryParse(existing!['start_date'].toString())
        : null;
    DateTime? endDate = existing?['end_date'] != null
        ? DateTime.tryParse(existing!['end_date'].toString())
        : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
          Text(existing == null ? 'Add Medication' : 'Edit Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration:
                  const InputDecoration(labelText: 'Medication Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 500 mg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    hintText: 'e.g. twice daily',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Purpose / Reason'),
                ),
                const SizedBox(height: 12),
                // start date picker
                Row(
                  children: [
                    Expanded(
                      child: Text(startDate == null
                          ? 'Start date: not set'
                          : 'Start: ${startDate!.toIso8601String().split('T').first}'),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                // end date picker
                Row(
                  children: [
                    Expanded(
                      child: Text(endDate == null
                          ? 'End date: not set'
                          : 'End: ${endDate!.toIso8601String().split('T').first}'),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
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

                final data = {
                  'patient_id': _patientId,
                  'medication_name': nameCtrl.text.trim(),
                  'dosage': dosageCtrl.text.trim().isEmpty
                      ? null
                      : dosageCtrl.text.trim(),
                  'frequency': frequencyCtrl.text.trim().isEmpty
                      ? null
                      : frequencyCtrl.text.trim(),
                  'purpose': purposeCtrl.text.trim().isEmpty
                      ? null
                      : purposeCtrl.text.trim(),
                  'start_date':
                  startDate?.toIso8601String().split('T').first,
                  'end_date': endDate?.toIso8601String().split('T').first,
                  'source': 'user',
                };

                if (existing == null) {
                  await _supabase.from('medications').insert(data);
                } else {
                  await _supabase
                      .from('medications')
                      .update(data)
                      .eq('id', existing['id']);
                }

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

  Future<void> _deleteMedication(String id) async {
    await _supabase.from('medications').delete().eq('id', id);
    await _loadData();
  }

  // ------------------------------- Medical condition dialog -------------------------------

  Future<void> _showConditionDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl =
    TextEditingController(text: existing?['condition_name'] ?? '');
    final placeCtrl =
    TextEditingController(text: existing?['diagnosis_place'] ?? '');
    final doctorCtrl =
    TextEditingController(text: existing?['follow_up_doctor'] ?? '');
    final treatmentCtrl =
    TextEditingController(text: existing?['treatment'] ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');

    String selectedType = existing?['type'] ?? 'chronic';
    DateTime? diagnosisDate = existing?['diagnosis_date'] != null
        ? DateTime.tryParse(existing!['diagnosis_date'].toString())
        : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
          Text(existing == null ? 'Add Condition' : 'Edit Condition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration:
                  const InputDecoration(labelText: 'Condition Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'chronic', child: Text('Chronic')),
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
                      child: Text(diagnosisDate == null
                          ? 'Diagnosed: not set'
                          : 'Diagnosed: ${diagnosisDate!.toIso8601String().split('T').first}'),
                    ),
                    TextButton(
                      child: const Text('Pick'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: diagnosisDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => diagnosisDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Diagnosis Place'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Follow-up Doctor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: treatmentCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Treatment'),
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

                final data = {
                  'patient_id': _patientId,
                  'condition_name': nameCtrl.text.trim(),
                  'type': selectedType,
                  'diagnosis_date':
                  diagnosisDate?.toIso8601String().split('T').first,
                  'diagnosis_place': placeCtrl.text.trim().isEmpty
                      ? null
                      : placeCtrl.text.trim(),
                  'follow_up_doctor': doctorCtrl.text.trim().isEmpty
                      ? null
                      : doctorCtrl.text.trim(),
                  'treatment': treatmentCtrl.text.trim().isEmpty
                      ? null
                      : treatmentCtrl.text.trim(),
                  'notes': notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                };

                if (existing == null) {
                  await _supabase.from('medical_conditions').insert(data);
                } else {
                  await _supabase
                      .from('medical_conditions')
                      .update(data)
                      .eq('id', existing['id']);
                }

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

  Future<void> _deleteCondition(String id) async {
    await _supabase.from('medical_conditions').delete().eq('id', id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
      // the FAB action changes depending on which tab is open
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final tab = _tabController.index;
          if (tab == 0) _showAllergyDialog();
          if (tab == 1) _showMedicationDialog();
          if (tab == 2) _showConditionDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ------------------------------- Allergies tab -------------------------------
          _allergies.isEmpty
              ? const Center(child: Text('No allergies recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _allergies.length,
            itemBuilder: (ctx, i) {
              final a = _allergies[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber,
                      color: Colors.orange),
                  title: Text(a['allergen_name'] ?? ''),
                  subtitle: Text([
                    if (a['allergy_type'] != null) a['allergy_type'],
                    if (a['severity'] != null) a['severity'],
                    if (a['reaction'] != null) a['reaction'],
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showAllergyDialog(existing: a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () =>
                            _deleteAllergy(a['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ------------------------------- Medications tab -------------------------------
          _medications.isEmpty
              ? const Center(child: Text('No medications recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _medications.length,
            itemBuilder: (ctx, i) {
              final m = _medications[i];
              return Card(
                child: ListTile(
                  leading:
                  const Icon(Icons.medication, color: Colors.blue),
                  title: Text(m['medication_name'] ?? ''),
                  subtitle: Text([
                    if (m['dosage'] != null) m['dosage'],
                    if (m['frequency'] != null) m['frequency'],
                    if (m['purpose'] != null) m['purpose'],
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showMedicationDialog(existing: m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () =>
                            _deleteMedication(m['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ------------------------------- Conditions tab -------------------------------
          _conditions.isEmpty
              ? const Center(child: Text('No conditions recorded.'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _conditions.length,
            itemBuilder: (ctx, i) {
              final c = _conditions[i];
              // chronic conditions are highlighted in red, acute in green
              final isChronic = c['type'] == 'chronic';
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.local_hospital,
                    color: isChronic ? Colors.red : Colors.green,
                  ),
                  title: Text(c['condition_name'] ?? ''),
                  subtitle: Text([
                    if (c['type'] != null) c['type'],
                    if (c['diagnosis_date'] != null)
                      'since ${c['diagnosis_date']}',
                    if (c['treatment'] != null) c['treatment'],
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showConditionDialog(existing: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () =>
                            _deleteCondition(c['id'] as String),
                      ),
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
