import 'package:flutter/material.dart';
import '../services/api_services.dart';

class DeviceUpdateForm extends StatefulWidget {
  final int deviceId;
  final String currentName;
  final String currentExerciseMode;
  final String currentSecretCode;
  final Function(Map<String, dynamic>)? onUpdated;

  const DeviceUpdateForm({
    Key? key,
    required this.deviceId,
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
  late TextEditingController _nameController;
  late TextEditingController _exerciseModeController;
  late TextEditingController _secretCodeController;
  String _message = '';
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _exerciseModeController = TextEditingController(text: widget.currentExerciseMode);
    _secretCodeController = TextEditingController(text: widget.currentSecretCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseModeController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    final newName = _nameController.text.trim();
    final newExerciseMode = _exerciseModeController.text.trim();
    final newSecretCode = _secretCodeController.text.trim();

    setState(() {
      _isSubmitting = true;
      _message = '';
    });

    try {
      final updatedDevice = await _apiService.updateDevice(
        widget.deviceId,
        newName,
        newExerciseMode,
        newSecretCode,
      );
      setState(() {
        _message = 'Gerät erfolgreich aktualisiert!';
      });
      if (widget.onUpdated != null) {
        widget.onUpdated!(updatedDevice);
      }
    } catch (error) {
      setState(() {
        _message = 'Fehler beim Aktualisieren.';
      });
      debugPrint('Update-Fehler: $error');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neuer Gerätename:',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Gib einen neuen Namen ein',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte einen Namen eingeben.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Neuer Exercise Mode:',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _exerciseModeController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'z.B. single, multi oder custom',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte den Exercise Mode eingeben.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Neuer Secret Code:',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _secretCodeController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Gib den Secret Code ein',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleUpdate,
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : Text('Änderungen übernehmen', style: theme.textTheme.labelLarge),
          ),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_message, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
