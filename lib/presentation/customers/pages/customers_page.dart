import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../application/customers/customers_bloc.dart';
import '../../../application/business/business_bloc.dart';
import '../../../domain/entities/business.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/business_configuration.dart';
import '../../../domain/entities/business_type.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(LoadCustomersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, bizState) {
        Business? business;
        if (bizState is BusinessLoaded) {
          business = bizState.business;
        }

        final config = business?.configuration ??
            BusinessConfiguration.fromType(
                business?.type ?? BusinessType.retail);
        final terminology = config.terminology;

        final customerLabel = terminology.customer;
        final customersLabel = terminology.customers;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go(RouteConstants.settings);
                }
              },
            ),
            title: Text(
              customersLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111418),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () =>
                        context.push(RouteConstants.addEditCustomer),
                    icon: const Icon(Icons.add,
                        size: 18, color: Color(0xFF111418)),
                    label: Text(
                      'Add $customerLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Customer Summary Banner
                _buildCustomerStats(context, customersLabel),

                // Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: AppSearchField(
                    controller: _searchController,
                    hint:
                        'Search ${customerLabel.toLowerCase()} name or phone...',
                    onChanged: (q) {
                      context
                          .read<CustomersBloc>()
                          .add(SearchCustomersEvent(q));
                    },
                  ),
                ),

                // Customer List
                Expanded(
                  child: BlocBuilder<CustomersBloc, CustomersState>(
                    builder: (context, state) {
                      if (state is CustomersLoaded) {
                        final customers = state.filteredCustomers;

                        if (customers.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64,
                                      color: AppColors.brightCyan
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.searchQuery.isNotEmpty
                                        ? 'No ${customersLabel.toLowerCase()} found'
                                        : 'No $customersLabel Yet',
                                    style: AppTextStyles.h3,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$customersLabel you add will appear here.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 100),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return _buildCustomerTile(context, customer);
                          },
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

  Widget _buildCustomerStats(BuildContext context, String customersLabel) {
    return BlocBuilder<CustomersBloc, CustomersState>(
      builder: (context, state) {
        int total = 0;
        double outstanding = 0.0;

        if (state is CustomersLoaded) {
          total = state.customers.length;
          outstanding = state.totalOutstanding;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Total $customersLabel',
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('$total',
                      style: const TextStyle(
                          color: Color(0xFF111418),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.grey.shade300),
              Column(
                children: [
                  const Text('Total Credit Outstanding',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(outstanding),
                    style: TextStyle(
                      color: outstanding > 0
                          ? AppColors.error
                          : AppColors.deepNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    final hasDue = customer.outstandingBalance > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () =>
            context.push(RouteConstants.customerProfile, extra: customer),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  hasDue ? Colors.amber.shade100 : AppColors.darkNavy,
              child: Icon(
                Icons.person,
                color: hasDue ? Colors.amber.shade900 : Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text(customer.phone.isEmpty ? "Walk-in" : customer.phone,
                      style: AppTextStyles.bodySmall),
                  Text('${customer.totalInvoices} Invoices',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDue) ...[
                      Text(
                        CurrencyFormatter.format(customer.outstandingBalance),
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('CREDIT DUE',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      const Text('₹0 Due',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF64748B), size: 20),
                  onPressed: () => _showCustomerOptionsModal(context, customer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerOptionsModal(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final hasDue = customer.outstandingBalance > 0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Grab Bar
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Header Preview
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: hasDue
                          ? Colors.amber.shade100
                          : const Color(0xFFF1F5F9),
                      child: Icon(
                        Icons.person,
                        color: hasDue
                            ? Colors.amber.shade900
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: AppTextStyles.h3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.phone.isEmpty
                                ? "No phone"
                                : customer.phone,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${customer.totalInvoices} Invoices',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasDue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CurrencyFormatter.format(customer.outstandingBalance),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // Option 1: View Details & Ledger
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.visibility_outlined,
                        color: Color(0xFF00ACC1), size: 22),
                  ),
                  title: const Text(
                    'View Details & Record Payment',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A)),
                  ),
                  subtitle: const Text(
                      'View credit balance, contact info & ledger',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(RouteConstants.customerProfile,
                        extra: customer);
                  },
                ),

                // Option 2: Edit Customer
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF334155), size: 22),
                  ),
                  title: const Text(
                    'Edit Customer Profile',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A)),
                  ),
                  subtitle: const Text('Update phone, email, address & GSTIN',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(RouteConstants.addEditCustomer,
                        extra: customer);
                  },
                ),

                // Option 3: Delete Customer
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Color(0xFFE53935), size: 22),
                  ),
                  title: const Text(
                    'Delete Customer',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFE53935)),
                  ),
                  subtitle: const Text('Remove party record from business',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteCustomer(context, customer);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer'),
        content: Text(
            'Are you sure you want to delete "${customer.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context
                  .read<CustomersBloc>()
                  .add(DeleteCustomerEvent(customer.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${customer.name} deleted')),
              );
            },
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
