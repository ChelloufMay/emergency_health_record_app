import 'package:flutter/material.dart';
import '../models/reproductive_health_model.dart';
import '../services/patient_service.dart';
import '../services/reproductive_health_service.dart';

class ReproductiveHealthScreen extends StatefulWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  State<ReproductiveHealthScreen> createState() => _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  final _service = ReproductiveHealthService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  String? _sex;
  ReproductiveHealthModel? _item;

  final _painLevelController = TextEditingController();
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
    _sex = identity.sex;
    _item = await _service.fetchReproductiveHealth(_patientId!);

    if (_item != null) {
      hasMenstrualCycle = _item!.hasMenstrualCycle;
      cycleRegular = _item!.cycleRegular;
      cyclePainful = _item!.cyclePainful;
      currentlyPregnant = _item!.currentlyPregnant;

      _painLevelController.text = _item!.painLevel ?? '';
      _lastStartController.text = _item!.lastPeriodStart?.toIso8601String().split('T').first ?? '';
      _lastEndController.text = _item!.lastPeriodEnd?.toIso8601String().split('T').first ?? '';
      _pregnancyWeeksController.text = _item!.pregnancyTermWeeks?.toString() ?? '';
      _gestityController.text = _item!.gestity?.toString() ?? '';
      _parityController.text = _item!.parity?.toString() ?? '';
      _abortionsController.text = _item!.abortions?.toString() ?? '';
      _pubertyAgeController.text = _item!.pubertyAge?.toString() ?? '';
      _breastNotesController.text = _item!.breastExamNotes ?? '';
      _pregnancyHistoryController.text = _item!.pregnancyHistory ?? '';
      _birthHistoryController.text = _item!.birthHistory ?? '';
      _abortionHistoryController.text = _item!.abortionHistory ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_patientId == null || _userId == null) return;

    final item = ReproductiveHealthModel(
      id: _item?.id,
      patientId: _patientId!,
      hasMenstrualCycle: hasMenstrualCycle,
      cycleRegular: cycleRegular,
      cyclePainful: cyclePainful,
      painLevel: _painLevelController.text.trim(),
      lastPeriodStart: _lastStartController.text.trim().isEmpty ? null : DateTime.tryParse(_lastStartController.text.trim()),
      lastPeriodEnd: _lastEndController.text.trim().isEmpty ? null : DateTime.tryParse(_lastEndController.text.trim()),
      currentlyPregnant: currentlyPregnant,
      pregnancyTermWeeks: int.tryParse(_pregnancyWeeksController.text.trim()),
      gestity: int.tryParse(_gestityController.text.trim()),
      parity: int.tryParse(_parityController.text.trim()),
      abortions: int.tryParse(_abortionsController.text.trim()),
      pubertyAge: int.tryParse(_pubertyAgeController.text.trim()),
      breastExamNotes: _breastNotesController.text.trim(),
      pregnancyHistory: _pregnancyHistoryController.text.trim(),
      birthHistory: _birthHistoryController.text.trim(),
      abortionHistory: _abortionHistoryController.text.trim(),
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
    _painLevelController.dispose();
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
          SwitchListTile(
            value: currentlyPregnant ?? false,
            onChanged: (v) => setState(() => currentlyPregnant = v),
            title: const Text('Currently pregnant'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _painLevelController, decoration: const InputDecoration(labelText: 'Pain level')),
          const SizedBox(height: 12),
          TextField(controller: _lastStartController, decoration: const InputDecoration(labelText: 'Last period start (YYYY-MM-DD)')),
          const SizedBox(height: 12),
          TextField(controller: _lastEndController, decoration: const InputDecoration(labelText: 'Last period end (YYYY-MM-DD)')),
          const SizedBox(height: 12),
          TextField(controller: _pregnancyWeeksController, decoration: const InputDecoration(labelText: 'Pregnancy term weeks')),
          const SizedBox(height: 12),
          TextField(controller: _gestityController, decoration: const InputDecoration(labelText: 'Gestity')),
          const SizedBox(height: 12),
          TextField(controller: _parityController, decoration: const InputDecoration(labelText: 'Parity')),
          const SizedBox(height: 12),
          TextField(controller: _abortionsController, decoration: const InputDecoration(labelText: 'Abortions')),
          const SizedBox(height: 12),
          TextField(controller: _pubertyAgeController, decoration: const InputDecoration(labelText: 'Puberty age')),
          const SizedBox(height: 12),
          TextField(controller: _breastNotesController, decoration: const InputDecoration(labelText: 'Breast exam notes')),
          const SizedBox(height: 12),
          TextField(controller: _pregnancyHistoryController, decoration: const InputDecoration(labelText: 'Pregnancy history')),
          const SizedBox(height: 12),
          TextField(controller: _birthHistoryController, decoration: const InputDecoration(labelText: 'Birth history')),
          const SizedBox(height: 12),
          TextField(controller: _abortionHistoryController, decoration: const InputDecoration(labelText: 'Abortion history')),
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