// lib/widgets/device_update_form.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';

class DeviceUpdateForm extends StatefulWidget {
  /// Firestore-Dokument-ID des Geräts
  final String documentId;
  final String currentName;
  final String currentExerciseMode;
  final String currentSecretCode;
  final Function(Map<String, dynamic>)? onUpdated;

  const DeviceUpdateForm({
    Key? key,
    required this.documentId,
    required this.currentName,
    required this.currentExerciseMode,
    required this.currentSecretCode,
    this.onUpdated,
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
  String _message = '';
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _modeController = TextEditingController(text: widget.currentExerciseMode);
    _secretController = TextEditingController(text: widget.currentSecretCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modeController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = '';
    });

    try {
      final updated = await _api.updateDevice(
        widget.documentId,
        _nameController.text.trim(),
        _modeController.text.trim(),
        _secretController.text.trim(),
      );
      _message = 'Gerät wurde aktualisiert.';
      if (widget.onUpdated != null) widget.onUpdated!(updated);
    } catch (e) {
      _message = 'Fehler beim Aktualisieren.';
      debugPrint('Update-Fehler: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Neuer Gerätename'),
            validator: (v) => v!.trim().isEmpty ? 'Bitte Namen eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _modeController,
            decoration: const InputDecoration(labelText: 'Neuer Exercise Mode'),
            validator: (v) => v!.trim().isEmpty ? 'Bitte Mode eingeben' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _secretController,
            decoration: const InputDecoration(labelText: 'Neuer Secret Code'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Änderungen übernehmen'),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_message, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
