import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/business_type.dart';
import '../../domain/entities/business_features.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/smart_insight.dart';

import '../../domain/entities/invoice_display_settings.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  bool _initialized = false;
  bool isDemoMode = false;
  bool isLoggedIn = false;
  bool isBusinessConfigured = false;

  Business? currentBusiness;
  InvoiceDisplaySettings invoiceDisplaySettings = const InvoiceDisplaySettings();
  List<Item> items = [];
  List<Customer> customers = [];
  List<CustomerPayment> customerPayments = [];
  List<Invoice> invoices = [];
  List<Expense> expenses = [];
  List<SmartInsight> smartInsights = [];

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    // Reset demo mode on cold start so the application presents the Auth screen
    isDemoMode = false;
    isLoggedIn = false;
    isBusinessConfigured = prefs.getBool('is_business_configured') ?? false;



    final invSettingsStr = prefs.getString('invoice_settings_json');
    if (invSettingsStr != null) {
      try {
        invoiceDisplaySettings = InvoiceDisplaySettings.fromJsonString(invSettingsStr);
      } catch (_) {}
    }

    if (isDemoMode) {
      loadDemoData();
    } else if (isBusinessConfigured) {
      await _loadLocalData(prefs);
    } else {
      currentBusiness = null;
      items = [];
      customers = [];
      customerPayments = [];
      invoices = [];
      expenses = [];
      smartInsights = [];
    }

    _initialized = true;
  }

  void loadDemoData() {
    isDemoMode = true;
    isLoggedIn = true;
    isBusinessConfigured = true;
    currentBusiness = Business(
      id: 'biz_demo_1',
      name: 'Demo Store & Services',
      businessType: BusinessType.retail,
      phone: '9876543210',
      email: 'demo@xenobiz.com',
      address: 'Demo Market, Station Road',
      gstEnabled: true,
      gstin: '27AABCU9603R1ZM',
      currency: '₹',
      invoicePrefix: 'INV',
      nextInvoiceNumber: 1027,
      features: BusinessType.retail.defaultFeatures,
    );
    items = [
      const Item(
        id: 'p1',
        businessId: 'biz_demo_1',
        type: ItemType.product,
        name: 'Basmati Rice 5kg',
        sku: 'RICE005',
        barcode: '8901030826404',
        category: 'Groceries',
        unit: 'Bag',
        sellingPrice: 320.0,
        purchasePrice: 280.0,
        mrp: 340.0,
        gstRate: 5.0,
        currentStock: 24,
        lowStockLimit: 10,
      ),
      const Item(
        id: 'p2',
        businessId: 'biz_demo_1',
        type: ItemType.product,
        name: 'Fortune Sunflower Oil 1L',
        sku: 'OIL001',
        barcode: '8901234567890',
        category: 'Groceries',
        unit: 'Bottle',
        sellingPrice: 165.0,
        purchasePrice: 140.0,
        mrp: 180.0,
        gstRate: 5.0,
        currentStock: 15,
        lowStockLimit: 5,
      ),
      const Item(
        id: 's1',
        businessId: 'biz_demo_1',
        type: ItemType.service,
        name: 'Home Delivery Service',
        sku: 'SERV01',
        category: 'Services',
        unit: 'Service',
        sellingPrice: 50.0,
        purchasePrice: 0.0,
        gstRate: 18.0,
        durationMinutes: 30,
      ),
    ];
    customers = [
      const Customer(
        id: 'c1',
        businessId: 'biz_demo_1',
        name: 'Hari',
        phone: '+91 40259294662',
        email: 'hari@example.com',
        address: 'Flat 102, Lake View Apartments',
        gstin: '',
        outstandingBalance: 2500.0,
        totalInvoices: 12,
      ),
    ];
    invoices = [
      Invoice(
        id: 'inv_1026',
        businessId: 'biz_demo_1',
        invoiceNumber: 'INV-1026',
        invoiceDate: DateTime.now().subtract(const Duration(hours: 2)),
        customerId: 'c1',
        customerName: 'Hari',
        customerPhone: '+91 40259294662',
        items: const [
          InvoiceItem(
            id: 'item_1',
            productId: 'p1',
            productName: 'Basmati Rice 5kg',
            quantity: 3,
            unitPrice: 320.0,
            discountAmount: 0.0,
            gstRate: 5.0,
            taxAmount: 48.0,
            totalAmount: 1008.0,
          ),
          InvoiceItem(
            id: 'item_2',
            productId: 's1',
            productName: 'Home Delivery Service',
            quantity: 1,
            unitPrice: 50.0,
            discountAmount: 0.0,
            gstRate: 18.0,
            taxAmount: 9.0,
            totalAmount: 59.0,
          ),
        ],
        subtotal: 1010.0,
        discount: 0.0,
        cgst: 28.5,
        sgst: 28.5,
        igst: 0.0,
        grandTotal: 1134.0,
        paymentType: PaymentType.credit,
        paidAmount: 500.0,
        dueAmount: 634.0,
        status: InvoiceStatus.partial,
      ),
      Invoice(
        id: 'inv_1021',
        businessId: 'biz_demo_1',
        invoiceNumber: 'INV-1021',
        invoiceDate: DateTime.now().subtract(const Duration(days: 4)),
        customerId: 'c1',
        customerName: 'Hari',
        customerPhone: '+91 40259294662',
        items: const [
          InvoiceItem(
            id: 'item_3',
            productId: 'p2',
            productName: 'Fortune Sunflower Oil 1L',
            quantity: 5,
            unitPrice: 165.0,
            discountAmount: 25.0,
            gstRate: 5.0,
            taxAmount: 40.0,
            totalAmount: 840.0,
          ),
        ],
        subtotal: 800.0,
        discount: 0.0,
        cgst: 25.0,
        sgst: 25.0,
        igst: 0.0,
        grandTotal: 850.0,
        paymentType: PaymentType.credit,
        paidAmount: 850.0,
        dueAmount: 0.0,
        status: InvoiceStatus.paid,
      ),
      Invoice(
        id: 'inv_1010',
        businessId: 'biz_demo_1',
        invoiceNumber: 'INV-1010',
        invoiceDate: DateTime(2026, 1, 12, 10, 0),
        customerId: 'c1',
        customerName: 'Hari',
        customerPhone: '+91 40259294662',
        items: const [
          InvoiceItem(
            id: 'item_4',
            productId: 'p1',
            productName: 'Basmati Rice 5kg',
            quantity: 20,
            unitPrice: 320.0,
            discountAmount: 0.0,
            gstRate: 5.0,
            taxAmount: 320.0,
            totalAmount: 6516.0,
          ),
        ],
        subtotal: 6200.0,
        discount: 0.0,
        cgst: 158.0,
        sgst: 158.0,
        igst: 0.0,
        grandTotal: 6516.0,
        paymentType: PaymentType.credit,
        paidAmount: 4650.0,
        dueAmount: 1866.0,
        status: InvoiceStatus.partial,
      ),
    ];
    customerPayments = [
      CustomerPayment(
        id: 'pay_1',
        customerId: 'c1',
        customerName: 'Hari',
        amount: 500.0,
        paymentMethod: 'Cash',
        paymentDate: DateTime.now().subtract(const Duration(days: 2)),
        referenceNote: 'Cash received on partial bill',
        allocatedInvoiceId: 'inv_1026',
      ),
      CustomerPayment(
        id: 'pay_2',
        customerId: 'c1',
        customerName: 'Hari',
        amount: 850.0,
        paymentMethod: 'UPI',
        paymentDate: DateTime.now().subtract(const Duration(days: 7)),
        referenceNote: 'UPI12345',
        allocatedInvoiceId: 'inv_1021',
      ),
      CustomerPayment(
        id: 'pay_3',
        customerId: 'c1',
        customerName: 'Hari',
        amount: 4650.0,
        paymentMethod: 'Bank Transfer',
        paymentDate: DateTime(2026, 8, 15, 14, 0),
        referenceNote: 'NEFT transfer',
        allocatedInvoiceId: 'inv_1010',
      ),
    ];
    final now = DateTime.now();
    expenses = [
      Expense(
        id: 'exp_1',
        businessId: 'biz_demo_1',
        category: 'Utilities',
        title: 'Electricity bill',
        description: 'Monthly commercial electricity bill',
        amount: 1200.0,
        date: DateTime(now.year, now.month, now.day, 11, 20),
        paymentMethod: 'Cash',
      ),
      Expense(
        id: 'exp_2',
        businessId: 'biz_demo_1',
        category: 'Transport',
        title: 'Auto fare — supplier pickup',
        description: 'Transport for stock',
        amount: 250.0,
        date: DateTime(now.year, now.month, now.day, 10, 5),
        paymentMethod: 'Cash',
      ),
      Expense(
        id: 'exp_3',
        businessId: 'biz_demo_1',
        category: 'Supplies',
        title: 'Packing covers — 2 boxes',
        description: 'Packaging materials',
        amount: 400.0,
        date: DateTime(now.year, now.month, now.day, 9, 40),
        paymentMethod: 'UPI',
      ),
      Expense(
        id: 'exp_4',
        businessId: 'biz_demo_1',
        category: 'Rent',
        title: 'Shop Rent',
        description: 'Monthly store building rent',
        amount: 15000.0,
        date: DateTime(now.year, now.month, 1, 10, 0),
        paymentMethod: 'Bank Transfer',
      ),
      Expense(
        id: 'exp_5',
        businessId: 'biz_demo_1',
        category: 'Salaries',
        title: 'Staff Salaries',
        description: 'Helper salaries',
        amount: 12000.0,
        date: DateTime(now.year, now.month, 2, 17, 30),
        paymentMethod: 'Bank Transfer',
      ),
      Expense(
        id: 'exp_6',
        businessId: 'biz_demo_1',
        category: 'Utilities',
        title: 'Internet & WiFi Bill',
        description: 'Fiber broadband',
        amount: 3400.0,
        date: DateTime(now.year, now.month, 3, 14, 15),
        paymentMethod: 'UPI',
      ),
      Expense(
        id: 'exp_7',
        businessId: 'biz_demo_1',
        category: 'Supplies',
        title: 'Thermal Paper Rolls',
        description: '80mm receipt paper',
        amount: 3540.0,
        date: DateTime(now.year, now.month, 4, 16, 0),
        paymentMethod: 'UPI',
      ),
      Expense(
        id: 'exp_8',
        businessId: 'biz_demo_1',
        category: 'Other',
        title: 'Miscellaneous Repairs',
        description: 'Store maintenance',
        amount: 2700.0,
        date: DateTime(now.year, now.month, 4, 18, 0),
        paymentMethod: 'Cash',
      ),
    ];
    smartInsights = [];
  }

  Future<void> createNewBusiness(Business business) async {
    isDemoMode = false;
    isBusinessConfigured = true;
    isLoggedIn = true;
    currentBusiness = business;
    items = [];
    customers = [];
    invoices = [];
    expenses = [];
    smartInsights = [];

    await saveLocalState();
  }

  Future<void> saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', isDemoMode);
    await prefs.setBool('is_logged_in', isLoggedIn);
    await prefs.setBool('is_business_configured', isBusinessConfigured);
    await prefs.setString('invoice_settings_json', invoiceDisplaySettings.toJsonString());

    if (!isDemoMode && currentBusiness != null) {
      await prefs.setString('business_json', jsonEncode({
        'id': currentBusiness!.id,
        'name': currentBusiness!.name,
        'businessType': currentBusiness!.type.name,
        'phone': currentBusiness!.phone,
        'address': currentBusiness!.address,
        'gstEnabled': currentBusiness!.gstEnabled,
        'gstin': currentBusiness!.gstin,
        'invoicePrefix': currentBusiness!.invoicePrefix,
        'nextInvoiceNumber': currentBusiness!.nextInvoiceNumber,
        'features': currentBusiness!.features.toJson(),
      }));

      // Store items, customers, invoices, expenses for real business
      await prefs.setString('real_items_json', jsonEncode(items.map((i) => {
        'id': i.id,
        'businessId': i.businessId,
        'type': i.type.name,
        'name': i.name,
        'description': i.description,
        'sku': i.sku,
        'barcode': i.barcode,
        'category': i.category,
        'unit': i.unit,
        'sellingPrice': i.sellingPrice,
        'purchasePrice': i.purchasePrice,
        'mrp': i.mrp,
        'gstRate': i.gstRate,
        'isTaxable': i.isTaxable,
        'currentStock': i.currentStock,
        'lowStockLimit': i.lowStockLimit,
        'durationMinutes': i.durationMinutes,
        'isActive': i.isActive,
      }).toList()));

      await prefs.setString('real_customers_json', jsonEncode(customers.map((c) => {
        'id': c.id,
        'businessId': c.businessId,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
        'gstin': c.gstin,
        'outstandingBalance': c.outstandingBalance,
        'totalInvoices': c.totalInvoices,
      }).toList()));
    }
  }

  Future<void> _loadLocalData(SharedPreferences prefs) async {
    final bizJson = prefs.getString('business_json');
    if (bizJson != null) {
      final map = jsonDecode(bizJson);
      final bType = BusinessType.fromString(map['businessType']?.toString() ?? 'retail');
      final featuresMap = map['features'] as Map<String, dynamic>?;
      final features = featuresMap != null ? BusinessFeatures.fromJson(featuresMap) : bType.defaultFeatures;

      currentBusiness = Business(
        id: map['id'] ?? 'biz_real_1',
        name: map['name'] ?? 'My Business',
        businessType: bType,
        phone: map['phone'] ?? '',
        address: map['address'] ?? '',
        gstEnabled: map['gstEnabled'] ?? true,
        gstin: map['gstin'] ?? '',
        invoicePrefix: map['invoicePrefix'] ?? 'INV',
        nextInvoiceNumber: map['nextInvoiceNumber'] ?? 1001,
        features: features,
      );

      // Load items
      final itemsStr = prefs.getString('real_items_json');
      if (itemsStr != null) {
        final List<dynamic> list = jsonDecode(itemsStr);
        items = list.map((itemMap) {
          final tStr = itemMap['type'] ?? 'product';
          final type = tStr == 'service' ? ItemType.service : (tStr == 'roomCharge' ? ItemType.roomCharge : ItemType.product);
          return Item(
            id: itemMap['id'],
            businessId: itemMap['businessId'] ?? currentBusiness!.id,
            type: type,
            name: itemMap['name'],
            description: itemMap['description'] ?? '',
            sku: itemMap['sku'] ?? '',
            barcode: itemMap['barcode'] ?? '',
            category: itemMap['category'] ?? 'General',
            unit: itemMap['unit'] ?? 'Unit',
            sellingPrice: (itemMap['sellingPrice'] as num).toDouble(),
            purchasePrice: ((itemMap['purchasePrice'] ?? 0.0) as num).toDouble(),
            mrp: ((itemMap['mrp'] ?? 0.0) as num).toDouble(),
            gstRate: ((itemMap['gstRate'] ?? 5.0) as num).toDouble(),
            isTaxable: itemMap['isTaxable'] ?? true,
            currentStock: itemMap['currentStock'] ?? 0,
            lowStockLimit: itemMap['lowStockLimit'] ?? 5,
            durationMinutes: itemMap['durationMinutes'] ?? 0,
            isActive: itemMap['isActive'] ?? true,
          );
        }).toList();
      } else {
        items = [];
      }

      // Load customers
      final custStr = prefs.getString('real_customers_json');
      if (custStr != null) {
        final List<dynamic> list = jsonDecode(custStr);
        customers = list.map((cMap) => Customer(
          id: cMap['id'],
          businessId: cMap['businessId'] ?? currentBusiness!.id,
          name: cMap['name'],
          phone: cMap['phone'] ?? '',
          email: cMap['email'] ?? '',
          address: cMap['address'] ?? '',
          gstin: cMap['gstin'] ?? '',
          outstandingBalance: ((cMap['outstandingBalance'] ?? 0.0) as num).toDouble(),
          totalInvoices: cMap['totalInvoices'] ?? 0,
        )).toList();
      } else {
        customers = [];
      }

      invoices = [];
      expenses = [];
      smartInsights = [];
    } else {
      currentBusiness = null;
      items = [];
      customers = [];
      invoices = [];
      expenses = [];
      smartInsights = [];
    }
  }

  String exportBackupJson() {
    final map = {
      'business': currentBusiness == null ? null : {
        'id': currentBusiness!.id,
        'name': currentBusiness!.name,
        'businessType': currentBusiness!.type.name,
        'phone': currentBusiness!.phone,
        'address': currentBusiness!.address,
        'gstEnabled': currentBusiness!.gstEnabled,
        'gstin': currentBusiness!.gstin,
        'invoicePrefix': currentBusiness!.invoicePrefix,
        'nextInvoiceNumber': currentBusiness!.nextInvoiceNumber,
        'features': currentBusiness!.features.toJson(),
      },
      'invoiceDisplaySettings': invoiceDisplaySettings.toJsonString(),
      'items': items.map((i) => {
        'id': i.id,
        'businessId': i.businessId,
        'type': i.type.name,
        'name': i.name,
        'description': i.description,
        'sku': i.sku,
        'barcode': i.barcode,
        'category': i.category,
        'unit': i.unit,
        'sellingPrice': i.sellingPrice,
        'purchasePrice': i.purchasePrice,
        'mrp': i.mrp,
        'gstRate': i.gstRate,
        'isTaxable': i.isTaxable,
        'currentStock': i.currentStock,
        'lowStockLimit': i.lowStockLimit,
        'durationMinutes': i.durationMinutes,
        'isActive': i.isActive,
      }).toList(),
      'customers': customers.map((c) => {
        'id': c.id,
        'businessId': c.businessId,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
        'gstin': c.gstin,
        'outstandingBalance': c.outstandingBalance,
        'totalInvoices': c.totalInvoices,
      }).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(map);
  }

  List<int> exportBinDatabase() {
    final jsonStr = exportBackupJson();
    return utf8.encode(jsonStr);
  }

  Future<bool> importBinDatabase(List<int> bytes) async {
    try {
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map.containsKey('business') && map['business'] != null) {
        final bizMap = map['business'] as Map<String, dynamic>;
        final bType = BusinessType.fromString(bizMap['businessType']?.toString() ?? 'retail');
        final featuresMap = bizMap['features'] as Map<String, dynamic>?;
        final features = featuresMap != null ? BusinessFeatures.fromJson(featuresMap) : bType.defaultFeatures;

        currentBusiness = Business(
          id: bizMap['id'] ?? 'biz_real_1',
          name: bizMap['name'] ?? 'My Business',
          businessType: bType,
          phone: bizMap['phone'] ?? '',
          address: bizMap['address'] ?? '',
          gstEnabled: bizMap['gstEnabled'] ?? true,
          gstin: bizMap['gstin'] ?? '',
          invoicePrefix: bizMap['invoicePrefix'] ?? 'INV',
          nextInvoiceNumber: bizMap['nextInvoiceNumber'] ?? 1001,
          features: features,
        );
        isBusinessConfigured = true;
        isLoggedIn = true;
      }

      if (map.containsKey('invoiceDisplaySettings') && map['invoiceDisplaySettings'] != null) {
        try {
          invoiceDisplaySettings = InvoiceDisplaySettings.fromJsonString(map['invoiceDisplaySettings']);
        } catch (_) {}
      }

      if (map.containsKey('items') && map['items'] is List) {
        final List<dynamic> list = map['items'];
        items = list.map((itemMap) {
          final tStr = itemMap['type'] ?? 'product';
          final type = tStr == 'service' ? ItemType.service : (tStr == 'roomCharge' ? ItemType.roomCharge : ItemType.product);
          return Item(
            id: itemMap['id'],
            businessId: itemMap['businessId'] ?? currentBusiness?.id ?? 'biz_real_1',
            type: type,
            name: itemMap['name'],
            description: itemMap['description'] ?? '',
            sku: itemMap['sku'] ?? '',
            barcode: itemMap['barcode'] ?? '',
            category: itemMap['category'] ?? 'General',
            unit: itemMap['unit'] ?? 'Unit',
            sellingPrice: ((itemMap['sellingPrice'] ?? 0.0) as num).toDouble(),
            purchasePrice: ((itemMap['purchasePrice'] ?? 0.0) as num).toDouble(),
            mrp: ((itemMap['mrp'] ?? 0.0) as num).toDouble(),
            gstRate: ((itemMap['gstRate'] ?? 5.0) as num).toDouble(),
            isTaxable: itemMap['isTaxable'] ?? true,
            currentStock: itemMap['currentStock'] ?? 0,
            lowStockLimit: itemMap['lowStockLimit'] ?? 5,
            durationMinutes: itemMap['durationMinutes'] ?? 0,
            isActive: itemMap['isActive'] ?? true,
          );
        }).toList();
      }

      if (map.containsKey('customers') && map['customers'] is List) {
        final List<dynamic> list = map['customers'];
        customers = list.map((cMap) => Customer(
          id: cMap['id'],
          businessId: cMap['businessId'] ?? currentBusiness?.id ?? 'biz_real_1',
          name: cMap['name'],
          phone: cMap['phone'] ?? '',
          email: cMap['email'] ?? '',
          address: cMap['address'] ?? '',
          gstin: cMap['gstin'] ?? '',
          outstandingBalance: ((cMap['outstandingBalance'] ?? 0.0) as num).toDouble(),
          totalInvoices: cMap['totalInvoices'] ?? 0,
        )).toList();
      }

      await saveLocalState();
      return true;
    } catch (e) {
      return false;
    }
  }
}

