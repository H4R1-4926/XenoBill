import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/route_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../application/business/business_bloc.dart';
import '../../infrastructure/database/app_database.dart';
import '../../domain/entities/business.dart';

import 'widgets/settings_section.dart';
import 'widgets/settings_group_card.dart';
import 'widgets/settings_tile.dart';
import 'widgets/business_profile_card.dart';
import 'widgets/destructive_action_tile.dart';
import 'widgets/invoice_settings_modals.dart';
import 'widgets/app_preferences_modals.dart';

import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';

class SettingsPage extends StatefulWidget {

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy),
        ),
        content: const Text(
          'Are you sure you want to logout? You will be redirected to the welcome screen.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              context.go(RouteConstants.welcome);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'More & Settings',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your business, preferences and app settings',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<BusinessBloc, BusinessState>(
          builder: (context, state) {
            final biz = (state is BusinessLoaded) ? state.business : AppDatabase.instance.currentBusiness;
            final isDemo = AppDatabase.instance.isDemoMode;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demo Banner
                  if (isDemo) ...[
                    AppCard(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You are exploring in DEMO MODE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const Text(
                                  'Changes made here use temporary demo data.',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.push(RouteConstants.businessTypeSelection),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Setup Real Shop', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search settings and tools',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // Recently Used Chips (Shown when search is empty)
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.history_rounded, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'Recently Used',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRecentChip(
                            icon: Icons.people_alt_outlined,
                            label: 'Customers',
                            onTap: () => context.push(RouteConstants.customers),
                          ),
                          _buildRecentChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Expenses',
                            onTap: () => context.push('/expenses'),
                          ),
                          _buildRecentChip(
                            icon: Icons.description_outlined,
                            label: 'Invoice Settings',
                            onTap: () => context.push(RouteConstants.invoiceSettings),
                          ),
                          _buildRecentChip(
                            icon: Icons.cloud_sync_outlined,
                            label: 'Backup & Restore',
                            onTap: () => context.push(RouteConstants.backupRestore),
                          ),
                          _buildRecentChip(
                            icon: Icons.bar_chart_rounded,
                            label: 'Analytics',
                            onTap: () => context.push(RouteConstants.reports),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Top Priority: Business Profile Card (Informational & Untappable Display Card)
                    BusinessProfileCard(
                      business: biz,
                    ),
                    const SizedBox(height: 8),

                    // 1. Business Management
                    const SettingsSection(
                      title: 'Business Management',
                      subtitle: 'Manage customers, expenses and business performance',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.people_alt_outlined,
                          iconColor: const Color(0xFF0284C7),
                          iconBackgroundColor: const Color(0xFFE0F2FE),
                          title: 'Customers',
                          subtitle: 'Manage customers and outstanding balances',
                          onTap: () => context.push(RouteConstants.customers),
                        ),
                        SettingsTile(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBackgroundColor: const Color(0xFFCCFBF1),
                          title: 'Expenses',
                          subtitle: 'Track business expenses and payments',
                          onTap: () => context.push('/expenses'),
                        ),
                        SettingsTile(
                          icon: Icons.bar_chart_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          iconBackgroundColor: const Color(0xFFEEF2FF),
                          title: 'Analytics & Reports',
                          subtitle: 'Sales, expenses, GST and business performance',
                          onTap: () => context.push(RouteConstants.reports),
                        ),
                      ],
                    ),

                    // 2. Business Settings
                    const SettingsSection(
                      title: 'Business Settings',
                      subtitle: 'Configure how Xenobiz works for your business',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.storefront_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBackgroundColor: const Color(0xFFF3E8FF),
                          title: 'Business Profile',
                          subtitle: 'Edit business information and business type',
                          trailingText: biz?.businessType ?? 'Retail Shop',
                          onTap: () => context.push(RouteConstants.editBusinessProfile),
                        ),
                        SettingsTile(
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBackgroundColor: const Color(0xFFCCFBF1),
                          title: 'GST Settings',
                          subtitle: 'Manage GST registration and tax settings',
                          trailingText: (biz?.gstEnabled ?? true) ? 'GST Active' : 'Exempt',
                          onTap: () => context.push(RouteConstants.gstSettings),
                        ),
                      ],
                    ),

                    // 3. Invoice & Printing
                    const SettingsSection(
                      title: 'Invoice & Printing',
                      subtitle: 'Configure invoices, numbering and printing',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBackgroundColor: const Color(0xFFDBEAFE),
                          title: 'Invoice',
                          subtitle: 'Invoice printing and invoice display settings',
                          onTap: () => context.push(RouteConstants.invoiceSettings),
                        ),
                        SettingsTile(
                          icon: Icons.pin_outlined,
                          iconColor: const Color(0xFFD97706),
                          iconBackgroundColor: const Color(0xFFFEF3C7),
                          title: 'Invoice Prefix & Numbering',
                          subtitle: 'Configure invoice prefixes and numbering',
                          trailingText: '${biz?.invoicePrefix ?? "INV"}-${biz?.nextInvoiceNumber ?? 1001}',
                          onTap: () => PrefixNumberingModal.show(context, biz),
                        ),
                      ],
                    ),

                    // 4. Data
                    const SettingsSection(
                      title: 'Data',
                      subtitle: 'Protect and manage your business data',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.cloud_sync_outlined,
                          iconColor: const Color(0xFF0284C7),
                          iconBackgroundColor: const Color(0xFFE0F2FE),
                          title: 'Backup & Restore',
                          subtitle: 'Backup your data or restore a previous backup',
                          onTap: () => context.push(RouteConstants.backupRestore),
                        ),
                      ],
                    ),

                    // 5. App Preferences
                    const SettingsSection(
                      title: 'App Preferences',
                      subtitle: 'Customize your Xenobiz experience',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF9333EA),
                          iconBackgroundColor: const Color(0xFFF3E8FF),
                          title: 'App Theme',
                          subtitle: 'Choose your preferred appearance',
                          trailingText: 'System Default',
                          onTap: () => AppThemeModal.show(context),
                        ),
                        SettingsTile(
                          icon: Icons.notifications_none_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBackgroundColor: const Color(0xFFFFEDD5),
                          title: 'Notifications',
                          subtitle: 'Manage alerts and reminders',
                          onTap: () => NotificationsModal.show(context),
                        ),
                      ],
                    ),

                    // 6. About
                    const SettingsSection(
                      title: 'About',
                      subtitle: 'App information and legal',
                    ),
                    SettingsGroupCard(
                      children: [
                        SettingsTile(
                          icon: Icons.info_outline,
                          iconColor: AppColors.darkNavy,
                          iconBackgroundColor: const Color(0xFFF1F5F9),
                          title: 'About Xenobiz',
                          subtitle: 'Version, help and information about Xenobiz',
                          trailingText: 'v1.0.0',
                          onTap: () => AboutXenobizModal.show(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 7. Logout Action (Full-width distinct destructive button)
                    DestructiveActionTile(
                      title: 'Logout',
                      onTap: () => _showLogoutConfirmationDialog(context),
                    ),
                  ] else ...[
                    // Search Filter Results View
                    const SizedBox(height: 16),
                    const Text(
                      'SEARCH RESULTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSearchResultsList(context, biz, isDemo),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.darkNavy),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context, Business? biz, bool isDemo) {
    final List<Map<String, dynamic>> allItems = [
      {
        'title': 'Business Profile',
        'sub': 'Manage business information, trade name and business type',
        'icon': Icons.storefront_rounded,
        'action': () => context.push(RouteConstants.editBusinessProfile),
      },
      {
        'title': 'GST Settings',
        'sub': 'Manage GST registration, GSTIN and tax rates',
        'icon': Icons.receipt_long_outlined,
        'action': () => context.push(RouteConstants.gstSettings),
      },
      {
        'title': 'Customers',
        'sub': 'Manage customers and outstanding balances',
        'icon': Icons.people_alt_outlined,
        'action': () => context.push(RouteConstants.customers),
      },
      {
        'title': 'Expenses',
        'sub': 'Track business expenses and payments',
        'icon': Icons.account_balance_wallet_outlined,
        'action': () => context.push('/expenses'),
      },
      {
        'title': 'Analytics & Reports',
        'sub': 'Sales, expenses, GST and business performance',
        'icon': Icons.bar_chart_rounded,
        'action': () => context.push(RouteConstants.reports),
      },
      {
        'title': 'Invoice',
        'sub': 'Invoice printing and invoice display settings',
        'icon': Icons.description_outlined,
        'action': () => context.push(RouteConstants.invoiceSettings),
      },
      {
        'title': 'Invoice Prefix & Numbering',
        'sub': 'Configure invoice prefixes and numbering sequence',
        'icon': Icons.pin_outlined,
        'action': () => PrefixNumberingModal.show(context, biz),
      },
      {
        'title': 'Backup & Restore',
        'sub': 'Backup your data or restore a previous backup',
        'icon': Icons.cloud_sync_outlined,
        'action': () => context.push(RouteConstants.backupRestore),
      },
      {
        'title': 'App Theme',
        'sub': 'Choose your preferred appearance (System, Light, Dark)',
        'icon': Icons.palette_outlined,
        'action': () => AppThemeModal.show(context),
      },
      {
        'title': 'Notifications',
        'sub': 'Manage alerts, payment reminders and due balance notifications',
        'icon': Icons.notifications_none_outlined,
        'action': () => NotificationsModal.show(context),
      },
      {
        'title': 'About Xenobiz',
        'sub': 'Version, help and information about Xenobiz',
        'icon': Icons.info_outline,
        'action': () => AboutXenobizModal.show(context),
      },
    ];

    final filtered = allItems.where((item) {
      final titleStr = (item['title'] as String).toLowerCase();
      final subStr = (item['sub'] as String).toLowerCase();
      return titleStr.contains(_searchQuery) || subStr.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text('No settings found for "$_searchQuery"', style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return SettingsGroupCard(
      children: filtered.map((item) {
        return SettingsTile(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['sub'] as String,
          onTap: item['action'] as VoidCallback,
        );
      }).toList(),
    );
  }
}
