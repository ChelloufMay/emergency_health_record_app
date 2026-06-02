// Managing and viewing a patient's vaccinations, including PNV schedule and others.
import 'package:flutter/material.dart';

import '../models/vaccination_model.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import '../services/vaccination_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

// Defines a specific vaccination slot in the national vaccination program (PNV).
class _PnvSlot {
  // What gets stored as vaccine_name in the DB.
  final String key;

  final String ageLabel;

  // Friendly vaccine description shown as subtitle.
  final String description;

  const _PnvSlot({
    required this.key,
    required this.ageLabel,
    required this.description,
  });
}

// Represents a group of PNV vaccination slots
class _PnvGroup {
  final String title;
  final List<_PnvSlot> slots;

  const _PnvGroup({required this.title, required this.slots});
}

// Static list of PNV vaccination groups and their respective slots.
const List<_PnvGroup> _pnvGroups = [
  // ------------------------------ À la naissance ------------------------------
  _PnvGroup(
    title: 'À la naissance',
    slots: [
      _PnvSlot(
        key: 'BCG',
        ageLabel: 'À la naissance',
        description:
            'BCG - Vaccin contre la tuberculose (1 seule dose, le plus tôt possible après la naissance)',
      ),
      _PnvSlot(
        key: 'HBV-0',
        ageLabel: 'À la naissance',
        description:
            'HBV-0 - Vaccin contre l\'hépatite B (dans les 24 h suivant la naissance)',
      ),
    ],
  ),

  // ------------------------------ Enfant en âge préscolaire ------------------------------
  _PnvGroup(
    title: 'Enfant en âge préscolaire',
    slots: [
      _PnvSlot(
        key: 'Pentavalent-1',
        ageLabel: 'À 2 mois',
        description: 'Pentavalent-1 - 1re prise (DTC + Hib + HBV)',
      ),
      _PnvSlot(
        key: 'VPI-1',
        ageLabel: 'À 2 mois',
        description:
            'VPI-1 - 1re prise du vaccin contre la poliomyélite (injectable)',
      ),
      _PnvSlot(
        key: 'PCV1',
        ageLabel: 'À 2 mois',
        description: 'PCV1 - 1re prise du vaccin pneumococcique',
      ),
      _PnvSlot(
        key: 'Pentavalent-2',
        ageLabel: 'À 3 mois',
        description: 'Pentavalent-2 - 2e prise (DTC + Hib + HBV)',
      ),
      _PnvSlot(
        key: 'VPI-2',
        ageLabel: 'À 3 mois',
        description:
            'VPI-2 - 2e prise du vaccin contre la poliomyélite (injectable)',
      ),
      _PnvSlot(
        key: 'PCV2',
        ageLabel: 'À 4 mois',
        description: 'PCV2 - 2e prise du vaccin pneumococcique',
      ),
      _PnvSlot(
        key: 'Pentavalent-3',
        ageLabel: 'À 6 mois',
        description: 'Pentavalent-3 - 3e prise (DTC + Hib + HBV)',
      ),
      _PnvSlot(
        key: 'VPI-3',
        ageLabel: 'À 6 mois',
        description:
            'VPI-3 - 3e prise du vaccin contre la poliomyélite (injectable)',
      ),
      _PnvSlot(
        key: 'PCV3',
        ageLabel: 'À 11 mois',
        description: 'PCV3 - 3e prise du vaccin pneumococcique',
      ),
      _PnvSlot(
        key: 'RR-1',
        ageLabel: 'À 12 mois',
        description: 'RR-1 - 1re prise du vaccin combiné rougeole-rubéole',
      ),
      _PnvSlot(
        key: 'HVA-18m',
        ageLabel: 'À 18 mois',
        description: 'HVA - Vaccin contre l\'hépatite virale A',
      ),
      _PnvSlot(
        key: 'DTC4',
        ageLabel: 'À 18 mois',
        description: 'DTC4 - Rappel par les vaccins DTC',
      ),
      _PnvSlot(
        key: 'VPO-1',
        ageLabel: 'À 18 mois',
        description: 'VPO - Rappel par le vaccin contre la poliomyélite (oral)',
      ),
      _PnvSlot(
        key: 'RR-2',
        ageLabel: 'À 18 mois',
        description: 'RR-2 - Rappel par le vaccin combiné rougeole-rubéole',
      ),
    ],
  ),

  // ------------------------------ Enfant en âge scolaire ------------------------------
  _PnvGroup(
    title: 'Enfant en âge scolaire',
    slots: [
      _PnvSlot(
        key: 'DTCa-VPI-6ans',
        ageLabel: 'À 6 ans\n(1re année)',
        description:
            'DTCa-VPI - Rappel quadrivalent (diphtérie, tétanos, coqueluche acellulaire, poliomyélite)',
      ),
      _PnvSlot(
        key: 'VHA-6ans',
        ageLabel: 'À 6 ans\n(1re année)',
        description: 'VHA - 1 prise du vaccin contre l\'hépatite virale A',
      ),
      _PnvSlot(
        key: 'dT-12ans',
        ageLabel: 'À 12 ans\n(6e année)',
        description: 'dT - Rappel contre la diphtérie et le tétanos',
      ),
      _PnvSlot(
        key: 'VPO-12ans',
        ageLabel: 'À 12 ans\n(6e année)',
        description: 'VPO - Rappel par le vaccin oral contre la poliomyélite',
      ),
      _PnvSlot(
        key: 'VPH-12ans',
        ageLabel: 'À 12 ans\n(6e année)',
        description:
            'VPH - 1 prise du vaccin contre le Virus du Papillome Humain',
      ),
      _PnvSlot(
        key: 'dT-18ans',
        ageLabel: 'À 18 ans\n(3e secondaire)',
        description: 'dT - Rappel contre la diphtérie et le tétanos',
      ),
      _PnvSlot(
        key: 'VPO-18ans',
        ageLabel: 'À 18 ans\n(3e secondaire)',
        description: 'VPO - Rappel par le vaccin oral contre la poliomyélite',
      ),
    ],
  ),

  // ------------------------------  Femmes en âge de procréation ------------------------------
  _PnvGroup(
    title: 'Femmes en âge de procréation',
    slots: [
      _PnvSlot(
        key: 'dT1-femme',
        ageLabel: 'dT1',
        description: 'dT1 - Dès le premier contact avec la structure de santé',
      ),
      _PnvSlot(
        key: 'dT2-femme',
        ageLabel: 'dT2',
        description: 'dT2 - 1 mois après dT1',
      ),
      _PnvSlot(
        key: 'dT3-femme',
        ageLabel: 'dT3',
        description: 'dT3 - 1 an après dT2',
      ),
      _PnvSlot(
        key: 'dT4-femme',
        ageLabel: 'dT4',
        description: 'dT4 - 5 ans après dT3',
      ),
      _PnvSlot(
        key: 'dT5-femme',
        ageLabel: 'dT5',
        description: 'dT5 - 10 ans après dT4 (puis tous les 10 ans)',
      ),
      _PnvSlot(
        key: 'Rubeole-femme',
        ageLabel: 'Rubéole',
        description:
            'Vaccin contre la rubéole - Pour les femmes non immunisées',
      ),
    ],
  ),
];

// --------------------------- Screen for displaying and recording vaccinations.
class VaccinationsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const VaccinationsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen>
    with SingleTickerProviderStateMixin {
  final VaccinationService _service = VaccinationService();

  late final TabController _tabController;

  bool _loading = true;
  String? _patientId;

  // All DB rows where category == 'pnv', keyed by vaccine_name
  final Map<String, VaccinationModel> _pnvRows = {};

  // Which PNV slot keys are currently toggled on
  final Set<String> _pnvChecked = {};

  // In progress toggles to disable checkbox.
  final Set<String> _pnvBusy = {};

  // Vaccinations that are NOT PNV
  List<VaccinationModel> _otherItems = [];

  late SectionScreenAccess _access;

  @override
  void initState() {
    // Initialize tab controller and load vaccination data.
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);
    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );
    _load();
  }

  void _rebuildOnPermissionChange() {
    if (!mounted) return;
    setState(() {
      _access = SectionScreenAccess(
        widgetCanEdit: widget.canEdit,
        widgetIsEmergencyOnly: widget.isEmergencyOnly,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    PatientAccessContext.instance.removeListener(_rebuildOnPermissionChange);
    super.dispose();
  }

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

  // Loads both PNV and other vaccinations from the service.
  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final allItems = await _service.fetchByPatient(patientId);
    if (!mounted) return;

    final newPnvRows = <String, VaccinationModel>{};
    final newOther = <VaccinationModel>[];

    for (final item in allItems) {
      if (item.category == 'pnv') {
        newPnvRows[item.vaccineName] = item;
      } else {
        newOther.add(item);
      }
    }

    setState(() {
      _patientId = patientId;
      _pnvRows
        ..clear()
        ..addAll(newPnvRows);
      _pnvChecked
        ..clear()
        ..addAll(newPnvRows.keys);
      _otherItems = newOther;
      _loading = false;
    });
  }

  // ------------------------------  PNV checkbox toggle ------------------------------

  // Toggles a PNV vaccination slot (adds or removes the record).
  Future<void> _onPnvToggle(_PnvSlot slot, bool checked) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;
    if (_pnvBusy.contains(slot.key)) return;

    if (checked) {
      // Insert a new PNV row.
      setState(() => _pnvBusy.add(slot.key));
      try {
        final id = await _service.save(
          vaccination: VaccinationModel(
            patientId: patientId,
            vaccineName: slot.key,
            category: 'pnv',
          ),
          patientId: patientId,
        );
        if (!mounted) return;
        final newRow = VaccinationModel(
          id: id,
          patientId: patientId,
          vaccineName: slot.key,
          category: 'pnv',
        );
        setState(() {
          _pnvRows[slot.key] = newRow;
          _pnvChecked.add(slot.key);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _pnvBusy.remove(slot.key));
      }
    } else {
      // Confirm then delete.
      final existing = _pnvRows[slot.key];
      if (existing?.id == null) return;

      final confirmed = await showDeleteConfirmDialog(
        context: context,
        title: 'Retirer ce vaccin ?',
        message: 'La ligne sera supprimée de votre dossier.',
      );
      if (!confirmed || !mounted) return;

      setState(() => _pnvBusy.add(slot.key));
      try {
        await _service.delete(patientId: patientId, id: existing!.id!);
        if (!mounted) return;
        setState(() {
          _pnvRows.remove(slot.key);
          _pnvChecked.remove(slot.key);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _pnvBusy.remove(slot.key));
      }
    }
  }

  // ------------------------------ Other vaccinations editor ------------------------------

  // Opens an editor dialog for non-PNV vaccinations.
  Future<void> _openEditor({VaccinationModel? initial}) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final nameController = TextEditingController(
      text: initial?.vaccineName ?? '',
    );
    final doseController = TextEditingController(
      text: initial?.doseNumber?.toString() ?? '',
    );
    final notesController = TextEditingController(text: initial?.notes ?? '');
    DateTime? dateAdministered = initial?.dateAdministered;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add vaccination' : 'Edit vaccination',
          validate: () {
            if (nameController.text.trim().isEmpty) {
              return 'Vaccine name is required.';
            }
            return null;
          },
          onSave: () async {
            final model = VaccinationModel(
              id: initial?.id,
              patientId: patientId,
              vaccineName: nameController.text.trim(),
              category: 'other',
              // always 'other' in this tab
              doseNumber: int.tryParse(doseController.text.trim()),
              dateAdministered: dateAdministered,
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );
            await _service.save(vaccination: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Vaccine name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: doseController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Dosage number',
                          hintText: 'in cc',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date administered'),
                        subtitle: Text(
                          dateAdministered == null
                              ? 'Not set'
                              : dateAdministered!
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                        ),
                        trailing: IconButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    initialDate:
                                        dateAdministered ?? DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => dateAdministered = picked,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    nameController.dispose();
    doseController.dispose();
    notesController.dispose();

    if (saved == true) await _load();
  }

  // Deletes a specific non PNV vaccination entry.
  Future<void> _deleteOtherItem(VaccinationModel item) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete vaccination?',
      message: 'This action cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    await _service.delete(patientId: patientId, id: item.id!);
    if (!mounted) return;
    await _load();
  }

  // ------------------------------ Build ------------------------------

  @override
  Widget build(BuildContext context) {
    // Builds the scaffold with tabs for PNV and other vaccinations.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccinations'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'PNV'),
            Tab(text: 'Autres vaccins'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : TabBarView(
              controller: _tabController,
              children: [
                _PnvTab(
                  groups: _pnvGroups,
                  checked: _pnvChecked,
                  busy: _pnvBusy,
                  allowMutations: _access.allowMutations,
                  onToggle: _onPnvToggle,
                  onRefresh: _load,
                ),
                _OtherTab(
                  items: _otherItems,
                  allowMutations: _access.allowMutations,
                  onAdd: () => _openEditor(),
                  onEdit: (item) => _openEditor(initial: item),
                  onDelete: _deleteOtherItem,
                  onRefresh: _load,
                ),
              ],
            ),
    );
  }
}

// --------------------------------------- PNV checklist ------------------------------

class _PnvTab extends StatelessWidget {
  final List<_PnvGroup> groups;
  final Set<String> checked;
  final Set<String> busy;
  final bool allowMutations;
  final Future<void> Function(_PnvSlot slot, bool checked) onToggle;
  final Future<void> Function() onRefresh;

  const _PnvTab({
    required this.groups,
    required this.checked,
    required this.busy,
    required this.allowMutations,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Info banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cochez les vaccins que vous avez reçus. '
                    'Chaque case est enregistrée immédiatement.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          for (final group in groups) ...[
            // Group header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                group.title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Slots
            for (final slot in group.slots)
              _PnvRow(
                slot: slot,
                isChecked: checked.contains(slot.key),
                isBusy: busy.contains(slot.key),
                allowMutations: allowMutations,
                onToggle: onToggle,
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PnvRow extends StatelessWidget {
  final _PnvSlot slot;
  final bool isChecked;
  final bool isBusy;
  final bool allowMutations;
  final Future<void> Function(_PnvSlot, bool) onToggle;

  const _PnvRow({
    required this.slot,
    required this.isChecked,
    required this.isBusy,
    required this.allowMutations,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: (allowMutations && !isBusy)
          ? () => onToggle(slot, !isChecked)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age label: prominent, left column
            SizedBox(
              width: 90,
              child: Text(
                slot.ageLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isChecked
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Vaccine description: fills remaining space
            Expanded(
              child: Text(
                slot.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isChecked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Checkbox / busy indicator
            isBusy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Checkbox(
                    value: isChecked,
                    onChanged: (allowMutations && !isBusy)
                        ? (v) => onToggle(slot, v ?? false)
                        : null,
                    activeColor: colorScheme.primary,
                  ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------ Other vaccinations ------------------------------

class _OtherTab extends StatelessWidget {
  final List<VaccinationModel> items;
  final bool allowMutations;
  final VoidCallback onAdd;
  final void Function(VaccinationModel) onEdit;
  final void Function(VaccinationModel) onDelete;
  final Future<void> Function() onRefresh;

  const _OtherTab({
    required this.items,
    required this.allowMutations,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FAB for adding: only visible in this tab
      floatingActionButton: allowMutations
          ? FloatingActionButton(
              onPressed: onAdd,
              tooltip: 'Add vaccination',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(
                // Allows pull-to-refresh even when empty
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No other vaccinations recorded.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.vaccineName),
                      subtitle: Text(
                        [
                          if (item.doseNumber != null)
                            'Dose: ${item.doseNumber}',
                          if (item.dateAdministered != null)
                            'Date: ${item.dateAdministered!.toIso8601String().split('T').first}',
                          if ((item.notes ?? '').isNotEmpty)
                            'Notes: ${item.notes}',
                        ].join('\n'),
                      ),
                      trailing: allowMutations
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit(item);
                                } else if (value == 'delete') {
                                  onDelete(item);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
