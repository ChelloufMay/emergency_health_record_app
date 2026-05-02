import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// shows every recorded action on the patient's record, newest first
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) return;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (profileRow == null) {
        setState(() => _errorMessage = 'No profile found.');
        return;
      }

      final patientId = profileRow['id'] as String;

      final logs = await _supabase
          .from('audit_logs')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false);

      setState(
              () => _logs = List<Map<String, dynamic>>.from(logs as List));
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Failed to load logs: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconForAction(String? action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'view':
        return Icons.visibility_outlined;
      case 'break_glass':
        return Icons.emergency;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorForAction(String? action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'break_glass':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red)))
          : _logs.isEmpty
          ? const Center(
          child: Text('No audit events recorded yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _logs.length,
        itemBuilder: (ctx, i) {
          final log = _logs[i];
          final action = log['action'] as String?;
          final timestamp = log['timestamp'] as String?;
          final entityType =
              log['entity_type'] as String? ?? '';
          final fieldName = log['field_name'] as String?;

          return Card(
            child: ListTile(
              leading: Icon(
                _iconForAction(action),
                color: _colorForAction(action),
              ),
              title: Text(
                '${action?.toUpperCase() ?? 'UNKNOWN'} — $entityType',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fieldName != null)
                    Text('Field: $fieldName'),
                  // show what changed if both values are present
                  if (log['old_value'] != null &&
                      log['new_value'] != null)
                    Text(
                      '${log['old_value']} → ${log['new_value']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  if (log['break_glass_reason'] != null)
                    Text(
                      'Reason: ${log['break_glass_reason']}',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 11),
                    ),
                  if (timestamp != null)
                    Text(
                      // trim the milliseconds for readability
                      timestamp.length >= 19
                          ? timestamp
                          .substring(0, 19)
                          .replaceAll('T', ' ')
                          : timestamp,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}