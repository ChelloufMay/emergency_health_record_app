import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment_model.dart';
import '../services/attachment_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

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
    return widget.patientId ??
        PatientSessionService.instance.current?.patientId;
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

  // CHANGED: attachment upload flow now picks a real file and uploads it to Storage.
  Future<void> _openEditor({AttachmentModel? initial}) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final performedByUserId = await _patientService.ensureAppUserId();
    if (performedByUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve current app user.')),
      );
      return;
    }

    final fileNameController = TextEditingController(
      text: initial?.fileName ?? '',
    );
    final fileTypeController = TextEditingController(
      text: initial?.fileType ?? '',
    );
    final storagePathController = TextEditingController(
      text: initial?.storagePath ?? '',
    );
    final descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );

    DateTime? documentDate = initial?.documentDate;
    String fileKind = initial?.fileKind ?? 'other';

    Uint8List? pickedBytes;
    String? pickedFileName;
    String? pickedExtension;

    Future<void> pickFile(StateSetter setDialogState) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null) return;

      pickedBytes = file.bytes;
      pickedFileName = file.name;
      pickedExtension = file.extension;

      if (fileNameController.text.trim().isEmpty) {
        fileNameController.text = file.name;
      }
      if (fileTypeController.text.trim().isEmpty &&
          (file.extension ?? '').trim().isNotEmpty) {
        fileTypeController.text = file.extension!.trim();
      }
      if (storagePathController.text.trim().isEmpty) {
        storagePathController.text = _service.buildStoragePath(
          patientId: patientId,
          fileName: file.name,
          extension: file.extension,
        );
      }

      setDialogState(() {});
    }

    Future<void> pickDocumentDate(StateSetter setDialogState) async {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDate: documentDate ?? DateTime.now(),
      );
      if (picked == null) return;
      documentDate = picked;
      setDialogState(() {});
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add attachment' : 'Edit attachment',
          validate: () {
            if (fileNameController.text.trim().isEmpty) {
              return 'File name is required.';
            }
            if (initial == null && pickedBytes == null) {
              return 'Please choose a file to upload.';
            }
            final storagePath = storagePathController.text.trim();
            if (storagePath.isNotEmpty &&
                !storagePath.startsWith('$patientId/')) {
              return 'Storage path must start with the patient ID.';
            }
            return null;
          },
          onSave: () async {
            String storagePath = storagePathController.text.trim();

            if (pickedBytes != null) {
              storagePath = await _service.uploadFile(
                patientId: patientId,
                fileName: pickedFileName ?? fileNameController.text.trim(),
                bytes: pickedBytes!,
                extension: pickedExtension,
              );
            } else if (storagePath.isEmpty) {
              storagePath = _service.buildStoragePath(
                patientId: patientId,
                fileName: fileNameController.text.trim(),
              );
            }

            final model = AttachmentModel(
              id: initial?.id,
              patientId: patientId,
              fileName: fileNameController.text.trim(),
              fileKind: fileKind,
              fileType: fileTypeController.text.trim().isEmpty
                  ? null
                  : fileTypeController.text.trim(),
              storagePath: storagePath,
              documentDate: documentDate,
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              uploadedByUserId: initial?.uploadedByUserId,
            );

            await _service.save(
              attachment: model,
              patientId: patientId,
              performedByUserId: performedByUserId,
            );
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fileNameController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'File name'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: saving ? null : () => pickFile(setDialogState),
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        pickedBytes == null
                            ? (initial == null
                            ? 'Choose file to upload'
                            : 'Choose file to replace')
                            : 'File selected',
                      ),
                    ),
                    if (pickedFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        pickedFileName!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: fileKind,
                      decoration: const InputDecoration(labelText: 'Kind'),
                      items: const [
                        DropdownMenuItem(
                          value: 'lab_result',
                          child: Text('Lab result'),
                        ),
                        DropdownMenuItem(value: 'xray', child: Text('X-ray')),
                        DropdownMenuItem(value: 'scan', child: Text('Scan')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: saving
                          ? null
                          : (v) {
                        fileKind = v ?? 'other';
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fileTypeController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'File type / mime type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storagePathController,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: 'Storage path',
                        hintText: '$patientId/file.pdf',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Document date'),
                      subtitle: Text(
                        documentDate == null
                            ? 'Not set'
                            : documentDate!.toIso8601String().split('T').first,
                      ),
                      trailing: IconButton(
                        onPressed: saving
                            ? null
                            : () => pickDocumentDate(setDialogState),
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    fileNameController.dispose();
    fileTypeController.dispose();
    storagePathController.dispose();
    descriptionController.dispose();

    if (saved == true) {
      await _load();
    }
  }

  // CHANGED: delete now asks for confirmation first.
  Future<void> _deleteItem(AttachmentModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete attachment?',
      message: 'This will delete the attachment metadata and the file itself.',
    );

    if (!confirmed || !mounted) return;

    await _service.delete(patientId: patientId, id: item.id!);
    if (!mounted) return;
    await _load();
  }

  // CHANGED: open file using a signed/public URL from Storage.
  Future<void> _openItem(AttachmentModel item) async {
    try {
      final url = await _service.getOpenUrl(item.storagePath);
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the attachment.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open failed: $e')),
      );
    }
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
                subtitle: Text(
                  [
                    'Kind: ${item.fileKind}',
                    if ((item.fileType ?? '').isNotEmpty)
                      'Type: ${item.fileType}',
                    if (item.documentDate != null)
                      'Date: ${item.documentDate!.toIso8601String().split('T').first}',
                    if ((item.description ?? '').isNotEmpty)
                      'Description: ${item.description}',
                    if (item.storagePath.isNotEmpty)
                      'Path: ${item.storagePath}',
                  ].join('\n'),
                ),
                trailing: widget.canEdit
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Open',
                      onPressed: () => _openItem(item),
                      icon: const Icon(Icons.open_in_new),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditor(initial: item);
                        } else if (value == 'delete') {
                          await _deleteItem(item);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
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