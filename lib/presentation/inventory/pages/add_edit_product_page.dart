import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../application/inventory/inventory_bloc.dart';
import '../../../application/business/business_bloc.dart';
import '../../../domain/entities/item.dart';

class AddEditProductPage extends StatefulWidget {
  final Item? initialItem;

  const AddEditProductPage({
    super.key,
    this.initialItem,
  });

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late ItemType _selectedType;
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late String _selectedCategory;
  late String _selectedUnit;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late int _selectedGstRate;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;
  String? _categoryError;
  String? _unitError;

  bool get isEditing => widget.initialItem != null;

  final List<String> _categoryOptions = [
    'Choose category',
    'Groceries',
    'Dairy',
    'Snacks',
    'Beverages',
    'Bakery',
    'Electronics',
    'Clothing',
    'Services',
    'General',
  ];

  final List<String> _unitOptions = [
    'Choose unit',
    'Pcs',
    'Kg',
    'Ltr',
    'Bag',
    'Box',
    'Pack',
    'Mtr',
    'Hours',
    'Mins',
    'Job',
  ];

  final List<int> _gstOptions = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _selectedType = item?.type ?? ItemType.product;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _barcodeController = TextEditingController(text: item?.barcode ?? '');

    final initialCat = item?.category ?? 'Choose category';
    _selectedCategory = _categoryOptions.contains(initialCat) ? initialCat : 'Choose category';

    final initialUnit = item?.unit ?? 'Choose unit';
    _selectedUnit = _unitOptions.contains(initialUnit) ? initialUnit : 'Choose unit';

    _purchasePriceController = TextEditingController(
      text: (item != null && item.purchasePrice > 0) ? item.purchasePrice.toStringAsFixed(0) : '',
    );
    _sellingPriceController = TextEditingController(
      text: (item != null && item.sellingPrice > 0) ? item.sellingPrice.toStringAsFixed(0) : '',
    );

    final intGst = item?.gstRate.toInt() ?? 5;
    _selectedGstRate = _gstOptions.contains(intGst) ? intGst : 5;

    _stockController = TextEditingController(
      text: item != null ? item.currentStock.toString() : '20',
    );
    _lowStockController = TextEditingController(
      text: item != null ? item.lowStockLimit.toString() : '5',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final item = widget.initialItem;
    if (item == null) {
      return _nameController.text.trim().isNotEmpty ||
          _skuController.text.trim().isNotEmpty ||
          _barcodeController.text.trim().isNotEmpty ||
          _selectedCategory != 'Choose category' ||
          _selectedUnit != 'Choose unit' ||
          _purchasePriceController.text.trim().isNotEmpty ||
          _sellingPriceController.text.trim().isNotEmpty;
    }
    return _nameController.text.trim() != item.name ||
        _skuController.text.trim() != item.sku ||
        _barcodeController.text.trim() != item.barcode ||
        _selectedCategory != item.category ||
        _selectedUnit != item.unit ||
        _purchasePriceController.text.trim() != (item.purchasePrice > 0 ? item.purchasePrice.toStringAsFixed(0) : '') ||
        _sellingPriceController.text.trim() != (item.sellingPrice > 0 ? item.sellingPrice.toStringAsFixed(0) : '');
  }

  Future<bool> _handlePop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onBackTapped() async {
    if (await _handlePop()) {
      if (mounted) context.pop();
    }
  }

  void _saveItem() {
    setState(() {
      _categoryError = (_selectedCategory == 'Choose category') ? 'Please select a category' : null;
      _unitError = (_selectedUnit == 'Choose unit') ? 'Please select a unit' : null;
    });

    if (_formKey.currentState!.validate() && _categoryError == null && _unitError == null) {
      final businessState = context.read<BusinessBloc>().state;
      String bizId = 'biz_1';
      if (businessState is BusinessLoaded) {
        bizId = businessState.business.id;
      }

      final newItem = Item(
        id: widget.initialItem?.id ?? const Uuid().v4(),
        businessId: bizId,
        type: _selectedType,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        category: _selectedCategory,
        unit: _selectedUnit,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        mrp: 0.0,
        gstRate: _selectedGstRate.toDouble(),
        currentStock: _selectedType == ItemType.product ? (int.tryParse(_stockController.text) ?? 0) : 0,
        lowStockLimit: _selectedType == ItemType.product ? (int.tryParse(_lowStockController.text) ?? 5) : 0,
      );

      if (isEditing) {
        context.read<InventoryBloc>().add(UpdateProductEvent(newItem));
      } else {
        context.read<InventoryBloc>().add(AddProductEvent(newItem));
      }

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? '${newItem.name} updated successfully!'
                : '${newItem.name} added successfully!',
          ),
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${widget.initialItem?.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.initialItem != null) {
                context.read<InventoryBloc>().add(DeleteProductEvent(widget.initialItem!.id));
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.initialItem!.name} deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessBloc>().state;
    final bool showGst = businessState is BusinessLoaded ? businessState.business.gstEnabled : true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBackTapped();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: _onBackTapped,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF111418), size: 20),
              ),
            ),
          ),
          title: Text(
            isEditing
                ? (_selectedType == ItemType.product ? 'Edit product' : 'Edit service')
                : (_selectedType == ItemType.product ? 'Add product' : 'Add service'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111418),
            ),
          ),
          actions: [
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Photo Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                _selectedType == ItemType.product ? Icons.folder_outlined : Icons.build_outlined,
                                size: 42,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.brightCyan,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: AppColors.deepNavy, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Change photo',
                          style: TextStyle(
                            color: Color(0xFF5A6275),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION 1: Basic Information
                  const Text(
                    'Basic information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                  ),
                  const SizedBox(height: 12),

                  _buildRoundedInputField(
                    label: _selectedType == ItemType.product ? 'Product name' : 'Service name',
                    hint: 'e.g. Basmati Rice 5kg',
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  if (_selectedType == ItemType.product) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoundedInputField(
                            label: 'SKU',
                            hint: 'RICE005',
                            controller: _skuController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoundedInputField(
                            label: 'Barcode',
                            hint: '8901030826404',
                            controller: _barcodeController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRoundedDropdownField<String>(
                          label: 'Category',
                          value: _selectedCategory,
                          items: _categoryOptions,
                          errorText: _categoryError,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedCategory = v;
                                _categoryError = (v == 'Choose category') ? 'Please select a category' : null;
                              });
                            }
                          },
                          itemLabelBuilder: (c) => c,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoundedDropdownField<String>(
                          label: 'Unit',
                          value: _selectedUnit,
                          items: _unitOptions,
                          errorText: _unitError,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedUnit = v;
                                _unitError = (v == 'Choose unit') ? 'Please select a unit' : null;
                              });
                            }
                          },
                          itemLabelBuilder: (u) => u,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SECTION 2: Pricing
                  const Text(
                    'Pricing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRoundedInputField(
                          label: 'Purchase price',
                          hint: '280',
                          prefixText: '₹',
                          keyboardType: TextInputType.number,
                          controller: _purchasePriceController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoundedInputField(
                          label: 'Selling price',
                          hint: '320',
                          prefixText: '₹',
                          keyboardType: TextInputType.number,
                          controller: _sellingPriceController,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SECTION 3: Tax (Conditional on GST Enabled)
                  if (showGst) ...[
                    const Text(
                      'Tax',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                    ),
                    const SizedBox(height: 12),

                    _buildRoundedDropdownField<int>(
                      label: 'GST rate',
                      value: _selectedGstRate,
                      items: _gstOptions,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGstRate = v);
                      },
                      itemLabelBuilder: (rate) => '$rate%',
                    ),
                    const SizedBox(height: 24),
                  ],

                  // SECTION 4: Inventory (If Product)
                  if (_selectedType == ItemType.product) ...[
                    const Text(
                      'Inventory',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRoundedInputField(
                            label: 'Current stock',
                            hint: '24',
                            keyboardType: TextInputType.number,
                            controller: _stockController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoundedInputField(
                            label: 'Low stock alert',
                            hint: '10',
                            keyboardType: TextInputType.number,
                            controller: _lowStockController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _onBackTapped,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brightCyan,
                        foregroundColor: AppColors.deepNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        _selectedType == ItemType.product ? 'Save product' : 'Save service',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator != null ? (_) => validator(controller.text) : null,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A6275),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                onChanged: (val) {
                  state.didChange(val);
                },
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111418),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixText: prefixText,
                  prefixStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoundedDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabelBuilder,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5A6275)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF111418)),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111418)),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabelBuilder(item)),
                );
              }).toList(),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}

