import 'package:flutter/material.dart';
import '../models/vaccination_model.dart';
import '../services/patient_service.dart';
import '../services/vaccination_service.dart';
import '../widgets/verification_badge.dart';

class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final _service = VaccinationService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<VaccinationModel> _items = [];

  String _selectedCategory = 'all';

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

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _items = await _service.fetchVaccinations(_patientId!);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<VaccinationModel> get _filteredItems {
    if (_selectedCategory == 'all') return _items;
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  Future<void> _add() async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'other';
    DateTime? dateAdministered;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateAdministered ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setStateDialog(() => dateAdministered = picked);
              }
            }

            return AlertDialog(
              title: const Text('Add vaccination'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Vaccine name'),
                    ),
                    TextField(
                      controller: doseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dose number',
                        hintText: 'in cc',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date administered'),
                      subtitle: Text(_formatDate(dateAdministered)),
                      trailing: TextButton(
                        onPressed: pickDate,
                        child: const Text('Pick'),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: const [
                        DropdownMenuItem(value: 'covid', child: Text('COVID')),
                        DropdownMenuItem(value: 'pnv', child: Text('PNV')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setStateDialog(() => category = v ?? 'other'),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
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

    final now = DateTime.now();

    final item = VaccinationModel(
      id: 'temp',
      patientId: _patientId!,
      vaccineName: nameController.text.trim(),
      category: category,
      doseNumber: int.tryParse(doseController.text.trim()),
      dateAdministered: dateAdministered,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _service.saveVaccination(
      vaccination: item,
      performedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _deleteItem(VaccinationModel item) async {
    if (_patientId == null || _userId == null) return;

    await _service.deleteVaccination(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      vaccineName: item.vaccineName,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'covid', child: Text('COVID')),
                DropdownMenuItem(value: 'pnv', child: Text('PNV')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No vaccinations found'))
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(item.vaccineName)),
                        const SizedBox(width: 8),
                        const VerificationBadge(status: 'user_entered'),
                      ],
                    ),
                    subtitle: Text(
                      [
                        'Category: ${item.category}',
                        if (item.doseNumber != null) 'Dose: ${item.doseNumber} cc',
                        'Date administered: ${_formatDate(item.dateAdministered)}',
                        if (item.notes != null && item.notes!.isNotEmpty) 'Notes: ${item.notes}',
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
          ),
        ],
      ),
    );
  }
}