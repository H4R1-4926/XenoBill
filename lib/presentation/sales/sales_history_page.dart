import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_search_field.dart';
import '../../application/sales/sales_bloc.dart';
import '../../application/business/business_bloc.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/invoice.dart';
import '../../infrastructure/database/app_database.dart';
import '../invoice/widgets/receipt_preview_dialog.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  String _selectedDateFilter = 'Today';
  String _selectedPaymentFilter = 'All';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(LoadSalesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, bizState) {
        Business? business;
        if (bizState is BusinessLoaded) {
          business = bizState.business;
        }

        final terminology = business?.terminology;
        final invoiceLabel = terminology?.invoices ?? 'Invoices';

        return Scaffold(
          backgroundColor: AppColors.lightGray,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER ROW ("Sales" title on left, circular search button on right)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sales',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                          letterSpacing: -0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isSearchOpen = !_isSearchOpen;
                            if (!_isSearchOpen) {
                              _searchController.clear();
                              _applyFilters(searchQuery: '');
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSearchOpen ? Icons.close : Icons.search,
                            color: AppColors.nearBlack,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. TWO MODERN SUMMARY CARDS (Today's sales & Today's bills)
                _buildSummaryCards(),
                const SizedBox(height: 16),

                // 3. SEARCH BAR (If search open) & FILTERS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_isSearchOpen) ...[
                        AppSearchField(
                          controller: _searchController,
                          hint: 'Search by invoice # or customer...',
                          onChanged: (q) => _applyFilters(searchQuery: q),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildFilterRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. INVOICES TRANSACTION LIST
                Expanded(
                  child: BlocBuilder<SalesBloc, SalesState>(
                    builder: (context, state) {
                      if (state is SalesLoaded) {
                        final invoices = state.filteredInvoices;
                        if (invoices.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 44,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No $invoiceLabel found',
                                    style: AppTextStyles.h2,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first $invoiceLabel to see transactions here.',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: invoices.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 68,
                                  endIndent: 16,
                                  color: Color(0xFFF0F0F0),
                                ),
                                itemBuilder: (context, index) {
                                  final inv = invoices[index];
                                  final isCancelled = inv.status == InvoiceStatus.cancelled;
                                  final initials = _getInitials(inv.customerName);
                                  final formattedTime = DateFormat('h:mm a').format(inv.invoiceDate);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        // Avatar Circle (Left)
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: index % 4 == 0 ? AppColors.brightCyan : AppColors.darkNavy,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: index % 4 == 0 ? AppColors.deepNavy : Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Middle Info (Invoice Number, Customer Name under it, Time)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                inv.invoiceNumber,
                                                style: AppTextStyles.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                                  color: AppColors.nearBlack,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                inv.customerName,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                formattedTime,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Amount & Payment Badge
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(inv.grandTotal),
                                              style: AppTextStyles.bodyLarge.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isCancelled ? Colors.grey : AppColors.nearBlack,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _buildPaymentBadge(inv.paymentType, isCancelled),
                                          ],
                                        ),
                                        const SizedBox(width: 4),

                                        // More Actions Button (Edit, View, Print, Delete)
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          onSelected: (action) {
                                            _handleInvoiceAction(context, action, inv);
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'view',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility_outlined, size: 18, color: AppColors.darkNavy),
                                                  SizedBox(width: 8),
                                                  Text('View Details'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.darkNavy),
                                                  SizedBox(width: 8),
                                                  Text('Edit Invoice'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'print',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.print_outlined, size: 18, color: AppColors.darkNavy),
                                                  SizedBox(width: 8),
                                                  Text('Print Receipt'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                                  SizedBox(width: 8),
                                                  Text('Delete / Cancel', style: TextStyle(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          double todaySales = 0.0;
          int todayBills = 0;

          if (state is SalesLoaded) {
            todaySales = state.todaySales;
            todayBills = state.todayBillsCount;
          }

          return Row(
            children: [
              // Today's sales Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's sales",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(todaySales),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Today's bills Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's bills",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$todayBills',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    final dateOptions = ['Today', '7 days', '30 days', 'Custom'];
    final paymentOptions = ['All', 'Cash', 'Credit'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Date Pill Chips (Today, 7 days, 30 days, Custom)
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dateOptions.length,
            itemBuilder: (context, index) {
              final dateOpt = dateOptions[index];
              final isSelected = _selectedDateFilter == dateOpt;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () async {
                    if (dateOpt == 'Custom') {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateFilter = 'Custom');
                        _applyFilters(dateRange: 'Custom');
                      }
                    } else {
                      setState(() => _selectedDateFilter = dateOpt);
                      _applyFilters(dateRange: dateOpt);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.darkNavy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.darkNavy : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.darkNavy.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      dateOpt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.nearBlack,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Row 2: Segmented Bar (All, Cash, Credit, Pending)
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBECEF),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            children: paymentOptions.map((opt) {
              final isSelected = _selectedPaymentFilter == opt;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPaymentFilter = opt);
                    _applyFilters(paymentFilter: opt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.nearBlack : const Color(0xFF5A6275),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(PaymentType type, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Cancelled',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
        ),
      );
    }

    Color bg;
    Color fg;
    String text = type.name.toUpperCase();

    switch (type) {
      case PaymentType.cash:
        bg = const Color(0xFFE0F7FA);
        fg = const Color(0xFF006064);
        text = 'Cash';
        break;
      case PaymentType.credit:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'Credit';
        break;
      case PaymentType.upi:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        text = 'UPI';
        break;
      case PaymentType.card:
        bg = const Color(0xFFF3E5F5);
        fg = const Color(0xFF7B1FA2);
        text = 'Card';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  String _getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'IN';
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _handleInvoiceAction(BuildContext context, String action, Invoice inv) {
    switch (action) {
      case 'view':
      case 'edit':
        context.push('/invoice/${inv.id}');
        break;
      case 'print':
        showDialog(
          context: context,
          builder: (ctx) => ReceiptPreviewDialog(
            invoice: inv,
            business: AppDatabase.instance.currentBusiness!,
          ),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete / Cancel Invoice?'),
            content: Text('Are you sure you want to cancel Invoice #${inv.invoiceNumber}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<SalesBloc>().add(CancelInvoiceEvent(inv.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice #${inv.invoiceNumber} cancelled'),
                      backgroundColor: AppColors.darkNavy,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete / Cancel'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _applyFilters({String? dateRange, String? paymentFilter, String? searchQuery}) {
    context.read<SalesBloc>().add(
          FilterSalesEvent(
            dateRange: dateRange ?? _selectedDateFilter,
            paymentFilter: paymentFilter ?? _selectedPaymentFilter,
            searchQuery: searchQuery ?? _searchController.text,
          ),
        );
  }
}
