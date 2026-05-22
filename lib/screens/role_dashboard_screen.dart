import 'package:flutter/material.dart';

import '../models/patient_access_row_model.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';
import '../services/patient_session_service.dart';
import 'patient_detail_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;

  const RoleDashboardScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final AccessService _service = AccessService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  List<PatientAccessRowModel> _rows = [];
  List<Map<String, dynamic>> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final rows = await _service.fetchMyAccessDashboardRows();

      // CHANGED: use the invite view that includes patient details.
      final invites = await _service.fetchMyPendingInvitesWithPatientDetails();

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _pendingInvites = invites;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load dashboard: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openPatient(PatientAccessRowModel row) {
    PatientSessionService.instance.setSession(
      patientId: row.patientId,
      patientName: row.patientName,
      permission: row.permission,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          patientId: row.patientId,
          patientName: row.patientName,
          permission: row.permission,
          roleLabel: row.role,
        ),
      ),
    );
  }

  String _invitePatientName(Map<String, dynamic> invite) {
    // CHANGED: build the name from the joined profile fields when possible.
    final fromView = invite['patient_name']?.toString().trim();
    if (fromView != null && fromView.isNotEmpty) return fromView;

    final first = invite['first_name']?.toString().trim() ?? '';
    final last = invite['family_name']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;

    return 'Unknown patient';
  }

  String _inviteToken(Map<String, dynamic> invite) {
    final token = invite['invite_token']?.toString() ??
        invite['token']?.toString() ??
        invite['access_invite_token']?.toString() ??
        '';
    return token.trim();
  }

  Future<void> _acceptInvite(String inviteToken) async {
    await _service.acceptInvite(inviteToken);
    await _loadData();
  }

  Future<void> _rejectInvite(String inviteToken) async {
    await _service.rejectInvite(inviteToken);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? BackButton(
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.subtitle),
              ),
            ),
            const SizedBox(height: 16),
            if (_pendingInvites.isNotEmpty) ...[
              Text(
                'Pending invites',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ..._pendingInvites.map((invite) {
                final token = _inviteToken(invite);
                final patientName = _invitePatientName(invite);
                final permission =
                    invite['permission']?.toString() ?? 'read';

                return Card(
                  child: ListTile(
                    title: Text(patientName),
                    subtitle: Text('Permission: $permission'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          onPressed: token.isEmpty
                              ? null
                              : () => _acceptInvite(token),
                          icon: const Icon(Icons.check),
                          tooltip: 'Accept',
                        ),
                        IconButton(
                          onPressed: token.isEmpty
                              ? null
                              : () => _rejectInvite(token),
                          icon: const Icon(Icons.close),
                          tooltip: 'Reject',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            Text(
              'Accessible patients',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.emptyMessage),
                ),
              )
            else
              ..._rows.map(
                    (row) => Card(
                  child: ListTile(
                    leading: Icon(
                      row.isEmergencyOnly
                          ? Icons.warning_amber_outlined
                          : row.canEdit
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(row.patientName),
                    subtitle: Text(
                      'Permission: ${row.permission} • Role: ${row.role}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPatient(row),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}