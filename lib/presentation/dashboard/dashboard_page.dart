import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/xenobiz_app_bar.dart';
import '../../application/business/business_bloc.dart';
import '../../application/sales/sales_bloc.dart';
import '../../application/inventory/inventory_bloc.dart';
import '../../application/customers/customers_bloc.dart';
import '../../application/smart/smart_bloc.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/business_type.dart';
import '../../domain/entities/business_configuration.dart';
import '../../domain/entities/invoice.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _chartPeriod = '7 Days';

  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(LoadBusinessEvent());
    context.read<SalesBloc>().add(LoadSalesEvent());
    context.read<InventoryBloc>().add(LoadInventoryEvent());
    context.read<CustomersBloc>().add(LoadCustomersEvent());
    context.read<SmartBloc>().add(LoadSmartInsightsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<SalesBloc>().add(LoadSalesEvent());
            context.read<InventoryBloc>().add(LoadInventoryEvent());
            context.read<CustomersBloc>().add(LoadCustomersEvent());
            context.read<SmartBloc>().add(LoadSmartInsightsEvent());
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: BlocBuilder<BusinessBloc, BusinessState>(
              builder: (context, bizState) {
                Business? business;
                if (bizState is BusinessLoaded) {
                  business = bizState.business;
                }
                final config = business?.configuration ?? BusinessConfiguration.fromType(business?.type ?? BusinessType.retail);
                final terminology = config.terminology;
                final features = config.features;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    _buildHeader(context, business, bizState is BusinessLoaded ? bizState.isDemoMode : false),
                    const SizedBox(height: AppSpacing.md),

                    // Smart Insight Home Widget
                    if (features.smartInsightsEnabled) ...[
                      _buildSmartHomeWidget(context),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Adaptive KPI Summary Cards based on features
                    _buildKpiGrid(context, config),
                    const SizedBox(height: AppSpacing.md),

                    // Interactive Sales Chart Card
                    _buildSalesChartCard(context),
                    const SizedBox(height: AppSpacing.md),

                    // Low Stock Preview Alert (Only if inventory is enabled)
                    if (features.inventoryEnabled) ...[
                      _buildLowStockPreview(context),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Recent Sales List
                    _buildRecentSalesList(context, terminology.invoices),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Business? business, bool isDemo) {
    return XenobizHeaderAppBar(
      business: business,
      isDemoMode: isDemo,
      onNotificationTap: () => context.push('/smart'),
    );
  }

  Widget _buildSmartHomeWidget(BuildContext context) {
    return BlocBuilder<SmartBloc, SmartState>(
      builder: (context, state) {
        if (state is SmartLoaded && state.insights.isNotEmpty) {
          final topInsight = state.insights.first;
          return AppCard(
            color: Colors.cyan.shade50,
            border: Border.all(color: AppColors.brightCyan.withValues(alpha: 0.5)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.brightCyan, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topInsight.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
                      Text(topInsight.message, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/smart'),
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return AppCard(
          color: Colors.cyan.shade50.withValues(alpha: 0.5),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.brightCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keep using Xenobiz and Smart Insights will appear here.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, BusinessConfiguration config) {
    final features = config.features;
    final terminology = config.terminology;

    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, salesState) {
        return BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, invState) {
            return BlocBuilder<CustomersBloc, CustomersState>(
              builder: (context, custState) {
                double todaySales = 0.0;
                int todayBills = 0;
                double cashSales = 0.0;
                double creditSales = 0.0;
                int lowStockCount = 0;
                double outstanding = 0.0;

                if (salesState is SalesLoaded) {
                  todaySales = salesState.todaySales;
                  todayBills = salesState.todayBillsCount;
                  cashSales = salesState.cashSales;
                  creditSales = salesState.creditSales;
                }

                if (invState is InventoryLoaded) {
                  lowStockCount = invState.lowStockCount;
                }

                if (custState is CustomersLoaded) {
                  outstanding = custState.totalOutstanding;
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            'Today\'s Revenue',
                            CurrencyFormatter.format(todaySales),
                            Icons.currency_rupee,
                            AppColors.brightCyan,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildKpiCard(
                            'Today\'s ${terminology.invoices}',
                            '$todayBills',
                            Icons.receipt_long,
                            AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            'Cash Sales',
                            CurrencyFormatter.format(cashSales),
                            Icons.payments_outlined,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildKpiCard(
                            'Credit Sales',
                            CurrencyFormatter.format(creditSales),
                            Icons.account_balance_wallet_outlined,
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    if (features.inventoryEnabled || features.customersEnabled || features.hotelEnabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          if (features.inventoryEnabled)
                            Expanded(
                              child: _buildKpiCard(
                                'Low Stock',
                                '$lowStockCount Items',
                                Icons.inventory_2_outlined,
                                lowStockCount > 0 ? AppColors.error : AppColors.textSecondary,
                                onTap: () => context.go(RouteConstants.shop),
                              ),
                            ),
                          if (features.inventoryEnabled && features.customersEnabled)
                            const SizedBox(width: AppSpacing.md),
                          if (features.customersEnabled && features.creditSalesEnabled)
                            Expanded(
                              child: _buildKpiCard(
                                'Outstanding',
                                CurrencyFormatter.format(outstanding),
                                Icons.people_outline,
                                outstanding > 0 ? AppColors.error : AppColors.textSecondary,
                                onTap: () => context.go(RouteConstants.customers),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color iconColor, {VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.kpiValue.copyWith(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartCard(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, salesState) {
        final invoices = salesState is SalesLoaded ? salesState.allInvoices : [];

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sales Trend', style: AppTextStyles.h3),
                  Row(
                    children: ['Today', '7 Days', '30 Days'].map((period) {
                      final isSelected = _chartPeriod == period;
                      return GestureDetector(
                        onTap: () => setState(() => _chartPeriod = period),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brightCyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.deepNavy : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 140,
                child: invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.show_chart, color: Colors.black26, size: 36),
                            const SizedBox(height: 4),
                            Text(
                              'Start billing to view sales trend',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: invoices.isEmpty
                                  ? const [FlSpot(0, 0)]
                                  : invoices.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.grandTotal)).toList(),
                              isCurved: true,
                              color: AppColors.brightCyan,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.brightCyan.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockPreview(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded && state.lowStockCount > 0) {
          final lowItems = state.products.where((p) => p.isLowStock).toList();
          return AppCard(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Low Stock Alert (${state.lowStockCount})', style: AppTextStyles.h3.copyWith(color: AppColors.error)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RouteConstants.shop),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                ...lowItems.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text('• ${item.name}', style: AppTextStyles.bodyMedium),
                          const Spacer(),
                          Text('Stock: ${item.currentStock} ${item.unit}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentSalesList(BuildContext context, String invoiceLabel) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        if (state is SalesLoaded) {
          final recent = state.allInvoices.take(4).toList();

          if (recent.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.lightGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.brightCyan),
                    ),
                    const SizedBox(height: 10),
                    Text('No $invoiceLabel yet', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first $invoiceLabel to see activity here.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent $invoiceLabel', style: AppTextStyles.h2),
                  TextButton(
                    onPressed: () => context.go(RouteConstants.sales),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ...recent.map((inv) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () => context.push('/invoice/${inv.id}'),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: inv.paymentType == PaymentType.cash ? AppColors.brightCyan.withValues(alpha: 0.15) : Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              inv.paymentType == PaymentType.cash ? Icons.payments : Icons.account_balance_wallet,
                              color: inv.paymentType == PaymentType.cash ? AppColors.darkNavy : Colors.orange.shade800,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv.invoiceNumber, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                Text('${inv.customerName} • ${DateFormatter.formatTime(inv.invoiceDate)}', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.format(inv.grandTotal), style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: inv.status == InvoiceStatus.paid ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  inv.paymentType.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: inv.status == InvoiceStatus.paid ? Colors.green.shade900 : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
