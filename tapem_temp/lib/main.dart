import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('✅ Firebase initialisiert');
  runApp(const TapemApp());
}

class TapemApp extends StatelessWidget {
  const TapemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap’em (Dev)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Drücke „Test Firestore“';

  Future<void> _testFirestore() async {
    setState(() => _status = '⏳ Test läuft…');
    try {
      await FirebaseFirestore.instance
          .collection('test')
          .doc('ping')
          .set({'pong': FieldValue.serverTimestamp()});
      print('📝 Dummy-Dokument geschrieben');
      final doc = await FirebaseFirestore.instance
          .collection('test')
          .doc('ping')
          .get();
      print('📖 Gelesen: ${doc.data()}');
      setState(() => _status = '✅ Firestore OK: ${doc.data()}');
    } catch (e) {
      print('❌ Fehler bei Firestore-Test: $e');
      setState(() => _status = '❌ Fehler: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tap’em (Dev)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testFirestore,
              child: const Text('Test Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}
