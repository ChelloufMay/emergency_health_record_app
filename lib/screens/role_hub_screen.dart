import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RoleHubScreen extends StatefulWidget {
  final String title;
  final String description;
  final String dashboardRoute;
  final String accessInboxRoute;
  final String accessManagementRoute; // kept for backward compatibility
  final String profileRoute;
  final String settingsRoute;

  const RoleHubScreen({
    super.key,
    required this.title,
    required this.description,
    required this.dashboardRoute,
    required this.accessInboxRoute,
    required this.accessManagementRoute,
    required this.profileRoute,
    required this.settingsRoute,
  });

  @override
  State<RoleHubScreen> createState() => _RoleHubScreenState();
}

class _RoleHubScreenState extends State<RoleHubScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  Future<void> _signOut(BuildContext context) async {
    await _authService.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _open(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _tabTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Invites';
      case 2:
        return 'My profile';
      default:
        return 'Dashboard';
    }
  }

  String _tabSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Open the patients you can access.';
      case 1:
        return 'Manage incoming invites and history.';
      case 2:
        return 'Open your role profile.';
      default:
        return widget.description;
    }
  }

  IconData _tabIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.dashboard_outlined;
      case 1:
        return Icons.inbox_outlined;
      case 2:
        return Icons.badge_outlined;
      default:
        return Icons.dashboard_outlined;
    }
  }

  String _tabRoute() {
    switch (_selectedIndex) {
      case 0:
        return widget.dashboardRoute;
      case 1:
        return widget.accessInboxRoute;
      case 2:
        return widget.profileRoute;
      default:
        return widget.dashboardRoute;
    }
  }

  String _tabButtonLabel() {
    switch (_selectedIndex) {
      case 0:
        return 'Open dashboard';
      case 1:
        return 'Open invites';
      case 2:
        return 'Open profile';
      default:
        return 'Open';
    }
  }

  Widget _buildTabBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.description),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_tabIcon(), size: 32),
                const SizedBox(height: 12),
                Text(
                  _tabTitle(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_tabSubtitle()),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _open(context, _tabRoute()),
                  child: Text(_tabButtonLabel()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
            onPressed: () => _open(context, widget.settingsRoute),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _buildTabBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            label: 'Invites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            label: 'My profile',
          ),
        ],
      ),
    );
  }
}