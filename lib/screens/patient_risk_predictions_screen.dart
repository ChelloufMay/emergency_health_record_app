import 'package:flutter/material.dart';

import '../models/patient_risk_prediction_model.dart';
import '../services/patient_risk_prediction_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class PatientRiskPredictionsScreen extends StatefulWidget {
  final String? patientId;

  const PatientRiskPredictionsScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientRiskPredictionsScreen> createState() =>
      _PatientRiskPredictionsScreenState();
}

class _PatientRiskPredictionsScreenState
    extends State<PatientRiskPredictionsScreen> {
  final PatientRiskPredictionService _service = PatientRiskPredictionService();
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _error;
  String? _patientName;
  List<PatientRiskPredictionModel> _predictions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatScore(double score) => '${(score * 100).toStringAsFixed(1)}%';

  String _describeFactor(dynamic factor) {
    if (factor is Map) {
      final map = Map<String, dynamic>.from(factor);
      final label = map['label']?.toString() ??
          map['name']?.toString() ??
          map['factor']?.toString() ??
          'Factor';
      final value = map['value']?.toString();
      final weight = map['weight']?.toString();

      final parts = <String>[label];
      if (value != null && value.trim().isNotEmpty) parts.add(value);
      if (weight != null && weight.trim().isNotEmpty) parts.add('weight: $weight');
      return parts.join(' • ');
    }
    return factor?.toString() ?? '-';
  }

  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }

    final session = PatientSessionService.instance.current;
    if (session?.patientId.isNotEmpty == true) return session!.patientId;

    final identity = await _patientService.resolveIdentity();
    return identity?.patientProfileId;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientId = await _resolvePatientId();
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _error = 'No patient profile found.';
          _loading = false;
        });
        return;
      }

      final identity = await _patientService.resolveIdentity();
      _patientName = identity?.patientProfileId != null ? 'Patient profile ${identity!.patientProfileId}' : null;

      final list = await _service.fetchByPatient(patientId);
      if (!mounted) return;
      setState(() {
        _predictions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load predictions: $e';
        _loading = false;
      });
    }
  }

  Widget _buildPredictionCard(PatientRiskPredictionModel prediction,
      {bool highlighted = false}) {
    final mainFactors = prediction.mainFactors;
    final snapshot = prediction.inputSnapshot;

    return Card(
      elevation: highlighted ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    highlighted ? 'Current risk result' : 'Prediction record',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(prediction.riskLevel.toUpperCase())),
              ],
            ),
            const SizedBox(height: 8),
            Text('Risk score: ${_formatScore(prediction.riskScore)}'),
            const SizedBox(height: 4),
            Text('Model: ${prediction.modelName}'),
            if ((prediction.modelVersion ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Version: ${prediction.modelVersion}'),
            ],
            const SizedBox(height: 4),
            Text('Created: ${_formatDateTime(prediction.createdAt)}'),
            if ((prediction.explanation ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Explanation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(prediction.explanation!),
            ],
            if (mainFactors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Main factors',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mainFactors
                    .map((factor) => Chip(label: Text(_describeFactor(factor))))
                    .toList(),
              ),
            ],
            if (snapshot.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Input snapshot'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(snapshot.toString()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _predictions.isNotEmpty ? _predictions.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk predictions'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _predictions.isEmpty
          ? const Center(
        child: Text('No risk predictions have been recorded yet.'),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if ((_patientName ?? '').trim().isNotEmpty) ...[
              Text(
                _patientName!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (current != null) _buildPredictionCard(current, highlighted: true),
            const SizedBox(height: 16),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._predictions.skip(1).map(
                  (prediction) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPredictionCard(prediction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
