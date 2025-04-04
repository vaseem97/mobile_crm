import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a collection reference
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  // Get a document reference
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  // Get a document by ID
  Future<DocumentSnapshot> getDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collectionPath).doc(documentId).get();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  // Get all documents from a collection
  Future<QuerySnapshot> getCollection(String collectionPath) async {
    try {
      return await _firestore.collection(collectionPath).get();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  // Stream documents from a collection
  Stream<QuerySnapshot> streamCollection(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  // Stream a specific document
  Stream<DocumentSnapshot> streamDocument({
    required String collectionPath,
    required String documentId,
  }) {
    return _firestore.collection(collectionPath).doc(documentId).snapshots();
  }

  // Add a document to a collection
  Future<DocumentReference> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  // Set a document with a specific ID
  Future<void> setDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  // Update a document
  Future<void> updateDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Delete a document
  Future<void> deleteDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Query a collection with filters
  Future<QuerySnapshot> queryCollection({
    required String collectionPath,
    required List<List<dynamic>> filters,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);

      // Apply filters
      for (final filter in filters) {
        query = query.where(filter[0], isEqualTo: filter[1]);
      }

      // Apply order by
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      throw Exception('Failed to query collection: $e');
    }
  }

  // Batch writes
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final ref = _firestore.doc(operation['path'] as String);
        final data = operation['data'] as Map<String, dynamic>?;

        switch (type) {
          case 'set':
            batch.set(ref, data!, SetOptions(merge: true));
            break;
          case 'update':
            batch.update(ref, data!);
            break;
          case 'delete':
            batch.delete(ref);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch write: $e');
    }
  }

  // Transaction
  Future<void> runTransaction(
      Future<void> Function(Transaction) transaction) async {
    try {
      await _firestore.runTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }
}
