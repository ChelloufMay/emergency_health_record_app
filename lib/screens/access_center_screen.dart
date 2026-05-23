import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_view_model.dart';
import '../widgets/access_grant_card.dart';
import 'access_inbox_screen.dart';
import 'caregiver_patient_detail_screen.dart';
import 'patient_access_management_screen.dart';

/// Single entry for the split access flow: inbox + management tabs.
///
/// CHANGED:
/// - Caregiver "My access" now loads directly from the active grants table for
///   the signed-in app user instead of relying on the owner dashboard path.
/// - Each patient card is tappable and opens the caregiver detail screen.
/// - The card label is the patient name, not the grantee name.
class AccessCenterScreen extends StatefulWidget {
  final int initialTab;
  final String? patientId;
  final bool isOwnerContext;

  const AccessCenterScreen({
    super.key,
    this.initialTab = 0,
    this.patientId,
    this.isOwnerContext = false,
  });

  @override
  State<AccessCenterScreen> createState() => _AccessCenterScreenState();
}

class _AccessCenterScreenState extends State<AccessCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loadingGrants = false;
  List<AccessGrantViewModel> _myGrants = [];

  @override
  void initState() {
    super.initState();

    final tabCount = 2;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, tabCount - 1),
    );

    if (!widget.isOwnerContext) {
      _loadMyGrants();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _currentAppUserId() async {
    final value = await _supabase.rpc('current_app_user_id');
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  Future<Map<String, dynamic>?> _patientNameRow(String patientId) async {
    // CHANGED: use the existing DB helper for a lightweight display label.
    final result = await _supabase.rpc(
      'get_patient_dashboard_details',
      params: {'_patient_id': patientId},
    );

    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  String _fullNameFromMap(Map<String, dynamic> row) {
    final first = row['first_name']?.toString().trim() ?? '';
    final family = row['family_name']?.toString().trim() ?? '';
    return [first, family].where((p) => p.isNotEmpty).join(' ').trim();
  }

  Future<void> _loadMyGrants() async {
    if (mounted) setState(() => _loadingGrants = true);

    try {
      final currentUserId = await _currentAppUserId();
      if (currentUserId == null) {
        if (!mounted) return;
        setState(() {
          _myGrants = [];
          _loadingGrants = false;
        });
        return;
      }

      // CHANGED: read the caregiver's own active grants directly.
      // This avoids depending on the owner dashboard view for caregiver access.
      final rows = await _supabase
          .from('access_grants')
          .select(
        'id, patient_id, grantee_user_id, grantee_role, permission, status, '
            'granted_by_user_id, granted_at, expires_at, source_invite_id, notes, '
            'created_at, updated_at',
      )
          .eq('grantee_user_id', currentUserId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final rawRows = rows;
      final views = <AccessGrantViewModel>[];

      for (final item in rawRows) {
        final row = Map<String, dynamic>.from(item as Map);
        final patientId = row['patient_id']?.toString().trim() ?? '';

        if (patientId.isNotEmpty) {
          final patientRow = await _patientNameRow(patientId);
          final patientName = patientRow == null
              ? ''
              : _fullNameFromMap(patientRow);

          // CHANGED: provide a patient label for the caregiver card.
          if (patientName.isNotEmpty) {
            row['patient_name'] = patientName;
            row['patient_full_name'] = patientName;
          }

          // CHANGED: keep the old dashboard model happy, but show the patient
          // in the card title via [titleLabel] below.
          row['grantee_name'] = patientName.isNotEmpty ? patientName : 'Connected patient';
        }

        views.add(AccessGrantViewModel.fromDashboardRow(row));
      }

      if (!mounted) return;
      setState(() {
        _myGrants = views;
        _loadingGrants = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _myGrants = [];
          _loadingGrants = false;
        });
      }
    }
  }

  void _openPatient(AccessGrantViewModel grant) {
    if (grant.patientId.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaregiverPatientDetailScreen(patientId: grant.patientId),
      ),
    );
  }

  Widget _myAccessTab() {
    if (_loadingGrants) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMyGrants,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Patients you can access. Tap a patient card to open their record.',
          ),
          const SizedBox(height: 12),
          if (_myGrants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active access grants.'),
              ),
            )
          else
            ..._myGrants.map(
                  (grant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AccessGrantCard(
                  grant: grant,
                  canManage: false,
                  // CHANGED: show the patient name here, not the caregiver label.
                  titleLabel: grant.patientName.isNotEmpty ? grant.patientName : null,
                  onTap: () => _openPatient(grant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Inbox', icon: Icon(Icons.inbox_outlined)),
            Tab(
              text: widget.isOwnerContext ? 'Manage' : 'My access',
              icon: Icon(
                widget.isOwnerContext
                    ? Icons.admin_panel_settings_outlined
                    : Icons.people_outline,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AccessInboxScreen(embedded: true),
          widget.isOwnerContext
              ? PatientAccessManagementScreen(
            patientId: widget.patientId,
            embedded: true,
          )
              : _myAccessTab(),
        ],
      ),
    );
  }
}