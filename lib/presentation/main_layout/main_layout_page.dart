import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/route_constants.dart';
import '../../application/business/business_bloc.dart';
import '../../domain/entities/business.dart';
import '../navigation/xenobiz_bottom_navigation_bar.dart';

import 'package:flutter/services.dart';
import '../../infrastructure/services/backup_service.dart';

class MainLayoutPage extends StatelessWidget {
  final Widget child;
  final GoRouterState? state;

  const MainLayoutPage({
    super.key,
    required this.child,
    this.state,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = state?.matchedLocation ?? state?.uri.path ?? _getSafePath(context);
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/sales')) return 1;
    if (location.startsWith('/shop') || location.startsWith('/inventory')) return 3;
    if (location.startsWith('/settings') || location.startsWith('/customers')) return 4;
    return 0;
  }

  String _getSafePath(BuildContext context) {
    try {
      return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '/home';
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteConstants.home);
        break;
      case 1:
        context.go(RouteConstants.sales);
        break;
      case 2:
        context.push(RouteConstants.addInvoice);
        break;
      case 3:
        context.go(RouteConstants.shop);
        break;
      case 4:
        context.go(RouteConstants.settings);
        break;
    }
  }

  Future<void> _handleAppExit(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Xenobill?'),
        content: const Text(
          'Would you like to create a local database backup before closing the app?',
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit_no_backup'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit Without Backup'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'backup_and_exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Backup & Exit'),
          ),
        ],
      ),
    );

    if (result == 'exit_no_backup') {
      SystemNavigator.pop();
    } else if (result == 'backup_and_exit') {
      try {
        await BackupService.instance.createLocalBackup();
      } catch (_) {}
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleAppExit(context);
      },
      child: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, bizState) {
          Business? business;
          if (bizState is BusinessLoaded) {
            business = bizState.business;
          }

          final inventoryLabel = business?.terminology.inventory ?? 'Inventory';
          const inventoryIcon = Icons.inventory_2_outlined;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  // Responsive Side Navigation for Desktop
                  Material(
                    color: AppColors.deepNavy,
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.brightCyan,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long, color: AppColors.deepNavy, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'XENOBIZ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // CTA Add Invoice
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(RouteConstants.addInvoice),
                              icon: const Icon(Icons.add, color: AppColors.deepNavy, size: 24),
                              label: Text(
                                '+ ${business?.terminology.addInvoice.toUpperCase() ?? 'ADD INVOICE'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepNavy, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brightCyan,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildNavTile(Icons.dashboard_outlined, Icons.dashboard, 'Home', selectedIndex == 0, () => _onItemTapped(0, context)),
                          _buildNavTile(Icons.receipt_outlined, Icons.receipt, 'Sales', selectedIndex == 1, () => _onItemTapped(1, context)),
                          _buildNavTile(inventoryIcon, inventoryIcon, inventoryLabel, selectedIndex == 3, () => _onItemTapped(3, context)),
                          _buildNavTile(Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'More', selectedIndex == 4, () => _onItemTapped(4, context)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          // Mobile / Tablet Bottom Navigation Layout
          return Scaffold(
            body: child,
            extendBody: false,
            bottomNavigationBar: XenobizBottomNavigationBar(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(index, context),
              inventoryLabel: inventoryLabel,
              inventoryIcon: inventoryIcon,
              inventorySelectedIcon: Icons.inventory_2,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavTile(IconData icon, IconData activeIcon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.brightCyan : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.brightCyan : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
