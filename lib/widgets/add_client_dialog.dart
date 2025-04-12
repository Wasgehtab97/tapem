import 'package:flutter/material.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({Key? key}) : super(key: key);

  @override
  _AddClientDialogState createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final TextEditingController _membershipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _membershipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_membershipController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        "Neuen Klienten hinzufügen",
        style: theme.textTheme.headlineMedium, // Statt headline6
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _membershipController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Mitgliedsnummer",
            hintText: "z.B. 0001",
            labelStyle: theme.textTheme.bodyMedium, // Statt bodyText2
            hintStyle: theme.inputDecorationTheme.hintStyle,
            border: theme.inputDecorationTheme.border,
          ),
          style: theme.textTheme.bodyMedium, // Statt bodyText2
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte Mitgliedsnummer eingeben';
            }
            if (int.tryParse(value.trim()) == null) {
              return 'Ungültige Nummer';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Abbrechen",
            style: theme.textTheme.bodyMedium, // Statt bodyText2
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
          ),
          child: Text(
            "Anfrage senden",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ), // Statt bodyText2
          ),
        ),
      ],
    );
  }
}
