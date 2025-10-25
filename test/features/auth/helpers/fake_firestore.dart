import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/fake.dart';

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};

  void seedDocument(String path, Map<String, dynamic> data) {
    final segments = path.split('/');
    if (segments.length.isOdd) {
      throw ArgumentError('Path must end with a document id: $path');
    }
    final collectionPath = segments.sublist(0, segments.length - 1).join('/');
    final docId = segments.last;
    final collection =
        _collections.putIfAbsent(collectionPath, () => <String, Map<String, dynamic>>{});
    collection[docId] = Map<String, dynamic>.from(data);
  }

  Map<String, Map<String, dynamic>> _ensureCollection(String path) {
    return _collections.putIfAbsent(path, () => <String, Map<String, dynamic>>{});
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    _ensureCollection(path);
    return FakeCollectionReference(this, path);
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = FakeTransaction(this);
    return transactionHandler(transaction);
  }

  Map<String, Map<String, dynamic>> getCollection(String path) {
    return _collections[path] ?? <String, Map<String, dynamic>>{};
  }

  Map<String, dynamic>? getDocument(String collectionPath, String docId) {
    return getCollection(collectionPath)[docId];
  }

  void setDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) {
    final collection = _ensureCollection(collectionPath);
    collection[docId] = Map<String, dynamic>.from(data);
  }

  void updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) {
    final collection = _ensureCollection(collectionPath);
    final existing = collection[docId];
    if (existing == null) {
      throw FirebaseException(plugin: 'fake-firestore', code: 'not-found');
    }
    for (final entry in data.entries) {
      existing[entry.key] = entry.value;
    }
  }

  void deleteDocument(String collectionPath, String docId) {
    final collection = _ensureCollection(collectionPath);
    collection.remove(docId);
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(this._firestore, this.path);

  final FakeFirebaseFirestore _firestore;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) {
    final docId = id ?? _autoId();
    return FakeDocumentReference(_firestore, path, docId);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = _firestore
        .getCollection(path)
        .entries
        .map((entry) =>
            FakeQueryDocumentSnapshot(_firestore, path, entry.key, entry.value))
        .toList();
    return FakeQuerySnapshot(docs);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNull,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNotEqualTo,
  }) {
    return FakeQuery(
      _firestore,
      path,
      filters: <_QueryFilter>[
        _QueryFilter(field as String, isEqualTo),
      ],
    );
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return FakeQuery(_firestore, path, limit: limit);
  }

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      throw UnimplementedError('parent not supported in fake');

  @override
  CollectionReference<Map<String, dynamic>> withConverter<T>(
          {FromFirestore<Map<String, dynamic>, T>? fromFirestore,
          ToFirestore<Map<String, dynamic>, T>? toFirestore}) =>
      this;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  FakeQuery(
    this._firestore,
    this._path, {
    List<_QueryFilter>? filters,
    this.limit,
  }) : filters = filters ?? <_QueryFilter>[];

  final FakeFirebaseFirestore _firestore;
  final String _path;
  final List<_QueryFilter> filters;
  @override
  final int? limit;

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNull,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNotEqualTo,
  }) {
    return FakeQuery(
      _firestore,
      _path,
      filters: <_QueryFilter>[...filters, _QueryFilter(field as String, isEqualTo)],
      limit: limit,
    );
  }

  @override
  Query<Map<String, dynamic>> limitToLast(int limit) {
    return FakeQuery(_firestore, _path, filters: filters, limit: limit);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final collection = _firestore.getCollection(_path);
    final docs = <FakeQueryDocumentSnapshot>[];
    for (final entry in collection.entries) {
      if (_matchesFilters(entry.value)) {
        docs.add(
            FakeQueryDocumentSnapshot(_firestore, _path, entry.key, entry.value));
        if (limit != null && docs.length >= limit!) {
          break;
        }
      }
    }
    return FakeQuerySnapshot(docs);
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    for (final filter in filters) {
      if (data[filter.field] != filter.equals) {
        return false;
      }
    }
    return true;
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
    Object? startAt,
    Object? startAtDocument,
    List<Object?>? startAtValues,
    Object? startAfter,
    Object? startAfterDocument,
    List<Object?>? startAfterValues,
    Object? endAt,
    Object? endAtDocument,
    List<Object?>? endAtValues,
    Object? endBefore,
    Object? endBeforeDocument,
    List<Object?>? endBeforeValues,
    int? limit,
  }) =>
      this;

  @override
  Query<Map<String, dynamic>> withConverter<T>({
    FromFirestore<Map<String, dynamic>, T>? fromFirestore,
    ToFirestore<Map<String, dynamic>, T>? toFirestore,
  }) =>
      this;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  FakeDocumentReference(this._firestore, this._collectionPath, this.id);

  final FakeFirebaseFirestore _firestore;
  final String _collectionPath;
  @override
  final String id;

  String get _documentPath => '$_collectionPath/$id';

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(
        _firestore, '$_collectionPath/$id/$collectionPath');
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = _firestore.getDocument(_collectionPath, id);
    return FakeDocumentSnapshot(_firestore, _collectionPath, id, data);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _firestore.setDocument(_collectionPath, id, data);
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    _firestore.updateDocument(_collectionPath, id, data);
  }

  @override
  Future<void> delete() async {
    _firestore.deleteDocument(_collectionPath, id);
  }

  @override
  String get path => _documentPath;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot(this._firestore, this._collectionPath, this._id, this._data);

  final FakeFirebaseFirestore _firestore;
  final String _collectionPath;
  final String _id;
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data!);

  @override
  bool get exists => _data != null;

  @override
  String get id => _id;

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      FakeDocumentReference(_firestore, _collectionPath, _id);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeQueryDocumentSnapshot(this._firestore, this._collectionPath, this._id, this._data);

  final FakeFirebaseFirestore _firestore;
  final String _collectionPath;
  final String _id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

  @override
  bool get exists => true;

  @override
  String get id => _id;

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      FakeDocumentReference(_firestore, _collectionPath, _id);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransaction extends Fake implements Transaction {
  FakeTransaction(this._firestore);

  final FakeFirebaseFirestore _firestore;

  @override
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> documentReference) async {
    final ref = documentReference as FakeDocumentReference;
    final data = _firestore.getDocument(ref._collectionPath, ref.id);
    return FakeDocumentSnapshot(
      _firestore,
      ref._collectionPath,
      ref.id,
      data,
    ) as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data,
      [SetOptions? options]) {
    final ref = documentReference as FakeDocumentReference;
    _firestore.setDocument(ref._collectionPath, ref.id,
        Map<String, dynamic>.from(data as Map<String, dynamic>));
    return this;
  }

  @override
  Transaction update<T>(DocumentReference<T> documentReference, Map<String, Object?> data) {
    final ref = documentReference as FakeDocumentReference;
    _firestore.updateDocument(ref._collectionPath, ref.id,
        Map<String, dynamic>.from(data));
    return this;
  }

  @override
  Transaction delete<T>(DocumentReference<T> documentReference) {
    final ref = documentReference as FakeDocumentReference;
    _firestore.deleteDocument(ref._collectionPath, ref.id);
    return this;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueryFilter {
  const _QueryFilter(this.field, this.equals);

  final String field;
  final Object? equals;
}

String _autoId() => DateTime.now().microsecondsSinceEpoch.toString();
