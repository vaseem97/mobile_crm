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
  bool _isUpdating = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

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
        _errorMessage = null;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary))
            : RefreshIndicator(
                onRefresh: _loadUserData,
                color: colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context),
                      const SizedBox(height: 24),
                      _buildShopInfoSection(context),
                      const SizedBox(height: 20),
                      _buildPersonalInfoSection(context),
                      const SizedBox(height: 20),
                      _buildActionsSection(context),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                      const SizedBox(height: 32),
                      _buildMadeInBharat(context),
                    ],
                  ),
                ),
              ),
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = _authService.currentUser;
    final userName = _userData?['name'] ?? currentUser?.displayName ?? 'User';
    final userEmail = _userData?['email'] ?? currentUser?.email ?? '';
    final createdAt = _formatDate(_userData?['createdAt']);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Text(
                        _getInitials(userName),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _editPersonalInfo(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.8),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Shop Owner',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (createdAt != null && createdAt != 'Unknown') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Joined on $createdAt',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shopName = _userData?['shopName'] ?? 'Your Shop';
    final address = _userData?['address'] ?? 'Not provided';
    final gstNumber = _userData?['gstNumber'] ?? 'Not provided';

    // Check if any shop information is missing
    final isMissingInfo = shopName == 'Your Shop' || address == 'Not provided';

    return Card(
      elevation: 0,
      color: isMissingInfo
          ? colorScheme.errorContainer.withOpacity(0.3)
          : colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.store_rounded,
                  color:
                      isMissingInfo ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Shop Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (isMissingInfo) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Required for Invoice',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: () {
                    _editShopInfo(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: isMissingInfo
                          ? colorScheme.error
                          : colorScheme.primary,
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
            Icons.store_rounded,
            iconColor: colorScheme.primary.withOpacity(0.8),
            valueColor: colorScheme.onPrimaryContainer,
            isError: shopName == 'Your Shop',
          ),
          _buildInfoItem(
            context,
            'Address',
            address,
            Icons.location_on_rounded,
            iconColor: colorScheme.primary.withOpacity(0.8),
            valueColor: colorScheme.onPrimaryContainer,
            isError: address == 'Not provided',
          ),
          _buildInfoItem(
            context,
            'GST Number',
            gstNumber,
            Icons.receipt_long_rounded,
            iconColor: colorScheme.primary.withOpacity(0.8),
            valueColor: colorScheme.onPrimaryContainer,
          ),
          // Add a help text at the bottom
          if (isMissingInfo)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your shop information to generate professional invoices',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userEmail =
        _userData?['email'] ?? _authService.currentUser?.email ?? '';
    final userName = _userData?['name'] ??
        _authService.currentUser?.displayName ??
        'Add your name';
    final userPhone = _userData?['phone'] ?? '';
    final isEmailVerified = _authService.currentUser?.emailVerified ?? false;
    final createdAt = _formatDate(_userData?['createdAt']);

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    _editPersonalInfo(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildInfoItem(
            context,
            'Full Name',
            userName,
            Icons.person_rounded,
            iconColor: colorScheme.secondary.withOpacity(0.8),
            valueColor: colorScheme.onSecondaryContainer,
          ),
          _buildInfoItem(
            context,
            'Email Address',
            userEmail,
            Icons.email_rounded,
            iconColor: colorScheme.secondary.withOpacity(0.8),
            valueColor: colorScheme.onSecondaryContainer,
            suffix: isEmailVerified
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          _buildInfoItem(
            context,
            'Phone Number',
            userPhone.isNotEmpty ? userPhone : 'Add your phone number',
            Icons.phone_rounded,
            iconColor: colorScheme.secondary.withOpacity(0.8),
            valueColor: colorScheme.onSecondaryContainer,
            isLast: createdAt == null,
          ),
          if (createdAt != null)
            _buildInfoItem(
              context,
              'Account Created',
              createdAt,
              Icons.calendar_today_rounded,
              iconColor: colorScheme.secondary.withOpacity(0.8),
              valueColor: colorScheme.onSecondaryContainer,
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
    Color? iconColor,
    Color? valueColor,
    Widget? suffix,
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDummy = value == 'Not provided' || value == 'Your Shop';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isError || isDummy)
                      ? colorScheme.errorContainer.withOpacity(0.5)
                      : colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: (isError || isDummy)
                      ? colorScheme.error
                      : (iconColor ?? colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isError || isDummy) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isDummy ? FontWeight.normal : FontWeight.w500,
                        color: isDummy
                            ? colorScheme.error.withOpacity(0.7)
                            : (valueColor ?? colorScheme.onSurface),
                        fontStyle:
                            isDummy ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (suffix != null) suffix,
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(
            context,
            'Settings',
            Icons.settings_rounded,
            onTap: () {
              // Navigate to settings
            },
          ),
          _buildActionItem(
            context,
            'Support & Help',
            Icons.support_agent_rounded,
            onTap: () {
              // Navigate to support
            },
          ),
          _buildActionItem(
            context,
            'Privacy Policy',
            Icons.privacy_tip_rounded,
            onTap: () {
              // Navigate to privacy policy
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 58,
              color: colorScheme.outlineVariant.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: () {
          _showLogoutConfirmation(context);
        },
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.errorContainer.withOpacity(0.7),
          foregroundColor: colorScheme.onErrorContainer,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 20,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMadeInBharat(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.language,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Made with ❤️ in Bharat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mobile CRM v1.0',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              setState(() {
                _isUpdating = true;
              });

              try {
                final authService = getService<FirebaseAuthService>();
                await authService.signOut();

                if (mounted) {
                  setState(() {
                    _isUpdating = false;
                  });
                  context.push('/login');
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isUpdating = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _editShopInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final shopNameController = TextEditingController(
      text: _userData?['shopName'] ?? '',
    );
    final addressController = TextEditingController(
      text: _userData?['address'] ?? '',
    );
    final gstController = TextEditingController(
      text: _userData?['gstNumber'] ?? '',
    );

    // Helper to check if required fields are filled
    bool areRequiredFieldsFilled() {
      return shopNameController.text.trim().isNotEmpty &&
          addressController.text.trim().isNotEmpty;
    }

    // Track if the required fields are filled
    bool isFormValid = areRequiredFieldsFilled();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.store_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Shop Information',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Shop information is used to personalize your invoices',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Shop Name Field
                Text(
                  'Shop Name *',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: shopNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your shop name',
                    prefixIcon: Icon(
                      Icons.store_rounded,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      isFormValid = areRequiredFieldsFilled();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Address Field
                Text(
                  'Shop Address *',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Enter your shop address',
                    prefixIcon: Icon(
                      Icons.location_on_rounded,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    setDialogState(() {
                      isFormValid = areRequiredFieldsFilled();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // GST Number Field
                Row(
                  children: [
                    Text(
                      'GST Number',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: gstController,
                  decoration: InputDecoration(
                    hintText: 'Enter your GST number (optional)',
                    prefixIcon: Icon(
                      Icons.receipt_long_rounded,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),

                // Required fields note
                Text(
                  '* Required fields for invoice generation',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                ),
              ),
            ),
            FilledButton(
              onPressed: isFormValid
                  ? () async {
                      Navigator.of(context).pop();

                      setState(() {
                        _isUpdating = true;
                        _errorMessage = null;
                      });

                      try {
                        final uid = _authService.currentUser!.uid;

                        final updatedData = {
                          'shopName': shopNameController.text.trim(),
                          'address': addressController.text.trim(),
                          'gstNumber': gstController.text.trim(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        };

                        await _firestoreService.updateDocument(
                          collectionPath: 'users',
                          documentId: uid,
                          data: updatedData,
                        );

                        await _loadUserData();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Shop information updated successfully'),
                              backgroundColor: colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error updating shop info: $e');
                        _errorMessage = 'Error updating information: $e';

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating information: $e'),
                              backgroundColor: colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isUpdating = false;
                          });
                        }
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor:
                    colorScheme.onSurface.withOpacity(0.12),
                disabledForegroundColor:
                    colorScheme.onSurface.withOpacity(0.38),
              ),
              child: const Text('Update'),
            ),
          ],
        );
      }),
    );
  }

  void _editPersonalInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nameController = TextEditingController(
      text: _userData?['name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _userData?['phone'] ?? '',
    );
    final emailController = TextEditingController(
      text: _userData?['email'] ?? _authService.currentUser?.email ?? '',
    );

    final isEmailVerified = _authService.currentUser?.emailVerified ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_rounded, color: colorScheme.secondary),
            const SizedBox(width: 12),
            Text(
              'Update Personal Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Your personal name',
                  prefixIcon: Icon(Icons.person, color: colorScheme.secondary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Your contact number',
                  prefixIcon: Icon(Icons.phone, color: colorScheme.secondary),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email,
                      color: colorScheme.secondary.withOpacity(0.7)),
                  suffixIcon: isEmailVerified
                      ? Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.tertiaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              if (!isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please verify your email address',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Note: Email cannot be changed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              setState(() {
                _isUpdating = true;
                _errorMessage = null;
              });

              try {
                final uid = _authService.currentUser!.uid;

                final updatedData = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                await _firestoreService.updateDocument(
                  collectionPath: 'users',
                  documentId: uid,
                  data: updatedData,
                );

                await _loadUserData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Personal information updated successfully'),
                      backgroundColor: colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error updating personal info: $e');
                _errorMessage = 'Error updating information: $e';

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating information: $e'),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isUpdating = false;
                  });
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? isoString) {
    if (isoString == null) return null;

    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
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
