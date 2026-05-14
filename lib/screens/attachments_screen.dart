import 'package:flutter/material.dart';

import '../models/attachment_model.dart';
import '../services/attachment_service.dart';
import '../services/patient_session_service.dart';

class AttachmentsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const AttachmentsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  final AttachmentService _service = AttachmentService();

  bool _loading = true;
  String? _patientId;
  List<AttachmentModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final items = await _service.fetchByPatient(patientId);
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _deleteItem(AttachmentModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    await _service.delete(
      patientId: patientId,
      id: item.id!,
      performedByUserId: 'current',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachments'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(item.fileName),
                subtitle: Text([
                  'Kind: ${item.fileKind}',
                  if ((item.fileType ?? '').isNotEmpty) 'Type: ${item.fileType}',
                  if (item.documentDate != null) 'Date: ${item.documentDate!.toIso8601String().split('T').first}',
                  if ((item.description ?? '').isNotEmpty) 'Description: ${item.description}',
                ].join('\n')),
                trailing: widget.canEdit
                    ? IconButton(
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(Icons.delete),
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}