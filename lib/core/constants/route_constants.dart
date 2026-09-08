class RouteConstants {
  RouteConstants._();

  static const String welcome = '/welcome';
  static const String register = '/register';
  static const String login = '/login';
  static const String businessTypeSelection = '/business-type-selection';
  static const String businessSetup = '/business-setup';
  
  static const String home = '/home';
  static const String sales = '/sales';
  static const String addInvoice = '/invoice/new';
  static const String invoiceDetail = '/invoice/:id';
  static const String shop = '/shop';
  static const String inventory = '/inventory';
  static const String addEditProduct = '/inventory/edit';
  static const String productDetail = '/inventory/detail';
  static const String customers = '/customers';
  static const String addEditCustomer = '/customers/edit';
  static const String customerProfile = '/customers/profile';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String invoiceSettings = '/settings/invoice';
  static const String businessSettings = '/settings/business';
  static const String editBusinessProfile = '/settings/business/profile';
  static const String gstSettings = '/settings/business/gst';
  static const String backupRestore = '/settings/backup-restore';
}

class StorageConstants {
  StorageConstants._();

  static const String isDemoMode = 'is_demo_mode';
  static const String isLoggedIn = 'is_logged_in';
  static const String isBusinessConfigured = 'is_business_configured';
  static const String activeBusinessId = 'active_business_id';
  static const String userAuthToken = 'user_auth_token';
}
