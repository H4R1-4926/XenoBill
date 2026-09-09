import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/business.dart';
import '../../../domain/entities/business_type.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../application/business/business_bloc.dart';

class GstSettingsPage extends StatefulWidget {
  const GstSettingsPage({super.key});

  @override
  State<GstSettingsPage> createState() => _GstSettingsPageState();
}

class _GstSettingsPageState extends State<GstSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _gstEnabled;
  late TextEditingController _gstinController;
  String _registrationType = 'Regular';
  String _defaultTaxRate = '5%';

  final List<String> _registrationTypes = [
    'Regular',
    'Composition Scheme',
    'Unregistered / Exempt',
    'SEZ / Overseas Export',
  ];

  final List<String> _gstRates = [
    '0% (Exempt)',
    '5%',
    '12%',
    '18%',
    '28%',
  ];

  @override
  void initState() {
    super.initState();
    final biz = AppDatabase.instance.currentBusiness;
    _gstEnabled = biz?.gstEnabled ?? true;
    _gstinController = TextEditingController(text: biz?.gstin ?? '');
  }

  @override
  void dispose() {
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'GST Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tax & GST Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage GST registration, GSTIN, and default tax application rules',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // GST Enablement Switch Card
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'GST Registered Business',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.darkNavy),
                      ),
                      subtitle: const Text('Enable GST tax calculation on sales invoices'),
                      value: _gstEnabled,
                      activeThumbColor: AppColors.brightCyan,
                      onChanged: (val) => setState(() => _gstEnabled = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_gstEnabled) ...[
                  // Registration Type
                  const Text(
                    'GST Registration Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _registrationType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkNavy),
                        items: _registrationTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type, style: const TextStyle(fontSize: 14, color: AppColors.darkNavy)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _registrationType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GSTIN Input
                  AppTextField(
                    label: 'GSTIN (GST Number)',
                    hint: 'e.g. 27AABCU9603R1ZM',
                    controller: _gstinController,
                  ),
                  const SizedBox(height: 16),

                  // Default GST Rate
                  const Text(
                    'Default Invoice GST Rate',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _defaultTaxRate,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkNavy),
                        items: _gstRates.map((rate) {
                          return DropdownMenuItem<String>(
                            value: rate,
                            child: Text(rate, style: const TextStyle(fontSize: 14, color: AppColors.darkNavy)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _defaultTaxRate = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

              const SizedBox(height: 40),
            ],
          ),
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
              onPressed: () {
                final current = AppDatabase.instance.currentBusiness;
                final gstin = _gstEnabled ? _gstinController.text.trim() : '';

                final updated = (current != null)
                    ? current.copyWith(
                        gstEnabled: _gstEnabled,
                        gstin: gstin,
                      )
                    : Business(
                        id: 'biz_real_1',
                        name: 'My Business',
                        businessType: BusinessType.retail,
                        phone: '',
                        address: '',
                        gstEnabled: _gstEnabled,
                        gstin: gstin,
                        invoicePrefix: 'INV',
                        nextInvoiceNumber: 1001,
                      );

                AppDatabase.instance.currentBusiness = updated;
                context.read<BusinessBloc>().add(UpdateBusinessEvent(updated));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GST Settings saved successfully!')),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brightCyan,
                foregroundColor: AppColors.darkNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'Save GST Settings',
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
}
