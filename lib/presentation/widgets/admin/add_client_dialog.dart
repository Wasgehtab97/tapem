import 'package:flutter/material.dart';

/// Dialog zum Hinzufügen eines neuen Klienten über seine Mitgliedsnummer.
/// Liefert die eingegebene Nummer als String zurück.
class AddClientDialog extends StatefulWidget {
  const AddClientDialog({Key? key}) : super(key: key);

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _membershipController = TextEditingController();

  @override
  void dispose() {
    _membershipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() == true) {
      Navigator.of(context).pop(_membershipController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        'Neuen Klienten hinzufügen',
        style: theme.textTheme.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _membershipController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Mitgliedsnummer',
            hintText: 'z.B. 0001',
          ),
          style: theme.textTheme.bodyMedium,
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return 'Bitte Mitgliedsnummer eingeben';
            }
            if (int.tryParse(v) == null) {
              return 'Ungültige Nummer';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Anfrage senden'),
        ),
      ],
    );
  }
}
