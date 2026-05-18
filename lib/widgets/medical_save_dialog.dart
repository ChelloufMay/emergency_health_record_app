import 'package:flutter/material.dart';

typedef MedicalDialogBuilder =
    Widget Function(BuildContext context, bool saving);

class MedicalSaveDialog extends StatefulWidget {
  final String title;
  final MedicalDialogBuilder contentBuilder;
  final String? Function() validate;
  final Future<void> Function() onSave;

  const MedicalSaveDialog({
    super.key,
    required this.title,
    required this.contentBuilder,
    required this.validate,
    required this.onSave,
  });

  @override
  State<MedicalSaveDialog> createState() => _MedicalSaveDialogState();
}

class _MedicalSaveDialogState extends State<MedicalSaveDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final validationError = widget.validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.contentBuilder(context, _saving),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
