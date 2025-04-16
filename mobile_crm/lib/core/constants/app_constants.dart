class AppConstants {
  // App information
  static const String appName = 'Mobile Repair CRM';
  static const String appVersion = '1.0.0';

  // Collection names for Firestore
  static const String usersCollection = 'users';
  static const String repairJobsCollection = 'repair_jobs';
  static const String statisticsCollection = 'statistics';
  static const String shopInfoCollection = 'shop_info';
  static const String customersCollection = 'customers';

  // Storage paths
  static const String repairImagesPath = 'repair_images';
  static const String profileImagesPath = 'profile_images';

  // Shared Preferences keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String darkModeKey = 'dark_mode';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Common device brands
  static const List<String> deviceBrands = [
    'Samsung',
    'Apple',
    'Xiaomi',
    'Oppo',
    'Vivo',
    'Realme',
    'OnePlus',
    'Motorola',
    'Nokia',
    'Google',
    'Nothing',
    'Poco',
    'Asus',
    'Lenovo',
    'Other',
  ];

  // Common repair problems
  static const List<String> commonRepairProblems = [
    'Screen replacement',
    'Battery replacement',
    'Charging port repair',
    'Speaker repair',
    'Microphone repair',
    'Camera repair',
    'Water damage repair',
    'Software issues',
    'Motherboard repair',
    'Other',
  ];

  // Common device colors
  static const List<String> deviceColors = [
    'Black',
    'White',
    'Blue',
    'Red',
    'Green',
    'Yellow',
    'Purple',
    'Pink',
    'Gold',
    'Silver',
    'Gray',
    'Other',
  ];

  // Format validation regexes
  static const String phoneRegex = r'^\d{10}$';
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String passwordRegex = r'^.{6,}$';

  // Warranty Options
  static const List<String> warrantyOptions = [
    'No Warranty',
    '15 Days',
    '30 Days',
    '60 Days',
    '90 Days',
    '6 Months',
    '1 Year',
  ];

  // Cloudinary configuration
  static const String cloudinaryApiKey = "268839765697753";
  static const String cloudinaryApiSecret = "kfO0acQafXvpQZthuBiM6UzWm-Q";
  static const String cloudinaryCloudName = "dq4rmz79q";
}
