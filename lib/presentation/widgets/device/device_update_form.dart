// lib/presentation/widgets/device/device_update_form.dart

import 'package:flutter/material.dart';
import 'package:tapem/domain/repositories/admin_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Formular, um ein bestehendes Gerät zu bearbeiten.
class DeviceUpdateForm extends StatefulWidget {
  final String documentId;
  const DeviceUpdateForm({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  _DeviceUpdateFormState createState() => _DeviceUpdateFormState();
}

class _DeviceUpdateFormState extends State<DeviceUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _modeController;
  late final TextEditingController _secretController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _modeController = TextEditingController();
    _secretController = TextEditingController();
    // TODO: Bei Bedarf bestehende Werte laden und in die Controller füllen.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modeController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      await context.read<AdminRepository>().updateDevice(
            documentId: widget.documentId,
            name: _nameController.text.trim(),
            exerciseMode: _modeController.text.trim(),
            secretCode: _secretController.text.trim(),
          );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerät bearbeiten'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _modeController,
              decoration: const InputDecoration(labelText: 'Übungsmodus'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _secretController,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
