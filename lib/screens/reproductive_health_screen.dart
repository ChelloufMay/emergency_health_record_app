import 'package:flutter/material.dart';
import '../models/reproductive_health_model.dart';
import '../services/patient_service.dart';
import '../services/reproductive_health_service.dart';

class ReproductiveHealthScreen extends StatefulWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  State<ReproductiveHealthScreen> createState() =>
      _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  final _service = ReproductiveHealthService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  String? _sex;
  ReproductiveHealthModel? _item;

  final _lastStartController = TextEditingController();
  final _lastEndController = TextEditingController();
  final _pregnancyWeeksController = TextEditingController();
  final _gestityController = TextEditingController();
  final _parityController = TextEditingController();
  final _abortionsController = TextEditingController();
  final _pubertyAgeController = TextEditingController();
  final _breastNotesController = TextEditingController();
  final _pregnancyHistoryController = TextEditingController();
  final _birthHistoryController = TextEditingController();
  final _abortionHistoryController = TextEditingController();

  bool? hasMenstrualCycle;
  bool? cycleRegular;
  bool? cyclePainful;
  bool? currentlyPregnant;

  int? painLevel;
  DateTime? _lastPeriodStart;
  DateTime? _lastPeriodEnd;

  // Used for the automatic cycle suggestion.
  bool _startEditedManually = false;
  bool _endEditedManually = false;

  // Default cycle assumptions for auto-tracking.
  static const int _defaultCycleLengthDays = 28;
  static const int _defaultPeriodDurationDays = 5;

  final List<int> _painLevels = List<int>.generate(10, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  DateTime? _parseDateFromController(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required bool isStartDate,
  }) async {
    final now = DateTime.now();
    final initial = _parseDateFromController(controller) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      controller.text = _formatDate(picked);

      // Mark the field as manually edited so auto-suggestion does not overwrite it.
      if (isStartDate) {
        _lastPeriodStart = picked;
        _startEditedManually = true;
      } else {
        _lastPeriodEnd = picked;
        _endEditedManually = true;
      }
    });
  }

  int _existingPeriodDurationDays() {
    if (_lastPeriodStart != null && _lastPeriodEnd != null) {
      final diff = _lastPeriodEnd!.difference(_lastPeriodStart!).inDays + 1;
      return diff > 0 ? diff : _defaultPeriodDurationDays;
    }
    return _defaultPeriodDurationDays;
  }

  /// Best-effort cycle helper:
  /// - uses a 28-day cycle by default
  /// - keeps the previously observed period length when possible
  /// - advances the stored dates to the next expected cycle when the old one is due
  void _applyCycleSuggestionIfNeeded() {
    if (_lastPeriodStart == null) return;
    if (_startEditedManually || _endEditedManually) return;

    final now = DateTime.now();
    final cycleLength = _defaultCycleLengthDays;
    final periodLength = _existingPeriodDurationDays();

    // This treats "last saved period" as the last known cycle marker.
    // If the next expected cycle is due or overdue, advance to it.
    final nextExpectedStart =
    _lastPeriodStart!.add(Duration(days: cycleLength));
    if (now.isAfter(nextExpectedStart) || now.isAtSameMomentAs(nextExpectedStart)) {
      final nextExpectedEnd =
      nextExpectedStart.add(Duration(days: periodLength - 1));

      _lastPeriodStart = nextExpectedStart;
      _lastPeriodEnd = nextExpectedEnd;

      _lastStartController.text = _formatDate(nextExpectedStart);
      _lastEndController.text = _formatDate(nextExpectedEnd);
    }

    // If pregnant is selected, keep the same rule but allow the app to continue
    // advancing the tracked dates as the user requested.
    if (currentlyPregnant == true) {
      final pregnantCycleStart =
      _lastPeriodStart!.add(const Duration(days: _defaultCycleLengthDays));
      final pregnantCycleEnd =
      pregnantCycleStart.add(Duration(days: periodLength - 1));

      if (now.isAfter(pregnantCycleStart) || now.isAtSameMomentAs(pregnantCycleStart)) {
        _lastPeriodStart = pregnantCycleStart;
        _lastPeriodEnd = pregnantCycleEnd;
        _lastStartController.text = _formatDate(pregnantCycleStart);
        _lastEndController.text = _formatDate(pregnantCycleEnd);
      }
    }
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _sex = identity.sex;
    _item = await _service.fetchReproductiveHealth(_patientId!);

    if (_item != null) {
      hasMenstrualCycle = _item!.hasMenstrualCycle;
      cycleRegular = _item!.cycleRegular;
      cyclePainful = _item!.cyclePainful;
      currentlyPregnant = _item!.currentlyPregnant;

      painLevel = int.tryParse(_item!.painLevel ?? '');
      _lastPeriodStart = _item!.lastPeriodStart;
      _lastPeriodEnd = _item!.lastPeriodEnd;

      _lastStartController.text = _item!.lastPeriodStart != null
          ? _formatDate(_item!.lastPeriodStart!)
          : '';
      _lastEndController.text = _item!.lastPeriodEnd != null
          ? _formatDate(_item!.lastPeriodEnd!)
          : '';

      _pregnancyWeeksController.text =
          _item!.pregnancyTermWeeks?.toString() ?? '';
      _gestityController.text = _item!.gestity?.toString() ?? '';
      _parityController.text = _item!.parity?.toString() ?? '';
      _abortionsController.text = _item!.abortions?.toString() ?? '';
      _pubertyAgeController.text = _item!.pubertyAge?.toString() ?? '';
      _breastNotesController.text = _item!.breastExamNotes ?? '';
      _pregnancyHistoryController.text = _item!.pregnancyHistory ?? '';
      _birthHistoryController.text = _item!.birthHistory ?? '';
      _abortionHistoryController.text = _item!.abortionHistory ?? '';
    }

    // Apply the auto-suggestion after loading existing data.
    _applyCycleSuggestionIfNeeded();

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_patientId == null || _userId == null) return;

    // If the dates are not manually edited, keep the automatic cycle behavior.
    _applyCycleSuggestionIfNeeded();

    final item = ReproductiveHealthModel(
      id: _item?.id,
      patientId: _patientId!,
      hasMenstrualCycle: hasMenstrualCycle,
      cycleRegular: cycleRegular,
      cyclePainful: cyclePainful,
      painLevel: painLevel?.toString(),
      lastPeriodStart: _lastPeriodStart,
      lastPeriodEnd: _lastPeriodEnd,
      currentlyPregnant: currentlyPregnant,
      pregnancyTermWeeks: int.tryParse(_pregnancyWeeksController.text.trim()),
      gestity: int.tryParse(_gestityController.text.trim()),
      parity: int.tryParse(_parityController.text.trim()),
      abortions: int.tryParse(_abortionsController.text.trim()),
      pubertyAge: int.tryParse(_pubertyAgeController.text.trim()),
      breastExamNotes: _breastNotesController.text.trim().isEmpty
          ? null
          : _breastNotesController.text.trim(),
      pregnancyHistory: _pregnancyHistoryController.text.trim().isEmpty
          ? null
          : _pregnancyHistoryController.text.trim(),
      birthHistory: _birthHistoryController.text.trim().isEmpty
          ? null
          : _birthHistoryController.text.trim(),
      abortionHistory: _abortionHistoryController.text.trim().isEmpty
          ? null
          : _abortionHistoryController.text.trim(),
    );

    await _service.saveReproductiveHealth(
      item: item,
      performedByUserId: _userId!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reproductive health saved')),
    );
  }

  @override
  void dispose() {
    _lastStartController.dispose();
    _lastEndController.dispose();
    _pregnancyWeeksController.dispose();
    _gestityController.dispose();
    _parityController.dispose();
    _abortionsController.dispose();
    _pubertyAgeController.dispose();
    _breastNotesController.dispose();
    _pregnancyHistoryController.dispose();
    _birthHistoryController.dispose();
    _abortionHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sex != null && _sex != 'female') {
      return Scaffold(
        appBar: AppBar(title: const Text('Reproductive health')),
        body: const Center(
          child: Text('This section is mainly for female patients.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reproductive health')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Same order as the database table columns.
          SwitchListTile(
            value: hasMenstrualCycle ?? false,
            onChanged: (v) => setState(() => hasMenstrualCycle = v),
            title: const Text('Has menstrual cycle'),
          ),
          SwitchListTile(
            value: cycleRegular ?? false,
            onChanged: (v) => setState(() => cycleRegular = v),
            title: const Text('Cycle regular'),
          ),
          SwitchListTile(
            value: cyclePainful ?? false,
            onChanged: (v) => setState(() => cyclePainful = v),
            title: const Text('Cycle painful'),
          ),
          const SizedBox(height: 12),

          // Pain level as a 1-10 selector.
          DropdownButtonFormField<int>(
            initialValue: painLevel,
            items: _painLevels
                .map(
                  (level) => DropdownMenuItem<int>(
                value: level,
                child: Text(level.toString()),
              ),
            )
                .toList(),
            onChanged: (value) => setState(() => painLevel = value),
            decoration: const InputDecoration(
              labelText: 'Pain level',
            ),
          ),
          const SizedBox(height: 12),

          // Calendar picker for date fields.
          TextField(
            controller: _lastStartController,
            readOnly: true,
            onTap: () => _pickDate(
              controller: _lastStartController,
              isStartDate: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Last period start',
              hintText: 'Pick a date from the calendar',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastEndController,
            readOnly: true,
            onTap: () => _pickDate(
              controller: _lastEndController,
              isStartDate: false,
            ),
            decoration: const InputDecoration(
              labelText: 'Last period end',
              hintText: 'Pick a date from the calendar',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            value: currentlyPregnant ?? false,
            onChanged: (v) => setState(() => currentlyPregnant = v),
            title: const Text('Currently pregnant'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _pregnancyWeeksController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pregnancy term weeks',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _gestityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Gestity',
              hintText:
              'Number of children you were pregnant with in total',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _parityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Parity',
              hintText: 'Number of children given birth to',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _abortionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Abortions',
              hintText: 'The number of abortions',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _pubertyAgeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Puberty age',
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _breastNotesController,
            decoration: const InputDecoration(
              labelText: 'Breast exam notes',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _pregnancyHistoryController,
            decoration: const InputDecoration(
              labelText: 'Pregnancy history',
              hintText:
              'List complications with "-" in between for distinction',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _birthHistoryController,
            decoration: const InputDecoration(
              labelText: 'Birth history',
              hintText:
              'List complications with "-" in between for distinction',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _abortionHistoryController,
            decoration: const InputDecoration(
              labelText: 'Abortion history',
              hintText:
              'List complications with "-" in between for distinction',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            child: const Text('Save reproductive health'),
          ),
        ],
      ),
    );
  }
}