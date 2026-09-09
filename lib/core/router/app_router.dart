import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/route_constants.dart';
import '../../infrastructure/database/app_database.dart';
import '../../presentation/auth/pages/welcome_page.dart';
import '../../presentation/auth/pages/register_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/business_type_selection_page.dart';
import '../../presentation/auth/pages/business_setup_page.dart';
import '../../domain/entities/business_type.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/customer.dart';
import '../../presentation/main_layout/main_layout_page.dart';
import '../../presentation/dashboard/dashboard_page.dart';
import '../../presentation/sales/sales_history_page.dart';
import '../../presentation/invoice/pages/add_invoice_page.dart';
import '../../presentation/invoice/pages/invoice_detail_page.dart';
import '../../presentation/inventory/pages/inventory_page.dart';
import '../../presentation/inventory/pages/add_edit_product_page.dart';
import '../../presentation/inventory/pages/product_detail_page.dart';
import '../../presentation/customers/pages/customers_page.dart';
import '../../presentation/customers/pages/add_edit_customer_page.dart';
import '../../presentation/reports/reports_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/settings/pages/business_settings_page.dart';
import '../../presentation/settings/pages/business_profile_edit_page.dart';
import '../../presentation/settings/pages/gst_settings_page.dart';
import '../../presentation/settings/pages/invoice_settings_page.dart';
import '../../presentation/settings/pages/backup_restore_page.dart';
import '../../presentation/expenses/expenses_page.dart';
import '../../presentation/smart/smart_insights_page.dart';
import '../../presentation/customers/pages/customer_profile_page.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.welcome,
    redirect: (context, state) {
      final db = AppDatabase.instance;
      final hasSupabaseSession = Supabase.instance.client.auth.currentSession != null;
      final isAuthenticated = db.isLoggedIn || hasSupabaseSession;
      if (db.currentBusiness != null) {
        db.isBusinessConfigured = true;
      }

      final isWelcomeRoute = state.matchedLocation == RouteConstants.welcome;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
                          state.matchedLocation == RouteConstants.register ||
                          state.matchedLocation == RouteConstants.businessTypeSelection ||
                          state.matchedLocation == RouteConstants.businessSetup;

      if (!isAuthenticated && !isWelcomeRoute && !isAuthRoute) {
        return RouteConstants.welcome;
      }

      if (isAuthenticated && !db.isBusinessConfigured) {
        if (state.matchedLocation != RouteConstants.businessTypeSelection &&
            state.matchedLocation != RouteConstants.businessSetup) {
          return RouteConstants.businessTypeSelection;
        }
      }

      if (isAuthenticated && db.isBusinessConfigured && (isWelcomeRoute || isAuthRoute)) {
        return RouteConstants.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RouteConstants.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.businessTypeSelection,
        builder: (context, state) => const BusinessTypeSelectionPage(),
      ),
      GoRoute(
        path: RouteConstants.businessSetup,
        builder: (context, state) {
          final type = state.extra as BusinessType? ?? BusinessType.retail;
          return BusinessSetupPage(selectedType: type);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.addInvoice,
        builder: (context, state) => const AddInvoicePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.invoiceDetail,
        builder: (context, state) {
          final invoiceId = state.pathParameters['id'] ?? '';
          return InvoiceDetailPage(invoiceId: invoiceId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.addEditProduct,
        builder: (context, state) {
          final item = state.extra as Item?;
          return AddEditProductPage(initialItem: item);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.productDetail,
        builder: (context, state) {
          final item = state.extra as Item;
          return ProductDetailPage(item: item);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.customers,
        builder: (context, state) => const MainLayoutPage(child: CustomersPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.addEditCustomer,
        builder: (context, state) {
          final customer = state.extra as Customer?;
          return AddEditCustomerPage(initialCustomer: customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.customerProfile,
        builder: (context, state) {
          final customer = state.extra as Customer;
          return CustomerProfilePage(customer: customer);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.reports,
        builder: (context, state) => const MainLayoutPage(child: ReportsPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/expenses',
        builder: (context, state) => const MainLayoutPage(child: ExpensesPage()),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/smart',
        builder: (context, state) => const SmartInsightsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.businessSettings,
        builder: (context, state) => const BusinessSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.editBusinessProfile,
        builder: (context, state) => const BusinessProfileEditPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.gstSettings,
        builder: (context, state) => const GstSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.invoiceSettings,
        builder: (context, state) => const InvoiceSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.backupRestore,
        builder: (context, state) => const BackupRestorePage(),
      ),
      // Main Stateful Shell Route with Floating Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutPage(
            navigationShell: navigationShell,
            state: state,
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.home,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.sales,
                builder: (context, state) => const SalesHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.shop,
                builder: (context, state) => const InventoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

