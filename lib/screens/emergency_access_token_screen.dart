import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/emergency_access_token_model.dart';
import '../screens/emergency_screen.dart';
import '../services/emergency_access_token_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

// Managing emergency "break-glass" access tokens, allowing patients to generate, view, and revoke temporary access codes for medical emergencies.
class EmergencyAccessTokenScreen extends StatefulWidget {
  final String? patientId;

  const EmergencyAccessTokenScreen({super.key, this.patientId});

  @override
  State<EmergencyAccessTokenScreen> createState() =>
      _EmergencyAccessTokenScreenState();
}

class _EmergencyAccessTokenScreenState
    extends State<EmergencyAccessTokenScreen> {
  final EmergencyAccessTokenService _service = EmergencyAccessTokenService();
  final PatientService _patientService = PatientService();

  // Replaced the raw days text field with a proper calendar date picker.
  DateTime? _selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _patientId;
  List<EmergencyAccessTokenModel> _tokens = [];

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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Use DB default';
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _shortToken(String? token) {
    final value = token ?? '';
    if (value.length <= 12) return value;
    return '${value.substring(0, 8)}…${value.substring(value.length - 4)}';
  }

  String _buildEmergencyPayload(String token) {
    return 'healthapp://emergency?payload=${Uri.encodeComponent(token)}';
  }

  // Resolves the patient ID from widget arguments, session, or identity
  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }

    final session = PatientSessionService.instance.current;
    if (session?.patientId.isNotEmpty == true) return session!.patientId;

    final identity = await _patientService.resolveIdentity();
    return identity?.patientProfileId;
  }

  // Displays a date picker for selecting the token's expiry date
  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: _selectedExpiryDate ?? now.add(const Duration(days: 30)),
      helpText: 'Select expiry date',
    );

    if (picked == null) return;
    setState(() => _selectedExpiryDate = picked);
  }

  // Fetches the list of emergency access tokens for the patient
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientId = await _resolvePatientId();
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _error = 'No patient profile found for token management.';
          _loading = false;
        });
        return;
      }

      final list = await _service.fetchByPatient(patientId);
      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _tokens = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tokens: $e';
        _loading = false;
      });
    }
  }

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copied to clipboard.')),
    );
  }

  Future<void> _copyEmergencyPayload(String token) async {
    final payload = _buildEmergencyPayload(token);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency link copied to clipboard.')),
    );
  }

  void _openEmergencyView(String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyScreen(
          payload: token,
          patientId: _patientId,
        ),
      ),
    );
  }

  // Generates a new emergency access token with the specified expiry and notes.
  Future<void> _createToken() async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    final notes = _notesController.text.trim();

    setState(() => _saving = true);

    try {
      final currentUser = await _patientService.fetchCurrentAppUserRow();
      final createdByUserId = currentUser?['id']?.toString();

      // Use a date picked from the calendar and convert it to a timestamp.
      final expiresAt = _selectedExpiryDate == null
          ? null
          : DateTime(
        _selectedExpiryDate!.year,
        _selectedExpiryDate!.month,
        _selectedExpiryDate!.day,
        23,
        59,
        59,
      );

      final created = await _service.create(
        patientId: patientId,
        createdByUserId: createdByUserId,
        notes: notes.isEmpty ? null : notes,
        expiresAt: expiresAt,
      );

      if (!mounted) return;
      _notesController.clear();
      setState(() {
        _tokens = [created, ..._tokens];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency token created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Revokes an existing emergency access token.
  Future<void> _revokeToken(EmergencyAccessTokenModel token) async {
    final tokenId = token.id;
    if (tokenId == null || tokenId.isEmpty) return;

    try {
      await _service.revoke(tokenId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token revoked.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revoke failed: $e')),
      );
    }
  }

  Widget _buildTokenCard(EmergencyAccessTokenModel token) {
    final tokenValue = token.token ?? '';
    final isActive = token.isActive && token.revokedAt == null;

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
                    _shortToken(tokenValue),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(isActive ? 'Active' : 'Revoked')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created: ${_formatDateTime(token.createdAt)}'),
            const SizedBox(height: 4),
            Text('Expires: ${_formatDateTime(token.expiresAt)}'),
            if ((token.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${token.notes}'),
            ],
            if (token.revokedAt != null) ...[
              const SizedBox(height: 4),
              Text('Revoked: ${_formatDateTime(token.revokedAt)}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: tokenValue.isEmpty
                      ? null
                      : () => _copyToken(tokenValue),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy token'),
                ),
                OutlinedButton.icon(
                  onPressed: tokenValue.isEmpty
                      ? null
                      : () => _copyEmergencyPayload(tokenValue),
                  icon: const Icon(Icons.link),
                  label: const Text('Copy emergency link'),
                ),
                OutlinedButton.icon(
                  onPressed: tokenValue.isEmpty
                      ? null
                      : () => _openEmergencyView(tokenValue),
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('Open emergency view'),
                ),
                if (isActive)
                  FilledButton.icon(
                    onPressed: () => _revokeToken(token),
                    icon: const Icon(Icons.block),
                    label: const Text('Revoke'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency access tokens'),
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
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Create a new break-glass token',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickExpiryDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry date',
                  helperText: 'Pick a date from the calendar',
                  border: OutlineInputBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_formatDate(_selectedExpiryDate)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional note for this token',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _createToken,
              icon: const Icon(Icons.add),
              label: _saving
                  ? const Text('Creating...')
                  : const Text('Create token'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tokens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${_tokens.length} total'),
              ],
            ),
            const SizedBox(height: 12),
            if (_tokens.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text('No emergency access tokens yet.'),
                ),
              )
            else
              ..._tokens.map(_buildTokenCard),
          ],
        ),
      ),
    );
  }
}