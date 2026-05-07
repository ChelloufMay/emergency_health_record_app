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
  final HospitalizationService _service = HospitalizationService();
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<HospitalizationModel> _items = [];

  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _matchesFilter(HospitalizationModel item) {
    final range = _dateFilter;
    if (range == null) return true;

    final admission = item.admissionDate;
    final discharge = item.dischargeDate;

    bool inRange(DateTime? date) {
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }

    return inRange(admission) || inRange(discharge);
  }

  List<HospitalizationModel> get _filteredItems {
    final filtered = _items.where(_matchesFilter).toList();
    filtered.sort((a, b) {
      final aDate = a.admissionDate ?? a.createdAt;
      final bDate = b.admissionDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: _dateFilter,
    );

    if (picked != null && mounted) {
      setState(() => _dateFilter = picked);
    }
  }

  Future<void> _clearFilter() async {
    if (!mounted) return;
    setState(() => _dateFilter = null);
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _items = await _service.fetchHospitalizations(_patientId!);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    final hospitalController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    DateTime? admissionDate;
    DateTime? dischargeDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickAdmissionDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: admissionDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => admissionDate = picked);
              }
            }

            Future<void> pickDischargeDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dischargeDate ?? (admissionDate ?? DateTime.now()),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => dischargeDate = picked);
              }
            }

            return AlertDialog(
              title: const Text('Add hospitalization'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: hospitalController,
                      decoration: const InputDecoration(labelText: 'Hospital name'),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Admission date'),
                      subtitle: Text(_formatDate(admissionDate)),
                      trailing: TextButton(
                        onPressed: pickAdmissionDate,
                        child: const Text('Pick'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Discharge date'),
                      subtitle: Text(_formatDate(dischargeDate)),
                      trailing: TextButton(
                        onPressed: pickDischargeDate,
                        child: const Text('Pick'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
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

    if (ok != true || _patientId == null || _userId == null) return;

    final item = HospitalizationModel(
      id: 'temp',
      patientId: _patientId!,
      hospitalName: hospitalController.text.trim().isEmpty
          ? null
          : hospitalController.text.trim(),
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitalizations'),
        actions: [
          IconButton(
            tooltip: 'Filter by date range',
            onPressed: _pickDateFilter,
            icon: const Icon(Icons.filter_alt),
          ),
          if (_dateFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              onPressed: _clearFilter,
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_dateFilter != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing: ${_formatDate(_dateFilter!.start)} to ${_formatDate(_dateFilter!.end)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No hospitalizations found'))
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(item.hospitalName ?? 'Hospitalization'),
                        ),
                        const SizedBox(width: 8),
                        const VerificationBadge(status: 'user_entered'),
                      ],
                    ),
                    subtitle: Text(
                      'Admission: ${_formatDate(item.admissionDate)} → Discharge: ${_formatDate(item.dischargeDate)}'
                          '${item.reason != null && item.reason!.isNotEmpty ? '\n${item.reason}' : ''}'
                          '${item.notes != null && item.notes!.isNotEmpty ? '\n${item.notes}' : ''}',
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
          ),
        ],
      ),
    );
  }
}