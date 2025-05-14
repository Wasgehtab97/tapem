// lib/presentation/widgets/device/device_create_form.dart

import 'package:flutter/material.dart';
import 'package:tapem/domain/repositories/admin_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog/Sheet, um ein neues Gerät anzulegen.
class DeviceCreateForm extends StatefulWidget {
  const DeviceCreateForm({Key? key}) : super(key: key);

  @override
  _DeviceCreateFormState createState() => _DeviceCreateFormState();
}

class _DeviceCreateFormState extends State<DeviceCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final id = await context
          .read<AdminRepository>()
          .createDevice(
            name: _nameController.text.trim(),
            exerciseMode: _modeController.text.trim(),
          );
      Navigator.of(context).pop(id);
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
      title: const Text('Neues Gerät'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Pflichtfeld'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeController,
              decoration: const InputDecoration(labelText: 'Übungsmodus'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Pflichtfeld'
                  : null,
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
              : const Text('Erstellen'),
        ),
      ],
    );
  }
}
