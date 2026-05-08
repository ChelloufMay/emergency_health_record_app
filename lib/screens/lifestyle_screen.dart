import 'package:flutter/material.dart';
import '../models/lifestyle_model.dart';
import '../services/lifestyle_service.dart';
import '../services/patient_service.dart';

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  final _service = LifestyleService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  LifestyleModel? _item;

  final _workController = TextEditingController();
  final _packsController = TextEditingController();
  final _yearsController = TextEditingController();
  final _drugTypeController = TextEditingController();
  final _drugQuantityController = TextEditingController();
  final _chichaYearsController = TextEditingController();
  final _alcoholController = TextEditingController();
  final _foodController = TextEditingController();
  final _milkController = TextEditingController();

  bool? livesAlone;
  bool? hasCaregiver;
  bool? stairsInHome;
  String socioeconomicClass = 'unknown';
  bool? smoking;
  bool? drugs;
  bool? chicha;

  final List<String> _waterTypeOptions = const [
    'tap water',
    'bottled water',
    'filtered water',
    'mineral water',
    'spring water',
    'well water',
    'boiled water',
    'other',
  ];

  String _waterType = 'tap water';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _normalizeWaterType(String? value) {
    if (value == null || value.trim().isEmpty) return 'tap water';
    final lower = value.trim().toLowerCase();

    for (final option in _waterTypeOptions) {
      if (option.toLowerCase() == lower) return option;
    }
    return 'other';
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _item = await _service.fetchLifestyle(_patientId!);

    if (_item != null) {
      livesAlone = _item!.livesAlone;
      hasCaregiver = _item!.hasCaregiver;
      stairsInHome = _item!.stairsInHome;
      socioeconomicClass = _item!.socioeconomicClass;
      smoking = _item!.smoking;
      drugs = _item!.drugs;
      chicha = _item!.chicha;

      _workController.text = _item!.workStatus ?? '';
      _packsController.text = _item!.packsPerDay?.toString() ?? '';
      _yearsController.text = _item!.smokingYears?.toString() ?? '';
      _drugTypeController.text = _item!.drugType ?? '';
      _drugQuantityController.text = _item!.drugQuantity ?? '';
      _chichaYearsController.text = _item!.chichaYears?.toString() ?? '';
      _alcoholController.text = _item!.alcoholFrequency ?? '';
      _foodController.text = _item!.foodQuality ?? '';
      _milkController.text = _item!.milkType ?? '';
      _waterType = _normalizeWaterType(_item!.waterType);
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_patientId == null || _userId == null) return;

    final item = LifestyleModel(
      id: _item?.id,
      patientId: _patientId!,
      livesAlone: livesAlone,
      hasCaregiver: hasCaregiver,
      stairsInHome: stairsInHome,
      socioeconomicClass: socioeconomicClass,
      workStatus: _workController.text.trim(),
      smoking: smoking,
      packsPerDay: double.tryParse(_packsController.text.trim()),
      smokingYears: double.tryParse(_yearsController.text.trim()),
      drugs: drugs,
      drugType: _drugTypeController.text.trim(),
      drugQuantity: _drugQuantityController.text.trim(),
      chicha: chicha,
      chichaYears: double.tryParse(_chichaYearsController.text.trim()),
      alcoholFrequency: _alcoholController.text.trim(),
      foodQuality: _foodController.text.trim(),
      milkType: _milkController.text.trim(),
      waterType: _waterType,
    );

    await _service.saveLifestyle(
      lifestyle: item,
      performedByUserId: _userId!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lifestyle saved')),
    );
  }

  @override
  void dispose() {
    _workController.dispose();
    _packsController.dispose();
    _yearsController.dispose();
    _drugTypeController.dispose();
    _drugQuantityController.dispose();
    _chichaYearsController.dispose();
    _alcoholController.dispose();
    _foodController.dispose();
    _milkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lifestyle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: livesAlone ?? false,
            onChanged: (v) => setState(() => livesAlone = v),
            title: const Text('Lives alone'),
          ),
          SwitchListTile(
            value: hasCaregiver ?? false,
            onChanged: (v) => setState(() => hasCaregiver = v),
            title: const Text('Has caregiver'),
          ),
          SwitchListTile(
            value: stairsInHome ?? false,
            onChanged: (v) => setState(() => stairsInHome = v),
            title: const Text('Stairs in home'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: socioeconomicClass,
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'middle', child: Text('Middle')),
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
            ],
            onChanged: (v) =>
                setState(() => socioeconomicClass = v ?? 'unknown'),
            decoration: const InputDecoration(
              labelText: 'Socioeconomic class',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _workController,
            decoration: const InputDecoration(
              labelText: 'Work status',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: smoking ?? false,
            onChanged: (v) => setState(() => smoking = v),
            title: const Text('Smoking'),
          ),
          TextField(
            controller: _packsController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Packs/day',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yearsController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Smoking years',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: drugs ?? false,
            onChanged: (v) => setState(() => drugs = v),
            title: const Text('Drugs'),
          ),
          TextField(
            controller: _drugTypeController,
            decoration: const InputDecoration(
              labelText: 'Drug type',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _drugQuantityController,
            decoration: const InputDecoration(
              labelText: 'Drug quantity',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: chicha ?? false,
            onChanged: (v) => setState(() => chicha = v),
            title: const Text('Chicha'),
          ),
          TextField(
            controller: _chichaYearsController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Chicha years',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alcoholController,
            decoration: const InputDecoration(
              labelText: 'Alcohol frequency',
              hintText:
              'If yes, how many days/week. If not, write "Does not consume".',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _foodController,
            decoration: const InputDecoration(
              labelText: 'Food quality',
              hintText:
              'How much junk food is consumed per week.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _milkController,
            decoration: const InputDecoration(
              labelText: 'Milk type',
              hintText:
              'Example: pasteurised cow milk, non-pasteurised goat milk, etc.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _waterType,
            items: _waterTypeOptions
                .map(
                  (type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _waterType = v ?? 'other'),
            decoration: const InputDecoration(
              labelText: 'Water type',
              hintText: 'Select the type of water consumed',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save lifestyle'),
          ),
        ],
      ),
    );
  }
}