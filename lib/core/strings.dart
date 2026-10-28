abstract final class AppStrings {
  // App
  static const String appName = 'HostelHub';
  static const String appTagline = 'Hostel & PG Rent Management';

  // Navigation Tabs
  static const String navDashboard = 'Dashboard';
  static const String navResidents = 'Residents';
  static const String navRooms = 'Rooms';
  static const String navRent = 'Rent';
  static const String navSettings = 'Settings';

  // Configuration Error
  static const String configMissingTitle = 'Missing Configuration';
  static const String configMissingMessage =
      'Supabase environment variables (SUPABASE_URL and SUPABASE_ANON_KEY) are not set. Please supply them via --dart-define or --dart-define-from-file=env.json.';

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';
  static const String businessName = 'Hostel / Business Name';
  static const String forgotPasswordPrompt = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? Sign Up";
  static const String alreadyHaveAccount = 'Already have an account? Sign In';
  static const String sendResetCode = 'Send Reset Code';
  static const String verifyAndReset = 'Verify & Update Password';
  static const String otpCode = '6-Digit Verification Code';
  static const String newPassword = 'New Password';
  static const String passwordMinLength = 'Password must be at least 8 characters';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String requiredField = 'This field is required';

  // Actions & Buttons
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String edit = 'Edit';
  static const String close = 'Close';
  static const String add = 'Add';

  // Statuses
  static const String statusPaid = 'Paid';
  static const String statusPending = 'Pending';
  static const String statusPartial = 'Partial';
  static const String statusOverdue = 'Overdue';
  static const String statusActive = 'Active';
  static const String statusLeft = 'Left';

  // Common Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noDataFound = 'No data available.';
  static const String loading = 'Loading...';

  // Settings
  static const String profile = 'Profile';
  static const String privacyPolicy = 'Privacy Policy';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountConfirmation =
      'Type DELETE to confirm account deletion. This will permanently remove all your properties, rooms, residents, and payment records.';
  static const String deleteAccountWarning =
      'Warning: This action is permanent and cannot be undone.';
  static const String deleteKeyword = 'DELETE';
  static const String about = 'About HostelHub';
}
