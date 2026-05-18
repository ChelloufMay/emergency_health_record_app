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
  final _expiresAtController = TextEditingController();

  String? _resolvePatientId() {
    return widget.patientId ??
        PatientSessionService.instance.current?.patientId;
  }

  Map<String, dynamic> _buildQrEnvelope({
    required String token,
    required String patientId,
    required Map<String, dynamic>? summary,
  }) {
    final envelope = <String, dynamic>{
      'type': 'emergency_access_token',
      'token': token,
      'patient_id': patientId,
      'issued_at': DateTime.now().toIso8601String(),
    };

    // The DB now returns the same shape from resolve_emergency_access_token().
    // Keeping this snapshot in the QR gives the emergency screen useful
    // fallback data if a scan happens with poor connectivity.
    if (summary != null) {
      envelope['offline_summary'] = summary;
    }

    return envelope;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _expiresAtController.dispose();
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

    // The owner QR should now represent the emergency token lifecycle,
    // not just a patient ID. The QR payload is a small JSON envelope that
    // carries the token string and can be decoded by the emergency screen.
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
      _summary = summary;
      _tokenRow = tokenRow;
      _qrData = tokenRow?.token == null
          ? ''
          : EmergencyPayloadService.encodePayload(
              _buildQrEnvelope(
                token: tokenRow!.token!,
                patientId: patientId,
                summary: summary,
              ),
            );
      _loading = false;
    });
  }

  Future<void> _createToken() async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final parsedExpiry = _expiresAtController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(_expiresAtController.text.trim());

      // Insert minimal fields only; the DB generates the token value.
      final response = await _supabase
          .from('emergency_access_tokens')
          .insert({
            'patient_id': patientId,
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            'expires_at': parsedExpiry?.toIso8601String(),
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
            : EmergencyPayloadService.encodePayload(
                _buildQrEnvelope(
                  token: tokenRow.token!,
                  patientId: patientId,
                  summary: _summary,
                ),
              );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emergency token created.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Token creation failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revokeToken() async {
    final tokenId = _tokenRow?.id;
    if (tokenId == null) return;

    setState(() => _saving = true);

    try {
      await _supabase
          .from('emergency_access_tokens')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tokenId);

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emergency token revoked.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Revoke failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyQrData() async {
    if (_qrData.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _qrData));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR payload copied.')));
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
                        // This QR encodes the token envelope, not a raw patient ID.
                        QrImageView(data: _qrData, size: 240),
                        const SizedBox(height: 16),
                        SelectableText(_qrData, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _copyQrData,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy QR payload'),
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
                TextField(
                  controller: _expiresAtController,
                  decoration: const InputDecoration(
                    labelText: 'Expires at',
                    hintText: 'ISO datetime, for example 2026-05-16T18:00:00',
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
