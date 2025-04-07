import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../domain/entities/repair_job.dart';
import '../models/repair_job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RepairRepositoryImpl {
  final FirestoreService _firestoreService = getService<FirestoreService>();
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final _uuid = const Uuid();

  // Create a new repair job
  Future<String> createRepairJob(RepairJob repairJob) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the current counter value and increment it
      final counterRef = _firestoreService
          .collection(AppConstants.repairJobsCollection)
          .doc('counters')
          .collection('shops')
          .doc(user.uid);

      // Use a transaction to safely increment the counter
      int counterValue = 0;
      await _firestoreService.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);
        int currentCount = 0;

        if (counterSnapshot.exists) {
          final data = counterSnapshot.data() as Map<String, dynamic>?;
          currentCount = (data?['count'] as int?) ?? 0;
        }

        // Increment the counter
        counterValue = currentCount + 1;
        transaction.set(counterRef, {
          'count': counterValue,
          'lastUpdated': DateTime.now().toIso8601String(),
          'shopId': user.uid,
        });
      });

      // Generate a friendly ID in format REP-YYMMxxxxx
      final now = DateTime.now();
      final yearMonth =
          '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}';

      // Format sequential number with leading zeros (e.g., 00001, 00012, 00123)
      final sequentialNum = counterValue.toString().padLeft(5, '0');

      // Create friendly ID
      final friendlyId = 'REP-$yearMonth$sequentialNum';

      // Create data map
      final model = RepairJobModel.fromEntity(
        repairJob.copyWith(id: friendlyId),
      );
      final data = model.toJson();

      // Add shop ID and additional metadata
      data['shopId'] = user.uid;
      data['createdAt'] = now.toIso8601String();
      data['createdBy'] = user.uid;
      data['isActive'] = true; // For soft delete support

      // Create document with the friendly ID as document ID
      await _firestoreService
          .collection(AppConstants.repairJobsCollection)
          .doc(friendlyId)
          .set(data);

      return friendlyId;
    } catch (e) {
      throw Exception('Failed to create repair job: $e');
    }
  }

  // Get all repair jobs for current shop (excluding soft-deleted ones)
  Future<List<RepairJob>> getRepairJobs() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService.queryCollection(
        collectionPath: AppConstants.repairJobsCollection,
        filters: [
          ['shopId', userId],
          ['isActive', true],
        ],
        orderBy: 'createdAt',
        descending: true,
      );

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return RepairJobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get repair jobs: $e');
    }
  }

  // Get repair job by ID
  Future<RepairJob?> getRepairJobById(String id) async {
    try {
      final doc = await _firestoreService.getDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: id,
      );

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set
      return RepairJobModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get repair job: $e');
    }
  }

  // Update repair job
  Future<void> updateRepairJob(RepairJob repairJob) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (repairJob.id.isEmpty) {
        throw Exception('Repair job ID cannot be empty');
      }

      // Convert to model then to JSON
      final repairModel = RepairJobModel.fromEntity(repairJob);
      final repairData = repairModel.toJson();

      // Add updated timestamp
      repairData['updatedAt'] = DateTime.now().toIso8601String();
      repairData['updatedBy'] = userId;

      await _firestoreService.updateDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: repairJob.id,
        data: repairData,
      );
    } catch (e) {
      throw Exception('Failed to update repair job: $e');
    }
  }

  // Delete repair job (soft delete)
  Future<void> deleteRepairJob(String id) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.updateDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: id,
        data: {
          'isActive': false,
          'deletedAt': DateTime.now().toIso8601String(),
          'deletedBy': user.uid,
        },
      );
    } catch (e) {
      throw Exception('Failed to delete repair job: $e');
    }
  }

  // Get repair jobs by status
  Future<List<RepairJob>> getRepairJobsByStatus(RepairStatus status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService
          .collection(AppConstants.repairJobsCollection)
          .where('shopId', isEqualTo: user.uid)
          .where('status', isEqualTo: status.name)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return RepairJobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get repair jobs by status: $e');
    }
  }

  // Get repair jobs by customer phone number
  Future<List<RepairJob>> getRepairJobsByPhone(String phoneNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService
          .collection(AppConstants.repairJobsCollection)
          .where('shopId', isEqualTo: user.uid)
          .where('customerPhone', isEqualTo: phoneNumber)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return RepairJobModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get repair jobs by phone: $e');
    }
  }

  // Method to update image URLs after initial creation
  Future<void> updateRepairJobImageUrls(
      String repairId, List<String> imageUrls) async {
    try {
      await _firestoreService.updateDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: repairId,
        data: {
          'imageUrls': imageUrls,
        },
      );
    } catch (e) {
      throw Exception('Failed to update image URLs: $e');
    }
  }
}
