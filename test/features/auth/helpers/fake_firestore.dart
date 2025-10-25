import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart' as fake_cloud;

class FakeFirebaseFirestore extends fake_cloud.FakeFirebaseFirestore {
  Future<void> seedDocument(String path, Map<String, dynamic> data) async {
    final segments = path.split('/');
    if (segments.length.isOdd) {
      throw ArgumentError('Path must end with a document id: $path');
    }

    CollectionReference<Map<String, dynamic>> collectionRef =
        collection(segments.first);
    DocumentReference<Map<String, dynamic>> docRef =
        collectionRef.doc(segments[1]);

    for (var index = 2; index < segments.length; index += 2) {
      collectionRef = docRef.collection(segments[index]);
      docRef = collectionRef.doc(segments[index + 1]);
    }

    await docRef.set(Map<String, dynamic>.from(data));
  }
}
