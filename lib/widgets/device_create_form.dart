import 'package:flutter/material.dart';
import '../services/api_services.dart';

class DeviceCreateForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreated;
  const DeviceCreateForm({Key? key, required this.onCreated}) : super(key: key);

  @override
  _DeviceCreateFormState createState() => _DeviceCreateFormState();
}

class _DeviceCreateFormState extends State<DeviceCreateForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = "";
  String _exerciseMode = "";
  bool _isSubmitting = false;
  final ApiService apiService = ApiService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
    });
    try {
      final newDevice = await apiService.createDevice(_name, _exerciseMode);
      widget.onCreated(newDevice);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Fehler beim Erstellen: $e",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        "Neues Gerät hinzufügen",
        style: theme.textTheme.headlineMedium,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Gerätename",
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? "Bitte Namen eingeben" : null,
              onSaved: (value) => _name = value!,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Übungsmodus (single/multi)",
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? "Bitte Übungsmodus eingeben" : null,
              onSaved: (value) => _exerciseMode = value!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            "Abbrechen",
            style: theme.textTheme.labelLarge,
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : Text(
                  "Erstellen",
                  style: theme.textTheme.labelLarge,
                ),
        ),
      ],
    );
  }
}
