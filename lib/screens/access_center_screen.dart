import 'package:flutter/material.dart';

import '../models/access_grant_view_model.dart';
import '../services/access_service.dart';
import '../widgets/access_grant_card.dart';
import 'access_inbox_screen.dart';
import 'patient_access_management_screen.dart';

/// Single entry for the split access flow: inbox + management tabs.
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
  final AccessService _accessService = AccessService();

  bool _loadingGrants = false;
  List<AccessGrantViewModel> _myGrants = [];

  @override
  void initState() {
    super.initState();
    final tabCount = widget.isOwnerContext ? 2 : 2;
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

  Future<void> _loadMyGrants() async {
    setState(() => _loadingGrants = true);
    try {
      final grants = await _accessService.fetchMyActiveGrantViews();
      if (!mounted) return;
      setState(() {
        _myGrants = grants;
        _loadingGrants = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGrants = false);
    }
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
            'Patients you can access (read-only here). Accept new invites '
            'from the Inbox tab.',
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
              (grant) => AccessGrantCard(
                grant: grant,
                canManage: false,
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
