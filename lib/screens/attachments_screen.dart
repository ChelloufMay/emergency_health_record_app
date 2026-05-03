import 'package:flutter/material.dart';
import '../models/attachment_model.dart';
import '../services/attachment_service.dart';
import '../services/patient_service.dart';

class AttachmentsScreen extends StatefulWidget {
  const AttachmentsScreen({super.key});

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  final _service = AttachmentService();
  final _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<AttachmentModel> _attachments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _attachments = await _service.fetchAttachments(_patientId!);

    setState(() => _loading = false);
  }

  Future<void> _addAttachment() async {
    final fileNameController = TextEditingController();
    final storagePathController = TextEditingController();
    final descriptionController = TextEditingController();
    String fileKind = 'other';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add attachment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: fileNameController, decoration: const InputDecoration(labelText: 'File name')),
              TextField(controller: storagePathController, decoration: const InputDecoration(labelText: 'Storage path')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: fileKind,
                items: const [
                  DropdownMenuItem(value: 'lab_result', child: Text('Lab result')),
                  DropdownMenuItem(value: 'xray', child: Text('X-ray')),
                  DropdownMenuItem(value: 'scan', child: Text('Scan')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => fileKind = v ?? 'other',
                decoration: const InputDecoration(labelText: 'File kind'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (save != true || _patientId == null || _userId == null) return;

    final item = AttachmentModel(
      id: 'temp',
      patientId: _patientId!,
      fileName: fileNameController.text.trim(),
      fileKind: fileKind,
      storagePath: storagePathController.text.trim(),
      description: descriptionController.text.trim(),
      uploadedByUserId: _userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _service.saveAttachment(
      attachment: item,
      uploadedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _deleteAttachment(AttachmentModel item) async {
    if (_patientId == null || _userId == null) return;

    await _service.deleteAttachment(
      id: item.id,
      patientId: item.patientId,
      performedByUserId: _userId!,
      fileName: item.fileName,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAttachment,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final item = _attachments[index];
          return Card(
            child: ListTile(
              title: Text(item.fileName),
              subtitle: Text('${item.fileKind} • ${item.storagePath}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteAttachment(item),
              ),
            ),
          );
        },
      ),
    );
  }
}