import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../application/invoice/invoice_bloc.dart';
import '../../../application/inventory/inventory_bloc.dart';
import '../../../application/customers/customers_bloc.dart';
import '../../../application/sales/sales_bloc.dart';
import '../../../application/business/business_bloc.dart';
import '../../../domain/entities/business.dart';
import '../../../domain/entities/invoice.dart';
import '../../../infrastructure/database/app_database.dart';
import '../widgets/receipt_preview_dialog.dart';
import '../widgets/pos/invoice_app_bar.dart';
import '../widgets/pos/customer_selector.dart';
import '../widgets/pos/product_search_bar.dart';
import '../widgets/pos/category_selector.dart';
import '../widgets/pos/product_grid.dart';
import '../widgets/pos/collapsible_cart.dart';
import '../widgets/pos/invoice_action_buttons.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCategory = 'All';
  bool _shouldPrintAfterSave = false;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(ResetCartEvent());
    context.read<InventoryBloc>().add(LoadInventoryEvent());
    context.read<CustomersBloc>().add(LoadCustomersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
        final features = business?.features;
        final nextInvNum = business?.nextInvoiceNumber ?? AppDatabase.instance.currentBusiness?.nextInvoiceNumber ?? 1001;
        final prefix = business?.invoicePrefix ?? 'INV';
        final invNumber = '$prefix-$nextInvNum';
        final invoiceLabel = terminology?.invoice ?? 'Invoice';
        final itemLabel = terminology?.item ?? 'Product';

        return BlocListener<InvoiceBloc, InvoiceState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }

            if (state.savedInvoice != null) {
              context.read<SalesBloc>().add(LoadSalesEvent());
              context.read<InventoryBloc>().add(LoadInventoryEvent());
              context.read<CustomersBloc>().add(LoadCustomersEvent());
              context.read<BusinessBloc>().add(LoadBusinessEvent());

              final invoiceBloc = context.read<InvoiceBloc>();
              final navigator = Navigator.of(context);
              final savedInv = state.savedInvoice!;

              if (_shouldPrintAfterSave) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => ReceiptPreviewDialog(
                    invoice: savedInv,
                    business: AppDatabase.instance.currentBusiness!,
                  ),
                ).then((_) {
                  invoiceBloc.add(ResetCartEvent());
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$invoiceLabel #${savedInv.invoiceNumber} saved successfully!'),
                    backgroundColor: AppColors.darkNavy,
                    duration: const Duration(seconds: 1),
                  ),
                );
                invoiceBloc.add(ResetCartEvent());
                if (navigator.canPop()) {
                  navigator.pop();
                }
              }
            }
          },
          child: BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, invoiceState) {
              // Sync controllers with customer contact details
              final isReadOnly = invoiceState.isContactReadOnly;
              if (isReadOnly) {
                if (_nameController.text != invoiceState.effectiveCustomerName) {
                  _nameController.text = invoiceState.effectiveCustomerName;
                }
                if (_phoneController.text != invoiceState.effectiveCustomerPhone) {
                  _phoneController.text = invoiceState.effectiveCustomerPhone;
                }
              } else {
                if (_nameController.text != invoiceState.customCustomerName) {
                  _nameController.text = invoiceState.customCustomerName;
                }
                if (_phoneController.text != invoiceState.customCustomerPhone) {
                  _phoneController.text = invoiceState.customCustomerPhone;
                }
              }

              return Scaffold(
                backgroundColor: const Color(0xFFF9FAFB),
                // Pinned App Bar with Customer Name & Phone textfields
                appBar: InvoiceAppBar(
                  invoiceNumber: invNumber,
                  selectedCustomer: invoiceState.customer,
                  selectedPaymentType: invoiceState.paymentType,
                  isReadOnly: isReadOnly,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  onNameChanged: (val) {
                    context.read<InvoiceBloc>().add(
                          UpdateCustomerDetailsEvent(name: val),
                        );
                  },
                  onPhoneChanged: (val) {
                    context.read<InvoiceBloc>().add(
                          UpdateCustomerDetailsEvent(phone: val),
                        );
                  },
                  onTapCustomer: () {
                    CustomerSelector.showCustomerPicker(context, label: 'Select customer');
                  },
                  onSelectPayment: (type) {
                    context.read<InvoiceBloc>().add(SetPaymentTypeEvent(type));
                    if (type == PaymentType.credit) {
                      if (invoiceState.customer.id == 'cust_walk_in') {
                        CustomerSelector.showCustomerPicker(context, label: 'Select customer');
                      }
                    }
                  },
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // 1. FIXED Search & Barcode Scan Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ProductSearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: 'Search product...',
                          onChanged: (q) {
                            context.read<InventoryBloc>().add(SearchInventoryEvent(q));
                          },
                          onScanTap: (features?.barcodeEnabled ?? true)
                              ? () => _simulateBarcodeScan(context)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2. FIXED Horizontally Scrollable Category Chips
                      _buildCategorySelector(context),
                      const SizedBox(height: 10),

                      // 3. Scrollable Main Content (Cart & Product Grid)
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cart Card
                              CollapsibleCart(
                                items: invoiceState.items,
                                totalItemCount: invoiceState.totalItemCount,
                              ),
                              const SizedBox(height: 14),

                              // Product Cards Grid
                              _buildProductGridSection(context, itemLabel),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),

                      // 5. Bottom Financial Summary & Save Actions
                      InvoiceActionButtons(
                        subtotal: invoiceState.subtotal,
                        cgst: invoiceState.cgst,
                        sgst: invoiceState.sgst,
                        igst: invoiceState.igst,
                        totalTax: invoiceState.totalTax,
                        grandTotal: invoiceState.grandTotal,
                        isSaving: invoiceState.isSaving,
                        onSave: () {
                          setState(() => _shouldPrintAfterSave = false);
                          context.read<InvoiceBloc>().add(SaveInvoiceEvent());
                        },
                        onSaveAndPrint: () {
                          setState(() => _shouldPrintAfterSave = true);
                          context.read<InvoiceBloc>().add(SaveInvoiceEvent());
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _simulateBarcodeScan(BuildContext context) {
    final invState = context.read<InventoryBloc>().state;
    if (invState is InventoryLoaded && invState.products.isNotEmpty) {
      final sample = invState.products.firstWhere((p) => p.isProduct && p.currentStock > 0, orElse: () => invState.products.first);
      context.read<InvoiceBloc>().add(AddProductToCartEvent(sample));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned barcode: ${sample.name} added to cart!'),
          backgroundColor: AppColors.darkNavy,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildCategorySelector(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        Set<String> categoriesSet = {'All', 'Category 1', 'Category 2'};
        if (state is InventoryLoaded) {
          for (final item in state.products) {
            if (item.category.isNotEmpty) categoriesSet.add(item.category);
          }
        }
        final categories = categoriesSet.toList();

        return CategorySelector(
          categories: categories,
          selectedCategory: _selectedCategory,
          onSelectCategory: (cat) {
            setState(() => _selectedCategory = cat);
            context.read<InventoryBloc>().add(SearchInventoryEvent(cat == 'All' ? '' : cat));
          },
        );
      },
    );
  }

  Widget _buildProductGridSection(BuildContext context, String itemLabel) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final products = state.filteredProducts;
          return ProductGrid(
            products: products,
            itemLabel: itemLabel,
            onAddProduct: (product) {
              context.read<InvoiceBloc>().add(AddProductToCartEvent(product));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${product.name} to cart'),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        }
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
