import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final FirestoreService _firestoreService = getService<FirestoreService>();

  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_authService.currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final uid = _authService.currentUser!.uid;
      final docSnapshot = await _firestoreService.getDocument(
        collectionPath: 'users',
        documentId: uid,
      );

      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.signOut();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(currentUser.displayName),
                    const SizedBox(height: 32),
                    _buildInfoCard(),
                    const SizedBox(height: 48),
                    CustomButton(
                      text: 'Logout',
                      onPressed: _logout,
                      isLoading: _isLoading,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String? name) {
    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              _getInitials(name ?? 'User'),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            name ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (_userData != null && _userData!['shopName'] != null)
          Center(
            child: Text(
              _userData!['shopName'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    if (_userData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No user data available')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.store, 'Shop Name',
                _userData!['shopName'] ?? 'Not provided'),
            const Divider(),
            _buildInfoRow(
                Icons.email, 'Email', _userData!['email'] ?? 'Not provided'),
            const Divider(),
            _buildInfoRow(
                Icons.phone, 'Phone', _userData!['phone'] ?? 'Not provided'),
            const Divider(),
            _buildInfoRow(
              Icons.access_time,
              'Account Created',
              _formatDate(_userData!['createdAt']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown';

    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
