import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_database/firebase_database.dart';

import '../utils/logs.dart';

class FirebaseService extends GetxService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<FirebaseService> init() async {
    // Set persistence for Firestore
    _firestore.settings.persistenceEnabled;

    // Set persistence for Realtime Database
    _database.setPersistenceEnabled(true);

    return this;
  }

  // Firestore methods
  firestore.CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  firestore.DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final reference = _firestore.doc(path);
    await reference.set(data, firestore.SetOptions(merge: merge));
  }

  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _firestore.doc(path);
    await reference.update(data);
  }

  // Get a collection
  Future<firestore.QuerySnapshot> getCollection({
    required String path,
    firestore.Query Function(firestore.Query query)? queryBuilder,
  }) async {
    try {
      firestore.Query query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      DevLogs.debug('Getting collection at path: $path');
      return await query.get();
    } catch (e) {
      DevLogs.error('Error getting collection', exception: e);
      throw e;
    }
  }

  Future<void> deleteData({required String path}) async {
    final reference = _firestore.doc(path);
    await reference.delete();
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    firestore.Query<Map<String, dynamic>> Function(firestore.Query<Map<String, dynamic>> query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    firestore.Query<Map<String, dynamic>> query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final Stream<firestore.QuerySnapshot<Map<String, dynamic>>> snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((snapshot) => builder(snapshot.data(), snapshot.id))
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Stream<T> documentStream<T>({
    required String path,
    required T Function(Map<String, dynamic>? data, String documentID) builder,
  }) {
    final firestore.DocumentReference<Map<String, dynamic>> reference = _firestore.doc(path);
    final Stream<firestore.DocumentSnapshot<Map<String, dynamic>>> snapshots = reference.snapshots();
    return snapshots.map((snapshot) => builder(snapshot.data(), snapshot.id));
  }

  // Realtime Database methods
  DatabaseReference databaseRef(String path) {
    return _database.ref(path);
  }

  Future<void> setRealtimeData({
    required String path,
    required dynamic data,
  }) async {
    final reference = _database.ref(path);
    await reference.set(data);
  }

  // Get a document
  Future<firestore.DocumentSnapshot> getDocument({required String path}) async {
    try {
      DevLogs.debug('Getting document at path: $path');
      return await _firestore.doc(path).get();
    } catch (e) {
      DevLogs.error('Error getting document', exception: e);
      throw e;
    }
  }

  Future<void> updateRealtimeData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _database.ref(path);
    await reference.update(data);
  }

  Future<void> deleteRealtimeData({required String path}) async {
    final reference = _database.ref(path);
    await reference.remove();
  }

  Stream<DatabaseEvent> realtimeStream({required String path}) {
    final reference = _database.ref(path);
    return reference.onValue;
  }
}
