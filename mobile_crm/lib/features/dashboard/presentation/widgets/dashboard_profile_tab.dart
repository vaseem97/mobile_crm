import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/service_locator.dart';

class DashboardProfileTab extends StatefulWidget {
  const DashboardProfileTab({Key? key}) : super(key: key);

  @override
  State<DashboardProfileTab> createState() => _DashboardProfileTabState();
}

class _DashboardProfileTabState extends State<DashboardProfileTab> {
  final FirebaseAuthService _authService = getService<FirebaseAuthService>();
  final FirestoreService _firestoreService = getService<FirestoreService>();

  bool _isLoading = true;
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
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 24),
                _buildShopInfoSection(context),
                const SizedBox(height: 16),
                _buildSettingsSection(context),
                const SizedBox(height: 16),
                _buildHelpSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
              ],
            ),
          );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final currentUser = _authService.currentUser;
    final userName = _userData?['name'] ?? currentUser?.displayName ?? 'User';
    final userEmail = _userData?['email'] ?? currentUser?.email ?? '';
    final userPhone = _userData?['phone'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _getInitials(userName),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (userPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verified Shop Owner',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfoSection(BuildContext context) {
    final shopName = _userData?['shopName'] ?? 'Your Shop';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.store,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Shop Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    // Edit shop information
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildInfoItem(
            context,
            'Shop Name',
            shopName,
            Icons.store_mall_directory,
          ),
          _buildInfoItem(
            context,
            'Address',
            _userData?['address'] ?? 'Add your shop address',
            Icons.location_on,
          ),
          _buildInfoItem(
            context,
            'Working Hours',
            _userData?['workingHours'] ??
                '10:00 AM - 8:00 PM (Monday - Saturday)',
            Icons.access_time,
          ),
          _buildInfoItem(
            context,
            'GST Number',
            _userData?['gstNumber'] ?? 'Add your GST Number',
            Icons.receipt_long,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            'App Settings',
            Icons.app_settings_alt,
            onTap: () {
              // Navigate to app settings
            },
          ),
          _buildSettingItem(
            context,
            'Notification Settings',
            Icons.notifications,
            onTap: () {
              // Navigate to notification settings
            },
          ),
          _buildSettingItem(
            context,
            'Print Settings',
            Icons.print,
            onTap: () {
              // Navigate to print settings
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.help,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Help & Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            'FAQ',
            Icons.help_outline,
            onTap: () {
              // Navigate to FAQ
            },
          ),
          _buildSettingItem(
            context,
            'Contact Support',
            Icons.support_agent,
            onTap: () {
              // Navigate to contact support
            },
          ),
          _buildSettingItem(
            context,
            'Terms & Conditions',
            Icons.description,
            onTap: () {
              // Navigate to terms and conditions
            },
          ),
          _buildSettingItem(
            context,
            'Privacy Policy',
            Icons.privacy_tip,
            onTap: () {
              // Navigate to privacy policy
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return CustomButton(
      text: 'Logout',
      onPressed: () {
        _showLogoutConfirmation(context);
      },
      isOutlined: true,
      leadingIcon: Icons.logout,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Get auth service and sign out
                final authService = getService<FirebaseAuthService>();
                await authService.signOut();

                // Navigate to login screen
                if (context.mounted) {
                  // Remove loading dialog
                  Navigator.of(context).pop();
                  context.go('/login');
                }
              } catch (e) {
                // Remove loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout'),
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
}
