import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_access_token_model.dart';
import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class QrScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const QrScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  bool _loading = true;
  bool _saving = false;
  String? _patientId;
  Map<String, dynamic>? _summary;
  EmergencyAccessTokenModel? _tokenRow;
  String _qrData = '';
  final _notesController = TextEditingController();
  DateTime? _selectedExpiresAt;

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }




  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Not set';

    final local = value.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd $hh:$min';
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedExpiresAt ?? now.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Select expiry date',
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedExpiresAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();

    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _patientId = null;
        _qrData = '';
      });
      return;
    }

    final summary = await _patientService.fetchEmergencySummary(patientId);

    final rows = await _supabase
        .from('emergency_access_tokens')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(1);

    EmergencyAccessTokenModel? tokenRow;
    if (rows.isNotEmpty) {
      tokenRow = EmergencyAccessTokenModel.fromMap(
        Map<String, dynamic>.from(rows.first as Map),
      );
    }

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _summary = summary == null ? null : Map<String, dynamic>.from(summary);
      _tokenRow = tokenRow;
      _qrData = tokenRow?.token == null
          ? ''
          : EmergencyPayloadService.buildEmergencyWebLink(
        tokenRow!.token!,
      );
      _loading = false;
    });
  }

  Future<void> _createToken() async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final response = await _supabase
          .from('emergency_access_tokens')
          .insert({
        'patient_id': patientId,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        // CHANGED: save the exact selected date + time.
        'expires_at': _selectedExpiresAt?.toIso8601String(),
      })
          .select()
          .single();

      final tokenRow = EmergencyAccessTokenModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );

      if (!mounted) return;
      setState(() {
        _tokenRow = tokenRow;
        _qrData = tokenRow.token == null
            ? ''
            : EmergencyPayloadService.buildEmergencyWebLink(
          tokenRow.token!,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency token created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token creation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revokeToken() async {
    final tokenId = _tokenRow?.id;
    if (tokenId == null) return;

    setState(() => _saving = true);

    try {
      await _supabase.from('emergency_access_tokens').update({
        'is_active': false,
        'revoked_at': DateTime.now().toIso8601String(),
      }).eq('id', tokenId);

      await _load();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Emergency token revoked. Scans should no longer resolve as active.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revoke failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyQrData() async {
    if (_qrData.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _qrData));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR link copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = [
      _summary?['first_name']?.toString() ?? '',
      _summary?['family_name']?.toString() ?? '',
    ].join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency token'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName.isEmpty
                        ? 'Emergency access token'
                        : patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Patient ID: $_patientId'),
                  Text(
                    'Current token: ${_tokenRow?.token ?? 'No active token'}',
                  ),
                  Text(
                    'Status: ${_tokenRow == null ? 'none' : (_tokenRow!.isActive ? 'active' : 'revoked')}',
                  ),
                  Text(
                    'Expires: ${_tokenRow?.expiresAt?.toIso8601String() ?? 'Not set'}',
                  ),
                  Text(
                    'Created at: ${_tokenRow?.createdAt?.toIso8601String() ?? 'Unknown'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_qrData.isNotEmpty)
            Center(
              child: Column(
                children: [
                  QrImageView(data: _qrData, size: 240),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan this code with the phone camera or a QR reader.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _copyQrData,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy QR link'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Create / update token',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional reason or context',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickExpiryDateTime,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Expiry date and time',
                helperText: 'Pick a date, then a time',
                border: OutlineInputBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _formatDateTime(_selectedExpiresAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _createToken,
                  child: _saving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Create token'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving || _tokenRow?.id == null
                      ? null
                      : _revokeToken,
                  child: const Text('Revoke token'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
