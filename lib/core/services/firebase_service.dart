import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloudFirestore;
import 'package:firebase_database/firebase_database.dart';

import '../utils/logs.dart';

class FirebaseService extends GetxService {
  final cloudFirestore.FirebaseFirestore firestore = cloudFirestore.FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<FirebaseService> init() async {
    // Set persistence for Firestore
    firestore.settings.persistenceEnabled;

    // Set persistence for Realtime Database
    _database.setPersistenceEnabled(true);

    return this;
  }

  // Firestore methods
  cloudFirestore.CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  cloudFirestore.DocumentReference<Map<String, dynamic>> document(String path) {
    return firestore.doc(path);
  }

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final reference = firestore.doc(path);
    await reference.set(data, cloudFirestore.SetOptions(merge: merge));
  }

  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = firestore.doc(path);
    await reference.update(data);
  }

  // Get a collection
  Future<cloudFirestore.QuerySnapshot> getCollection({
    required String path,
    cloudFirestore.Query Function(cloudFirestore.Query query)? queryBuilder,
  }) async {
    try {
      cloudFirestore.Query query = firestore.collection(path);
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
    final reference = firestore.doc(path);
    await reference.delete();
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    cloudFirestore.Query<Map<String, dynamic>> Function(cloudFirestore.Query<Map<String, dynamic>> query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    cloudFirestore.Query<Map<String, dynamic>> query = firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final Stream<cloudFirestore.QuerySnapshot<Map<String, dynamic>>> snapshots = query.snapshots();
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
    final cloudFirestore.DocumentReference<Map<String, dynamic>> reference = firestore.doc(path);
    final Stream<cloudFirestore.DocumentSnapshot<Map<String, dynamic>>> snapshots = reference.snapshots();
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
  Future<cloudFirestore.DocumentSnapshot> getDocument({required String path}) async {
    try {
      DevLogs.debug('Getting document at path: $path');
      return await firestore.doc(path).get();
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
