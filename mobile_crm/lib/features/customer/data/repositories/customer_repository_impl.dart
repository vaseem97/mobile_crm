import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/connectivity_mixin.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';
import '../../../repair/data/repositories/repair_repository_impl.dart';
import '../../../repair/domain/entities/repair_job.dart';

class CustomerRepositoryImpl with ConnectivityAware {
  final FirestoreService _firestoreService = getService<FirestoreService>();
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final RepairRepositoryImpl _repairRepository =
      getService<RepairRepositoryImpl>();
  final _uuid = const Uuid();

  // Collection name for customers
  static const String _customersCollection = AppConstants.customersCollection;

  // Get all customers for current shop
  Future<List<Customer>> getCustomers() async {
    return executeWithConnectivity(() async {
      try {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        final snapshot = await _firestoreService.queryCollection(
          collectionPath: _customersCollection,
          filters: [
            ['shopId', userId],
            ['isActive', true],
          ],
          orderBy: 'name',
        );

        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is set
          return CustomerModel.fromJson(data);
        }).toList();
      } catch (e) {
        throw Exception('Failed to get customers: $e');
      }
    });
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    try {
      final doc = await _firestoreService.getDocument(
        collectionPath: _customersCollection,
        documentId: id,
      );

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set
      return CustomerModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // Get customer by phone number
  Future<Customer?> getCustomerByPhone(String phone) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestoreService.queryCollection(
        collectionPath: _customersCollection,
        filters: [
          ['shopId', userId],
          ['phone', phone],
          ['isActive', true],
        ],
      );

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set
      return CustomerModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get customer by phone: $e');
    }
  }

  // Create a new customer
  Future<String> createCustomer(Customer customer) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if customer with same phone already exists
      final existingCustomer = await getCustomerByPhone(customer.phone);
      if (existingCustomer != null) {
        throw Exception('Customer with this phone number already exists');
      }

      // Generate a unique ID
      final customerId = _uuid.v4();

      // Create data map
      final model = CustomerModel.fromEntity(
        customer.copyWith(id: customerId),
      );
      final data = model.toJson();

      // Add shop ID and additional metadata
      data['shopId'] = userId;
      data['createdAt'] = DateTime.now().toIso8601String();
      data['createdBy'] = userId;
      data['isActive'] = true; // For soft delete support

      // Create document
      await _firestoreService.setDocument(
        collectionPath: _customersCollection,
        documentId: customerId,
        data: data,
      );

      // Find any existing repairs with this phone number and associate them with this customer
      final repairs =
          await _repairRepository.getRepairJobsByPhone(customer.phone);
      if (repairs.isNotEmpty) {
        // Get repair IDs
        final repairIds = repairs.map((r) => r.id).toList();

        // Update customer with repair IDs
        final updatedCustomer = customer.copyWith(
          id: customerId,
          repairIds: repairIds,
          repairCount: repairs.length,
          totalSpent: repairs.fold<double>(
              0.0, (sum, repair) => sum + repair.estimatedCost),
          lastVisit: repairs
              .where((r) => r.deliveredAt != null)
              .fold<DateTime?>(null, (latest, repair) {
            if (latest == null) return repair.deliveredAt;
            if (repair.deliveredAt == null) return latest;
            return repair.deliveredAt!.isAfter(latest)
                ? repair.deliveredAt
                : latest;
          }),
        );

        // Update the customer document
        final updatedModel = CustomerModel.fromEntity(updatedCustomer);
        final updatedData = updatedModel.toJson();

        await _firestoreService.updateDocument(
          collectionPath: _customersCollection,
          documentId: customerId,
          data: updatedData,
        );

        // Update customer info in all associated repairs if needed
        await _updateCustomerInfoInRepairs(
          repairIds: repairIds,
          customerName: customer.name,
          customerPhone: customer.phone,
          customerEmail: customer.email,
        );
      }

      return customerId;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  // Update customer
  Future<void> updateCustomer(Customer customer) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (customer.id.isEmpty) {
        throw Exception('Customer ID cannot be empty');
      }

      // Get the original customer to check what changed
      final originalCustomer = await getCustomerById(customer.id);
      if (originalCustomer == null) {
        throw Exception('Customer not found');
      }

      // Check if name or phone changed
      final bool nameChanged = originalCustomer.name != customer.name;
      final bool phoneChanged = originalCustomer.phone != customer.phone;

      // Convert to model then to JSON
      final customerModel = CustomerModel.fromEntity(customer);
      final customerData = customerModel.toJson();

      // Add updated timestamp
      customerData['updatedAt'] = DateTime.now().toIso8601String();
      customerData['updatedBy'] = userId;

      await _firestoreService.updateDocument(
        collectionPath: _customersCollection,
        documentId: customer.id,
        data: customerData,
      );

      // If name or phone changed, update all associated repair jobs
      if ((nameChanged || phoneChanged) &&
          customer.repairIds != null &&
          customer.repairIds!.isNotEmpty) {
        // First, verify which repair IDs are still active
        final activeRepairIds = <String>[];
        for (final repairId in customer.repairIds!) {
          final repair = await _repairRepository.getRepairJobById(repairId);
          if (repair != null) {
            activeRepairIds.add(repairId);
          }
        }

        // Only update active repairs
        if (activeRepairIds.isNotEmpty) {
          await _updateCustomerInfoInRepairs(
            repairIds: activeRepairIds,
            customerName: nameChanged ? customer.name : null,
            customerPhone: phoneChanged ? customer.phone : null,
            customerEmail: customer.email,
          );
        }

        // If we found that some repairs are no longer active, update the customer's repair IDs
        if (activeRepairIds.length < customer.repairIds!.length) {
          // Get the active repairs to recalculate stats
          final activeRepairs = <RepairJob>[];
          for (final repairId in activeRepairIds) {
            final repair = await _repairRepository.getRepairJobById(repairId);
            if (repair != null) {
              activeRepairs.add(repair);
            }
          }

          // Calculate updated stats
          final totalSpent = activeRepairs.fold<double>(
              0.0, (sum, repair) => sum + repair.estimatedCost);

          final lastVisit = activeRepairs
              .where((r) => r.deliveredAt != null)
              .fold<DateTime?>(null, (latest, repair) {
            if (latest == null) return repair.deliveredAt;
            if (repair.deliveredAt == null) return latest;
            return repair.deliveredAt!.isAfter(latest)
                ? repair.deliveredAt
                : latest;
          });

          // Update customer with corrected stats
          final updatedCustomerData = {
            'repairIds': activeRepairIds,
            'repairCount': activeRepairs.length,
            'totalSpent': totalSpent,
            'lastVisit': lastVisit?.toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          };

          await _firestoreService.updateDocument(
            collectionPath: _customersCollection,
            documentId: customer.id,
            data: updatedCustomerData,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // Delete customer (soft delete)
  Future<void> deleteCustomer(String id) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestoreService.updateDocument(
        collectionPath: _customersCollection,
        documentId: id,
        data: {
          'isActive': false,
          'deletedAt': DateTime.now().toIso8601String(),
          'deletedBy': userId,
        },
      );
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Get real-time stream of customers
  Stream<List<Customer>> getCustomersStream() {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _firestoreService
          .collection(_customersCollection)
          .where('shopId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is set
          return CustomerModel.fromJson(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get customers stream: $e');
    }
  }

  // Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all customers (we'll filter in memory since Firestore doesn't support OR queries well)
      final snapshot = await _firestoreService.queryCollection(
        collectionPath: _customersCollection,
        filters: [
          ['shopId', userId],
          ['isActive', true],
        ],
      );

      final customers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return CustomerModel.fromJson(data);
      }).toList();

      // Filter by query
      if (query.isEmpty) {
        return customers;
      }

      final lowercaseQuery = query.toLowerCase();
      return customers.where((customer) {
        return customer.name.toLowerCase().contains(lowercaseQuery) ||
            customer.phone.contains(query);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  // Get customer's repair history
  Future<List<RepairJob>> getCustomerRepairs(String customerId) async {
    try {
      final customer = await getCustomerById(customerId);
      if (customer == null) {
        throw Exception('Customer not found');
      }

      if (customer.repairIds == null || customer.repairIds!.isEmpty) {
        return [];
      }

      final repairs = <RepairJob>[];
      final deletedRepairIds = <String>[];

      for (final repairId in customer.repairIds!) {
        final repair = await _repairRepository.getRepairJobById(repairId);
        if (repair != null) {
          repairs.add(repair);
        } else {
          // Keep track of deleted repair IDs
          deletedRepairIds.add(repairId);
        }
      }

      // Always recalculate customer stats based on active repairs
      // This ensures the stats are accurate even if repairs were deleted
      final updatedRepairIds = deletedRepairIds.isEmpty
          ? customer.repairIds
          : customer.repairIds!
              .where((id) => !deletedRepairIds.contains(id))
              .toList();

      // Only update if we have repairs or if some repairs were deleted
      if (repairs.isNotEmpty || deletedRepairIds.isNotEmpty) {
        // Calculate total spent from active repairs only
        final totalSpent = repairs.fold<double>(
            0.0, (sum, repair) => sum + repair.estimatedCost);

        // Find the latest visit date from active repairs
        final lastVisit = repairs
            .where((r) => r.deliveredAt != null)
            .fold<DateTime?>(null, (latest, repair) {
          if (latest == null) return repair.deliveredAt;
          if (repair.deliveredAt == null) return latest;
          return repair.deliveredAt!.isAfter(latest)
              ? repair.deliveredAt
              : latest;
        });

        // Update customer with the filtered repair IDs and recalculated stats
        final updatedCustomer = customer.copyWith(
          repairIds: updatedRepairIds,
          repairCount: repairs.length,
          totalSpent: totalSpent,
          lastVisit: lastVisit,
        );

        // Update the customer in the database
        await updateCustomer(updatedCustomer);
      }

      // Sort by date (newest first)
      repairs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return repairs;
    } catch (e) {
      throw Exception('Failed to get customer repairs: $e');
    }
  }

  // Update customer information in all associated repair jobs
  Future<void> _updateCustomerInfoInRepairs({
    required List<String> repairIds,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update each repair job
      for (final repairId in repairIds) {
        final repair = await _repairRepository.getRepairJobById(repairId);
        if (repair == null) continue;

        // Create a map of fields to update
        final Map<String, dynamic> updateData = {};

        // Only update fields that have changed
        if (customerName != null && repair.customerName != customerName) {
          updateData['customerName'] = customerName;
        }

        if (customerPhone != null && repair.customerPhone != customerPhone) {
          updateData['customerPhone'] = customerPhone;
        }

        if (customerEmail != null && repair.customerEmail != customerEmail) {
          updateData['customerEmail'] = customerEmail;
        }

        // Skip if no changes
        if (updateData.isEmpty) continue;

        // Add metadata
        updateData['updatedAt'] = DateTime.now().toIso8601String();
        updateData['updatedBy'] = userId;

        // Update the repair job
        await _firestoreService.updateDocument(
          collectionPath: AppConstants.repairJobsCollection,
          documentId: repairId,
          data: updateData,
        );
      }
    } catch (e) {
      throw Exception('Failed to update customer info in repairs: $e');
    }
  }

  // Extract customers from repair jobs
  Future<void> extractCustomersFromRepairs() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all active repair jobs
      final repairs = await _repairRepository.getRepairJobs();

      // Group repairs by customer phone
      final Map<String, List<RepairJob>> repairsByPhone = {};
      for (final repair in repairs) {
        if (!repairsByPhone.containsKey(repair.customerPhone)) {
          repairsByPhone[repair.customerPhone] = [];
        }
        repairsByPhone[repair.customerPhone]!.add(repair);
      }

      // Create or update customers
      for (final entry in repairsByPhone.entries) {
        final phone = entry.key;
        final customerRepairs = entry.value;

        // Skip if no repairs
        if (customerRepairs.isEmpty) continue;

        // Get the most recent repair for customer info
        customerRepairs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latestRepair = customerRepairs.first;

        // Calculate total spent
        final totalSpent = customerRepairs.fold<double>(
          0.0,
          (sum, repair) => sum + repair.estimatedCost,
        );

        // Get repair IDs
        final repairIds = customerRepairs.map((r) => r.id).toList();

        // Find latest visit date
        DateTime? lastVisit;
        for (final repair in customerRepairs) {
          if (repair.deliveredAt != null) {
            if (lastVisit == null || repair.deliveredAt!.isAfter(lastVisit)) {
              lastVisit = repair.deliveredAt;
            }
          }
        }

        // Check if customer already exists
        final existingCustomer = await getCustomerByPhone(phone);

        if (existingCustomer == null) {
          // Create new customer
          final customer = Customer(
            id: _uuid.v4(),
            name: latestRepair.customerName,
            phone: phone,
            email: latestRepair.customerEmail,
            createdAt: latestRepair.createdAt,
            lastVisit: lastVisit,
            repairCount: customerRepairs.length,
            totalSpent: totalSpent,
            repairIds: repairIds,
          );

          // Create data map
          final model = CustomerModel.fromEntity(customer);
          final data = model.toJson();

          // Add shop ID and additional metadata
          data['shopId'] = userId;
          data['createdAt'] = DateTime.now().toIso8601String();
          data['createdBy'] = userId;
          data['isActive'] = true;

          // Create document
          await _firestoreService.setDocument(
            collectionPath: _customersCollection,
            documentId: customer.id,
            data: data,
          );
        } else {
          // Update existing customer
          final updatedCustomer = existingCustomer.copyWith(
            name: latestRepair.customerName,
            email: latestRepair.customerEmail,
            lastVisit: lastVisit,
            repairCount: customerRepairs.length,
            totalSpent: totalSpent,
            repairIds: repairIds,
          );

          await updateCustomer(updatedCustomer);
        }
      }
    } catch (e) {
      throw Exception('Failed to extract customers from repairs: $e');
    }
  }
}
