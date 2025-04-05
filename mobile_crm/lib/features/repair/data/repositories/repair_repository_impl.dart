import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/repair_job_card.dart';
import '../../domain/entities/repair_job.dart';
import '../models/repair_job_model.dart';

class RepairRepositoryImpl {
  final FirestoreService _firestoreService = getService<FirestoreService>();
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final _uuid = const Uuid();

  // Create a new repair job
  Future<String> createRepairJob(RepairJob repairJob) async {
    try {
      // Generate a unique ID for the repair
      final String repairId = _uuid.v4();

      // Convert entity to model and add the generated ID
      final RepairJobModel repairModel =
          RepairJobModel.fromEntity(repairJob.copyWith(id: repairId));

      // Add shop ID from current user
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert to JSON
      final repairData = repairModel.toJson();
      repairData['shopId'] = userId;
      repairData['createdBy'] = userId;
      repairData['createdAt'] = DateTime.now().toIso8601String();
      repairData['updatedAt'] = DateTime.now().toIso8601String();

      // Save to Firestore
      await _firestoreService.setDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: repairId,
        data: repairData,
      );

      return repairId;
    } catch (e) {
      throw Exception('Failed to create repair job: $e');
    }
  }

  // Get all repair jobs for current shop
  Future<List<RepairJob>> getRepairJobs() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService.queryCollection(
        collectionPath: AppConstants.repairJobsCollection,
        filters: [
          ['shopId', userId]
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

  // Delete repair job
  Future<void> deleteRepairJob(String id) async {
    try {
      await _firestoreService.deleteDocument(
        collectionPath: AppConstants.repairJobsCollection,
        documentId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete repair job: $e');
    }
  }

  // Get repair jobs by status
  Future<List<RepairJob>> getRepairJobsByStatus(RepairStatus status) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService.queryCollection(
        collectionPath: AppConstants.repairJobsCollection,
        filters: [
          ['shopId', userId],
          ['status', status.name],
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
      throw Exception('Failed to get repair jobs by status: $e');
    }
  }
}
