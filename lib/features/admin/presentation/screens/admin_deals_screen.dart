import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/deals/data/providers/deals_provider.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDealsScreen extends ConsumerWidget {
  const AdminDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals verwalten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _editDeal(context, null),
          ),
        ],
      ),
      body: dealsAsync.when(
        data: (deals) => ListView.builder(
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            return ListTile(
              leading: Switch(
                value: deal.isActive,
                onChanged: (val) {
                  FirebaseFirestore.instance.collection('deals').doc(deal.id).update({'isActive': val});
                },
              ),
              title: Text(deal.partnerName),
              subtitle: Text(deal.title),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editDeal(context, deal),
              ),
            );
          },
        ),
        error: (e, s) => Center(child: Text('Fehler: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _editDeal(BuildContext context, Deal? deal) {
    final titleController = TextEditingController(text: deal?.title);
    final partnerController = TextEditingController(text: deal?.partnerName);
    final codeController = TextEditingController(text: deal?.code);
    final linkController = TextEditingController(text: deal?.link);
    final imageController = TextEditingController(text: deal?.imageUrl);
    final descriptionController = TextEditingController(text: deal?.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partnerController, decoration: const InputDecoration(labelText: 'Partner Name (z.B. ESN)')),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titel (z.B. 20% Rabatt)')),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Rabattcode')),
              TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Shop Link')),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Bild URL')),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final data = {
                    'partnerName': partnerController.text,
                    'title': titleController.text,
                    'code': codeController.text,
                    'link': linkController.text,
                    'imageUrl': imageController.text,
                    'description': descriptionController.text,
                    'isActive': deal?.isActive ?? true,
                    'priority': deal?.priority ?? 0,
                    'category': deal?.category ?? 'Supplements',
                    'partnerLogoUrl': deal?.partnerLogoUrl ?? '',
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (deal == null) {
                    FirebaseFirestore.instance.collection('deals').add({
                      ...data,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    FirebaseFirestore.instance.collection('deals').doc(deal.id).update(data);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
