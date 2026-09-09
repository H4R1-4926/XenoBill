import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/invoice_display_settings.dart';
import '../../../infrastructure/database/app_database.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/invoice_preview_dialog.dart';
import '../widgets/invoice_settings_modals.dart';

class InvoiceSettingsPage extends StatefulWidget {
  const InvoiceSettingsPage({super.key});

  @override
  State<InvoiceSettingsPage> createState() => _InvoiceSettingsPageState();
}

class _InvoiceSettingsPageState extends State<InvoiceSettingsPage> {
  late InvoiceDisplaySettings _settings;
  late TextEditingController _footerMessageController;
  late TextEditingController _termsController;
  late TextEditingController _footerNoteController;

  @override
  void initState() {
    super.initState();
    _settings = AppDatabase.instance.invoiceDisplaySettings;
    _footerMessageController =
        TextEditingController(text: _settings.footerMessage);
    _termsController =
        TextEditingController(text: _settings.termsAndConditions);
    _footerNoteController =
        TextEditingController(text: _settings.customFooterNote);
  }

  @override
  void dispose() {
    _footerMessageController.dispose();
    _termsController.dispose();
    _footerNoteController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final updated = _settings.copyWith(
      footerMessage: _footerMessageController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      customFooterNote: _footerNoteController.text.trim(),
    );
    AppDatabase.instance.invoiceDisplaySettings = updated;
    AppDatabase.instance.saveLocalState();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice Settings saved successfully!')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final biz = AppDatabase.instance.currentBusiness;
    final isGstConfigured = biz?.gstEnabled ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkNavy),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Invoice Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1 — BUSINESS INFORMATION
              const SettingsSection(
                title: 'Business Information',
                subtitle:
                    'Choose what business information appears on your invoices.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Business Logo',
                    description: 'Display business logo on invoices',
                    value: _settings.showBusinessLogo,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showBusinessLogo: v)),
                  ),
                  _buildToggleTile(
                    title: 'Business Name',
                    description: 'Display business name on invoice header',
                    value: _settings.showBusinessName,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showBusinessName: v)),
                  ),
                  _buildToggleTile(
                    title: 'Business Address',
                    description: 'Display business address on invoice',
                    value: _settings.showBusinessAddress,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showBusinessAddress: v)),
                  ),
                  _buildToggleTile(
                    title: 'Phone Number',
                    description: 'Display business contact number',
                    value: _settings.showPhone,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showPhone: v)),
                  ),
                  _buildToggleTile(
                    title: 'Email Address',
                    description: 'Display business email address',
                    value: _settings.showEmail,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showEmail: v)),
                  ),
                  if (isGstConfigured)
                    _buildToggleTile(
                      title: 'GSTIN / Tax Registration',
                      description: 'Display GSTIN or tax registration number',
                      value: _settings.showGstin,
                      onChanged: (v) => setState(
                          () => _settings = _settings.copyWith(showGstin: v)),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2 — INVOICE DETAILS
              const SettingsSection(
                title: 'Invoice Details',
                subtitle: 'Choose the information displayed on every invoice.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Invoice Number',
                    description: 'Show unique invoice reference number',
                    value: _settings.showInvoiceNumber,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showInvoiceNumber: v)),
                  ),
                  _buildToggleTile(
                    title: 'Invoice Date',
                    description: 'Show invoice creation date',
                    value: _settings.showInvoiceDate,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showInvoiceDate: v)),
                  ),
                  _buildToggleTile(
                    title: 'Invoice Time',
                    description: 'Show time of invoice creation',
                    value: _settings.showInvoiceTime,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showInvoiceTime: v)),
                  ),
                  _buildToggleTile(
                    title: 'Customer Details',
                    description: 'Show customer name and contact information',
                    value: _settings.showCustomerDetails,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showCustomerDetails: v)),
                  ),
                  _buildToggleTile(
                    title: 'Previous Customer Balance',
                    description: "Show customer's previous outstanding balance",
                    value: _settings.showPreviousCustomerBalance,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(showPreviousCustomerBalance: v)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3 — ITEMS & LINE PRICING
              const SettingsSection(
                title: 'Items & Line Pricing',
                subtitle: 'Configure line item layout and pricing details.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Quantity',
                    description: 'Display product quantity alongside item name',
                    value: _settings.showQuantity,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showQuantity: v)),
                  ),
                  _buildToggleTile(
                    title: 'Unit Price',
                    description: 'Display per-unit price breakdown',
                    value: _settings.showUnitPrice,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showUnitPrice: v)),
                  ),
                  _buildToggleTile(
                    title: 'Discount',
                    description: 'Show discount line when applicable',
                    value: _settings.showDiscount,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showDiscount: v)),
                  ),
                  if (isGstConfigured)
                    _buildToggleTile(
                      title: 'Tax Row & Rate',
                      description: 'Show tax breakdown and GST rate',
                      value: _settings.showTaxRowAndRate,
                      onChanged: (v) => setState(() =>
                          _settings = _settings.copyWith(showTaxRowAndRate: v)),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 4 — PAYMENT & TOTALS
              const SettingsSection(
                title: 'Payment & Totals',
                subtitle: 'Configure payment details and invoice totals.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Payment Method',
                    description:
                        'Display payment method such as Cash, UPI, Card, Credit',
                    value: _settings.showPaymentMethod,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showPaymentMethod: v)),
                  ),
                  _buildToggleTile(
                    title: 'Amount Paid',
                    description: 'Show the amount received from the customer',
                    value: _settings.showAmountPaid,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showAmountPaid: v)),
                  ),
                  _buildToggleTile(
                    title: 'Balance Due',
                    description:
                        'Show remaining unpaid or partially paid balance',
                    value: _settings.showBalanceDue,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showBalanceDue: v)),
                  ),
                  _buildToggleTile(
                    title: 'Subtotal',
                    description:
                        'Show subtotal before tax, discount and expenses',
                    value: _settings.showSubtotal,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showSubtotal: v)),
                  ),
                  if (isGstConfigured)
                    _buildToggleTile(
                      title: 'Tax Total',
                      description: 'Show total GST/tax amount',
                      value: _settings.showTaxTotal,
                      onChanged: (v) => setState(() =>
                          _settings = _settings.copyWith(showTaxTotal: v)),
                    ),
                  _buildToggleTile(
                    title: 'Discount Total',
                    description: 'Show total discount applied to the invoice',
                    value: _settings.showDiscountTotal,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showDiscountTotal: v)),
                  ),
                  _buildToggleTile(
                    title: 'Additional Expenses',
                    description:
                        'Show additional expenses added to the invoice',
                    value: _settings.showAdditionalExpenses,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(showAdditionalExpenses: v)),
                  ),
                  _buildToggleTile(
                    title: 'Grand Total',
                    description: 'Show final payable invoice amount (Required)',
                    value: true,
                    enabled: false,
                    onChanged: null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 5 — ADDITIONAL EXPENSES
              const SettingsSection(
                title: 'Additional Expenses',
                subtitle:
                    'Configure how extra charges/expenses appear on invoices.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Show Expense Details',
                    description:
                        'Display additional expense names on the invoice',
                    value: _settings.showExpenseDetails,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showExpenseDetails: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show Expense Amount',
                    description: 'Display individual expense amounts',
                    value: _settings.showExpenseAmount,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showExpenseAmount: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show Expense Total',
                    description: 'Display total additional expenses',
                    value: _settings.showExpenseTotal,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showExpenseTotal: v)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 6 — FOOTER
              const SettingsSection(
                title: 'Footer',
                subtitle:
                    'Customize the information displayed at the bottom of your invoice.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Show Footer Message',
                    description:
                        'Display a custom message at the bottom of the invoice',
                    value: _settings.showFooterMessage,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showFooterMessage: v)),
                  ),
                  if (_settings.showFooterMessage)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 14),
                      child: AppTextField(
                        label: 'Footer Message',
                        hint: 'e.g. Thank you for your business!',
                        controller: _footerMessageController,
                      ),
                    ),
                  _buildToggleTile(
                    title: 'Terms & Conditions',
                    description: 'Display terms and conditions on the invoice',
                    value: _settings.showTermsAndConditions,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(showTermsAndConditions: v)),
                  ),
                  if (_settings.showTermsAndConditions)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 14),
                      child: AppTextField(
                        label: 'Default Terms & Conditions',
                        hint: 'e.g. Goods once sold cannot be returned.',
                        maxLines: 2,
                        controller: _termsController,
                      ),
                    ),
                  _buildToggleTile(
                    title: 'Authorized Signature',
                    description: 'Show authorized signature area on invoice',
                    value: _settings.showAuthorizedSignature,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(showAuthorizedSignature: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show "Thank You" Message',
                    description:
                        'Display a short thank-you message below the invoice totals',
                    value: _settings.showThankYouMessage,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showThankYouMessage: v)),
                  ),
                  _buildToggleTile(
                    title: 'Custom Footer Note',
                    description:
                        'Add an additional note at the bottom of the invoice',
                    value: _settings.showCustomFooterNote,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(showCustomFooterNote: v)),
                  ),
                  if (_settings.showCustomFooterNote)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 14),
                      child: AppTextField(
                        label: 'Footer Note',
                        hint: 'e.g. Visit our website for more deals',
                        maxLines: 2,
                        controller: _footerNoteController,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 7 — INVOICE DISPLAY
              const SettingsSection(
                title: 'Invoice Display',
                subtitle: 'Configure visual elements and item display.',
              ),
              SettingsGroupCard(
                children: [
                  _buildToggleTile(
                    title: 'Show Item Images',
                    description: 'Display product images on invoices',
                    value: _settings.showItemImages,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showItemImages: v)),
                  ),
                  _buildToggleTile(
                    title: 'Compact Item Layout',
                    description:
                        'Use a compact layout to fit more items on one page',
                    value: _settings.compactItemLayout,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(compactItemLayout: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show SKU',
                    description: 'Display product SKU/code beside item name',
                    value: _settings.showSku,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showSku: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show HSN/SAC',
                    description: 'Display HSN/SAC code for applicable items',
                    value: _settings.showHsnSac,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showHsnSac: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show Barcode',
                    description: 'Display product barcode on invoice',
                    value: _settings.showBarcode,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(showBarcode: v)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 8 — PRINTING
              const SettingsSection(
                title: 'Printing',
                subtitle: 'Configure how invoices are printed or shared.',
              ),
              SettingsGroupCard(
                children: [
                  // Paper Size Row
                  InkWell(
                    onTap: () {
                      PrintingFormatsModal.show(
                        context,
                        currentSize: _settings.paperSize,
                        onSelected: (val) => setState(() =>
                            _settings = _settings.copyWith(paperSize: val)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Paper Size',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkNavy)),
                                const SizedBox(height: 2),
                                Text(_settings.paperSize,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _settings.paperSize,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkNavy),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.darkNavy, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Invoice Format Row
                  InkWell(
                    onTap: () {
                      InvoiceFormatModal.show(
                        context,
                        currentFormat: _settings.invoiceFormat,
                        onSelected: (val) => setState(() =>
                            _settings = _settings.copyWith(invoiceFormat: val)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Invoice Format',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkNavy)),
                                const SizedBox(height: 2),
                                Text(_settings.invoiceFormat,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _settings.invoiceFormat,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkNavy),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.darkNavy, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Interactive Preview Invoice Row
                  InkWell(
                    onTap: () => InvoicePreviewDialog.show(context, _settings),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: const [
                          Icon(Icons.remove_red_eye_outlined,
                              color: AppColors.darkNavy, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Preview Invoice',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.darkNavy, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  _buildToggleTile(
                    title: 'Auto Print After Saving',
                    description:
                        'Automatically open printing after saving an invoice',
                    value: _settings.autoPrintAfterSaving,
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(autoPrintAfterSaving: v)),
                  ),
                  _buildToggleTile(
                    title: 'Show Print Button',
                    description: 'Show print option after invoice creation',
                    value: _settings.showPrintButton,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(showPrintButton: v)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brightCyan,
                foregroundColor: AppColors.darkNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String description,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.darkNavy : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled
                        ? const Color(0xFF64748B)
                        : Colors.grey.shade400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.brightCyan,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
