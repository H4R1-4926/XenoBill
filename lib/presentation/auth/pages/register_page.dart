import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/business.dart';
import '../../../domain/entities/business_type.dart';
import '../../../application/auth/auth_bloc.dart';
import '../../../application/auth/auth_event.dart';
import '../../../application/auth/auth_state.dart';
import '../../../application/business/business_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../infrastructure/database/app_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0; // 0: Business Type, 1: Create Account, 2: Business Details, 3: App Config

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Step 1 Selection: Business Type
  BusinessType _selectedType = BusinessType.retail;

  // Step 2 Controllers: Account Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 3 Controllers: Business Details
  final _bizNameController = TextEditingController();
  final _bizPhoneController = TextEditingController();
  final _bizAddressController = TextEditingController();
  final _gstinController = TextEditingController();
  bool _gstEnabled = true;

  // Step 4 Controllers: App Config
  final _prefixController = TextEditingController(text: 'INV');
  final _startNumController = TextEditingController(text: '1001');
  String _selectedCurrency = '₹';
  String _paperSize = '3 inch (80mm)';

  final List<BusinessType> _availableTypes = [
    BusinessType.retail,
    BusinessType.wholesale,
    BusinessType.restaurant,
    BusinessType.cafe,
    BusinessType.hotel,
    BusinessType.salon,
    BusinessType.service,
    BusinessType.mixed,
    BusinessType.other,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bizNameController.dispose();
    _bizPhoneController.dispose();
    _bizAddressController.dispose();
    _gstinController.dispose();
    _prefixController.dispose();
    _startNumController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_step1Key.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_step3Key.currentState!.validate()) return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _completeRegistration() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    // 1. Create Business Domain Object
    final bizName = _bizNameController.text.trim().isEmpty
        ? '${name.isEmpty ? "My" : name}\'s Shop'
        : _bizNameController.text.trim();

    final features = _selectedType.defaultFeatures.copyWith(
      gstEnabled: _gstEnabled,
    );

    final newBiz = Business(
      id: const Uuid().v4(),
      name: bizName,
      businessType: _selectedType,
      phone: _bizPhoneController.text.trim().isEmpty ? _phoneController.text.trim() : _bizPhoneController.text.trim(),
      address: _bizAddressController.text.trim(),
      email: email,
      gstEnabled: _gstEnabled,
      gstin: _gstEnabled ? _gstinController.text.trim() : '',
      currency: _selectedCurrency,
      invoicePrefix: _prefixController.text.trim().isEmpty ? 'INV' : _prefixController.text.trim().toUpperCase(),
      nextInvoiceNumber: int.tryParse(_startNumController.text) ?? 1001,
      features: features,
    );

    // 2. Dispatch Business Bloc Update & AppDatabase
    AppDatabase.instance.isBusinessConfigured = true;
    AppDatabase.instance.isLoggedIn = true;
    AppDatabase.instance.currentBusiness = newBiz;
    AppDatabase.instance.saveLocalState();
    context.read<BusinessBloc>().add(UpdateBusinessEvent(newBiz));

    // 3. Dispatch Supabase Auth Registration
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: email.contains('@') ? email : '$email@xenobiz.internal',
            password: password,
            name: name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkNavy),
          onPressed: _previousStep,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Register Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of 4: ${_getStepTitle()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.brightCyan,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brightCyan),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthenticationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 5),
                ),
              );
            } else if (state is Authenticated) {
              AppDatabase.instance.isLoggedIn = true;
              AppDatabase.instance.saveLocalState();
              context.go(RouteConstants.home);
            } else if (state is EmailVerificationRequired) {
              AppDatabase.instance.isLoggedIn = true;
              AppDatabase.instance.saveLocalState();
              context.go(RouteConstants.home);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Column(
              children: [
                // STEP PROGRESS CHIPS
                _buildStepHeaderProgress(),

                // STEP CONTENT AREA
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildCurrentStepContent(),
                  ),
                ),

                // FIXED BOTTOM NAVIGATION BAR
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          text: isLoading
                              ? 'Saving & Launching...'
                              : (_currentStep == 3 ? 'Complete & Start POS 🎉' : 'Next Step →'),
                          width: double.infinity,
                          onPressed: isLoading ? null : _nextStep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Business Type';
      case 1:
        return 'Create Account';
      case 2:
        return 'Business Details';
      case 3:
        return 'App Config';
      default:
        return '';
    }
  }

  Widget _buildStepHeaderProgress() {
    final steps = ['Type', 'Account', 'Details', 'Config'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.brightCyan.withValues(alpha: 0.15)
                          : (isDone ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.brightCyan
                            : (isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDone)
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981))
                        else
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.brightCyan : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? AppColors.deepNavy : Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? AppColors.deepNavy
                                  : (isDone ? const Color(0xFF065F46) : const Color(0xFF64748B)),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep2BusinessTypeSelection();
      case 1:
        return _buildStep1AccountForm();
      case 2:
        return _buildStep3BusinessDetailsForm();
      case 3:
        return _buildStep4AppConfigForm();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1 (INDEX 0): BUSINESS TYPE SELECTION
  Widget _buildStep2BusinessTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Type', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select your business category first to customize your POS workspace',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableTypes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final type = _availableTypes[index];
            final isSelected = _selectedType == type;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brightCyan.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.brightCyan : AppColors.border,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brightCyan : AppColors.lightGray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type.icon,
                        color: isSelected ? AppColors.deepNavy : AppColors.darkNavy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.deepNavy : AppColors.nearBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? AppColors.deepNavy.withValues(alpha: 0.8) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.brightCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.deepNavy,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 2 (INDEX 1): CREATE ACCOUNT FORM
  Widget _buildStep1AccountForm() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Account', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your details to register your Xenobiz owner account',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Full Name',
            hint: 'e.g. Ramesh Kumar',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Mobile Number',
            hint: 'e.g. 9876543210',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_outlined,
            controller: _phoneController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Email Address',
            hint: 'e.g. user@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email address is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Password',
            hint: '••••••••',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            controller: _passwordController,
            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirm Password',
            hint: '••••••••',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            controller: _confirmPasswordController,
            validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
          ),
        ],
      ),
    );
  }

  // STEP 3 (INDEX 2): BUSINESS DETAILS FORM
  Widget _buildStep3BusinessDetailsForm() {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Details', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Configure your shop profile for invoices and customer receipts',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brightCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brightCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.darkNavy, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected Category: ${_selectedType.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkNavy, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppTextField(
            label: 'Business / Shop Name',
            hint: 'e.g. Apex Retail, Spark Salon',
            prefixIcon: Icons.business_outlined,
            controller: _bizNameController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            label: 'Shop Contact Phone',
            hint: 'e.g. 9876543210',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            controller: _bizPhoneController,
          ),
          const SizedBox(height: AppSpacing.md),

          AppTextField(
            label: 'Shop Address',
            hint: 'e.g. Shop 12, Main Market Road',
            prefixIcon: Icons.location_on_outlined,
            controller: _bizAddressController,
          ),
          const SizedBox(height: AppSpacing.lg),

          // GST Registration Switch Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text('GST Registered Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Enable GST tax calculation & GSTIN printing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              value: _gstEnabled,
              activeThumbColor: AppColors.brightCyan,
              onChanged: (val) => setState(() => _gstEnabled = val),
            ),
          ),

          if (_gstEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'GSTIN (GST Number)',
              hint: 'e.g. 27AABCU9603R1ZM',
              prefixIcon: Icons.receipt_long_outlined,
              controller: _gstinController,
            ),
          ],
        ],
      ),
    );
  }

  // STEP 4 (INDEX 3): APP CONFIGURATION & PREFERENCES
  Widget _buildStep4AppConfigForm() {
    final currencies = ['₹', '\$', '€', '£', '¥', 'AED'];
    final paperSizes = ['2 inch (58mm)', '3 inch (80mm)', 'A4 / Letter Sheet'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Configuration', style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Customize invoice prefixes, starting sequence and thermal printing',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Currency Selector
        const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.darkNavy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: currencies.map((curr) {
            final isSelected = _selectedCurrency == curr;
            return ChoiceChip(
              label: Text(curr, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.deepNavy : AppColors.darkNavy)),
              selected: isSelected,
              selectedColor: AppColors.brightCyan,
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? AppColors.brightCyan : const Color(0xFFCBD5E1)),
              onSelected: (val) {
                if (val) setState(() => _selectedCurrency = curr);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Invoice Numbering Row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Invoice Prefix',
                hint: 'INV',
                prefixIcon: Icons.pin_outlined,
                controller: _prefixController,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Starting Inv #',
                hint: '1001',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.onetwothree_outlined,
                controller: _startNumController,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Thermal Printer Paper Format
        const Text('Receipt Printing Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.darkNavy)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: paperSizes.map((size) {
              return RadioListTile<String>(
                title: Text(size, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                value: size,
                groupValue: _paperSize,
                activeColor: AppColors.brightCyan,
                onChanged: (val) {
                  if (val != null) setState(() => _paperSize = val);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Registration Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                  SizedBox(width: 8),
                  Text('Ready to Launch Shop!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildSummaryRow('Category', _selectedType.displayName),
              _buildSummaryRow('Owner', _nameController.text.isEmpty ? 'Shop Owner' : _nameController.text),
              _buildSummaryRow('Email', _emailController.text),
              _buildSummaryRow('Business Name', _bizNameController.text.isEmpty ? 'My Shop' : _bizNameController.text),
              _buildSummaryRow('Invoice Format', '${_prefixController.text.toUpperCase()}-${_startNumController.text}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        ],
      ),
    );
  }
}
