import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../application/customers/customers_bloc.dart';
import '../../../../application/invoice/invoice_bloc.dart';

class CustomerSelector extends StatelessWidget {
  final Customer selectedCustomer;
  final String label;

  const CustomerSelector({
    super.key,
    required this.selectedCustomer,
    this.label = 'Select customer',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCustomerPicker(context, label: label),
      child: Text(
        selectedCustomer.name,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  static void showCustomerPicker(BuildContext context, {String label = 'Select customer'}) {
    final invoiceBloc = context.read<InvoiceBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<CustomersBloc>(),
        child: const _CustomerPickerModal(),
      ),
    ).then((selected) {
      if (selected is Customer) {
        invoiceBloc.add(SetCustomerEvent(selected));
      }
    });
  }
}

class _CustomerPickerModal extends StatefulWidget {
  const _CustomerPickerModal();

  @override
  State<_CustomerPickerModal> createState() => _CustomerPickerModalState();
}

class _CustomerPickerModalState extends State<_CustomerPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title 'Select customer' & '+' button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select customer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack,
                ),
              ),
              IconButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await context.push(RouteConstants.addEditCustomer);
                  if (result is Customer && context.mounted) {
                    context.read<InvoiceBloc>().add(SetCustomerEvent(result));
                  }
                },
                icon: const Icon(Icons.add, size: 28, color: AppColors.nearBlack),
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar Input ('search')
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              style: const TextStyle(fontSize: 14, color: AppColors.nearBlack),
              decoration: const InputDecoration(
                hintText: 'search',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Customer List
          Expanded(
            child: BlocBuilder<CustomersBloc, CustomersState>(
              builder: (context, state) {
                if (state is CustomersLoaded) {
                  var list = state.customers;
                  if (_searchQuery.isNotEmpty) {
                    list = list
                        .where((c) =>
                            c.name.toLowerCase().contains(_searchQuery) ||
                            c.phone.contains(_searchQuery))
                        .toList();
                  }

                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, index) {
                      final cust = list[index];
                      final bool isDue = cust.outstandingBalance > 0;

                      return InkWell(
                        onTap: () => Navigator.pop(context, cust),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cust.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.nearBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ph: ${cust.phone}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDue ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isDue
                                      ? 'due: ${CurrencyFormatter.format(cust.outstandingBalance)}'
                                      : 'no due',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDue ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
