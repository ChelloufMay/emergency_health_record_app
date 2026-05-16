import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_risk_prediction_model.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _patientId;
  List<PatientRiskPredictionModel> _predictions = [];

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // This screen is read-only. Predictions are inserted by service role
    // workflows, and the DB policy already allows authenticated reads.
    final rows = await _supabase
        .from('patient_risk_predictions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    final predictions = (rows as List)
        .map(
          (row) => PatientRiskPredictionModel.fromMap(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _predictions = predictions;
      _loading = false;
    });
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _factorsWidget(List<dynamic> factors) {
    if (factors.isEmpty) return const Text('No main factors recorded.');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: factors
          .map((factor) => Chip(label: Text(factor.toString())))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk predictions'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : _predictions.isEmpty
          ? const Center(child: Text('No predictions available.'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _predictions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prediction.modelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(prediction.riskLevel),
                        backgroundColor:
                        _riskColor(prediction.riskLevel)
                            .withOpacity(0.12),
                        side: BorderSide(
                          color: _riskColor(prediction.riskLevel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${prediction.riskScore.toStringAsFixed(4)}',
                  ),
                  Text(
                    'Version: ${prediction.modelVersion ?? 'Unknown'}',
                  ),
                  Text(
                    'Created: ${prediction.createdAt?.toIso8601String() ?? 'Unknown'}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Main factors',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _factorsWidget(prediction.mainFactors),
                  if ((prediction.explanation ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Explanation',
                      style:
                      TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(prediction.explanation!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}