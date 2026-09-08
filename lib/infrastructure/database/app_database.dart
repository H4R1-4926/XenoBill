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

    isDemoMode = false;
    isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    isBusinessConfigured = prefs.getBool('is_business_configured') ?? false;

    final invSettingsStr = prefs.getString('invoice_settings_json');
    if (invSettingsStr != null) {
      try {
        invoiceDisplaySettings = InvoiceDisplaySettings.fromJsonString(invSettingsStr);
      } catch (_) {}
    }

    if (isBusinessConfigured) {
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
    isDemoMode = false;
    isLoggedIn = true;
    isBusinessConfigured = true;
    currentBusiness = null;
    items = [];
    customers = [];
    invoices = [];
    customerPayments = [];
    expenses = [];
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

