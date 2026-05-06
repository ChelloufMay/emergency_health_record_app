import 'package:file_picker/file_picker.dart';
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
    if (!mounted) return;

    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _attachments = await _service.fetchAttachments(_patientId!);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addAttachment() async {
    final fileNameController = TextEditingController();
    final descriptionController = TextEditingController();

    String fileKind = 'other';
    PlatformFile? selectedFile;
    DateTime? documentDate;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add attachment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          withData: true,
                        );

                        if (result == null || result.files.isEmpty) return;

                        setDialogState(() {
                          selectedFile = result.files.single;
                          if (fileNameController.text.trim().isEmpty) {
                            fileNameController.text = selectedFile!.name;
                          }
                        });
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        selectedFile == null ? 'Choose file' : 'Change file',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedFile != null)
                      Text(
                        'Selected: ${selectedFile!.name}'
                            '${selectedFile!.size != 0 ? ' • ${(selectedFile!.size / 1024).toStringAsFixed(1)} KB' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fileNameController,
                      decoration: const InputDecoration(
                        labelText: 'File name',
                        hintText: 'Leave as the original file name or change it',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: fileKind,
                      decoration: const InputDecoration(labelText: 'File kind'),
                      items: const [
                        DropdownMenuItem(
                          value: 'lab_result',
                          child: Text('Lab result'),
                        ),
                        DropdownMenuItem(
                          value: 'xray',
                          child: Text('X-ray'),
                        ),
                        DropdownMenuItem(
                          value: 'scan',
                          child: Text('Scan'),
                        ),
                        DropdownMenuItem(
                          value: 'pdf',
                          child: Text('PDF'),
                        ),
                        DropdownMenuItem(
                          value: 'image',
                          child: Text('Image'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          fileKind = v ?? 'other';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe what this file is about',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: documentDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            documentDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                        documentDate == null
                            ? 'Select document date (optional)'
                            : 'Document date: ${documentDate!.toIso8601String().split('T').first}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedFile == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || _patientId == null || _userId == null) {
      fileNameController.dispose();
      descriptionController.dispose();
      return;
    }

    try {
      await _service.uploadAttachment(
        patientId: _patientId!,
        uploadedByUserId: _userId!,
        file: selectedFile!,
        fileKind: fileKind,
        fileName: fileNameController.text.trim().isEmpty
            ? selectedFile!.name
            : fileNameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        documentDate: documentDate,
      );

      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attachment: $e')),
        );
      }
    } finally {
      fileNameController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _deleteAttachment(AttachmentModel item) async {
    if (_patientId == null || _userId == null) return;

    try {
      await _service.deleteAttachment(
        id: item.id,
        patientId: item.patientId,
        performedByUserId: _userId!,
        fileName: item.fileName,
        storagePath: item.storagePath,
      );

      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete attachment: $e')),
        );
      }
    }
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
          : _attachments.isEmpty
          ? const Center(child: Text('No attachments yet'))
          : ListView.builder(
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          final item = _attachments[index];

          return Card(
            child: ListTile(
              title: Text(item.fileName),
              subtitle: Text(
                [
                  'Kind: ${item.fileKind}',
                  if (item.documentDate != null)
                    'Document date: ${item.documentDate!.toIso8601String().split('T').first}',
                  if ((item.description ?? '').trim().isNotEmpty)
                    'Description: ${item.description}',
                ].join('\n'),
              ),
              isThreeLine: true,
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