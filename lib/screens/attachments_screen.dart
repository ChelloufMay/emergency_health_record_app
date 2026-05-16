import 'package:flutter/material.dart';

import '../models/attachment_model.dart';
import '../models/user_model.dart';
import '../services/attachment_service.dart';
import '../services/patient_service.dart';
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
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  List<AttachmentModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() {
    // Keep the attachment list scoped to the same patient context as the rest
    // of the owner dashboard.
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

  Future<void> _openEditor({AttachmentModel? initial}) async {
    if (!widget.canEdit) return;

    final performedByUserId = await _patientService.ensureAppUserId();
    if (performedByUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve current app user.')),
      );
      return;
    }

    final fileNameController = TextEditingController(text: initial?.fileName ?? '');
    final fileTypeController = TextEditingController(text: initial?.fileType ?? '');
    final storagePathController = TextEditingController(text: initial?.storagePath ?? '');
    final descriptionController = TextEditingController(text: initial?.description ?? '');
    final dateController = TextEditingController(
      text: initial?.documentDate?.toIso8601String().split('T').first ?? '',
    );
    String fileKind = initial?.fileKind ?? 'other';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add attachment' : 'Edit attachment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Attachments stay in their own table and storage path, so the UI
                // exposes the file metadata clearly.
                TextField(
                  controller: fileNameController,
                  decoration: const InputDecoration(labelText: 'File name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: fileKind,
                  decoration: const InputDecoration(labelText: 'Kind'),
                  items: const [
                    DropdownMenuItem(value: 'lab_result', child: Text('Lab result')),
                    DropdownMenuItem(value: 'xray', child: Text('X-ray')),
                    DropdownMenuItem(value: 'scan', child: Text('Scan')),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => fileKind = v ?? 'other',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fileTypeController,
                  decoration: const InputDecoration(labelText: 'File type / mime type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: storagePathController,
                  decoration: const InputDecoration(labelText: 'Storage path'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Document date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      fileNameController.dispose();
      fileTypeController.dispose();
      storagePathController.dispose();
      descriptionController.dispose();
      dateController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = AttachmentModel(
      id: initial?.id,
      patientId: patientId,
      fileName: fileNameController.text.trim(),
      fileKind: fileKind,
      fileType: fileTypeController.text.trim().isEmpty ? null : fileTypeController.text.trim(),
      storagePath: storagePathController.text.trim(),
      documentDate: dateController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(dateController.text.trim()),
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      uploadedByUserId: initial?.uploadedByUserId,
    );

    await _service.save(
      attachment: model,
      patientId: patientId,
      performedByUserId: performedByUserId,
    );

    fileNameController.dispose();
    fileTypeController.dispose();
    storagePathController.dispose();
    descriptionController.dispose();
    dateController.dispose();

    await _load();
  }

  Future<void> _deleteItem(AttachmentModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    await _service.delete(patientId: patientId, id: item.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachments'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit)
            IconButton(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
            ),
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
                  if (item.documentDate != null)
                    'Date: ${item.documentDate!.toIso8601String().split('T').first}',
                  if ((item.description ?? '').isNotEmpty) 'Description: ${item.description}',
                  if ((item.storagePath).isNotEmpty) 'Path: ${item.storagePath}',
                ].join('\n')),
                trailing: widget.canEdit
                    ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _openEditor(initial: item);
                    } else if (value == 'delete') {
                      await _deleteItem(item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
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