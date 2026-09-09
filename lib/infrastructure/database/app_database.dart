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
import '../datasources/business_local_data_source.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  bool _initialized = false;
  bool isDemoMode = false;
  bool isLoggedIn = false;
  bool isBusinessConfigured = false;
  String? activeUserId;

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
    activeUserId = prefs.getString('active_user_id');

    if (isLoggedIn && activeUserId != null && activeUserId!.isNotEmpty) {
      await loadAccountData(activeUserId!);
    } else {
      clearMemoryState();
    }

    _initialized = true;
  }

  /// Sets active user account and loads user-scoped local data
  Future<void> setActiveUser(String userId) async {
    activeUserId = userId;
    isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_user_id', userId);
    await prefs.setBool('is_logged_in', true);

    await loadAccountData(userId);
  }

  /// Loads account-isolated local data for given userId
  Future<void> loadAccountData(String userId) async {
    activeUserId = userId;
    final prefs = await SharedPreferences.getInstance();

    final userBizKey = 'user_${userId}_business_json';
    final userItemsKey = 'user_${userId}_items_json';
    final userCustKey = 'user_${userId}_customers_json';
    final userInvKey = 'user_${userId}_invoices_json';
    final userExpKey = 'user_${userId}_expenses_json';
    final userConfiguredKey = 'user_${userId}_is_business_configured';

    // MIGRATION: If legacy global un-scoped keys exist and user key doesn't, migrate them to this user
    String? bizJson = prefs.getString(userBizKey);
    String? itemsStr = prefs.getString(userItemsKey);
    String? custStr = prefs.getString(userCustKey);
    String? invStr = prefs.getString(userInvKey);
    String? expStr = prefs.getString(userExpKey);

    if (bizJson == null && prefs.containsKey('business_json')) {
      bizJson = prefs.getString('business_json');
      itemsStr = prefs.getString('real_items_json');
      custStr = prefs.getString('real_customers_json');

      if (bizJson != null) await prefs.setString(userBizKey, bizJson);
      if (itemsStr != null) await prefs.setString(userItemsKey, itemsStr);
      if (custStr != null) await prefs.setString(userCustKey, custStr);
      await prefs.setBool(userConfiguredKey, true);

      // Clean up legacy global keys to prevent cross-user leakage
      await prefs.remove('business_json');
      await prefs.remove('real_items_json');
      await prefs.remove('real_customers_json');
      await prefs.remove('is_business_configured');
    }

    isBusinessConfigured = prefs.getBool(userConfiguredKey) ?? (bizJson != null);

    final invSettingsStr = prefs.getString('user_${userId}_invoice_settings_json') ?? prefs.getString('invoice_settings_json');
    if (invSettingsStr != null) {
      try {
        invoiceDisplaySettings = InvoiceDisplaySettings.fromJsonString(invSettingsStr);
      } catch (_) {}
    }

    if (bizJson != null) {
      try {
        final map = jsonDecode(bizJson);
        final bType = BusinessType.fromString(map['businessType']?.toString() ?? 'retail');
        final featuresMap = map['features'] as Map<String, dynamic>?;
        final features = featuresMap != null ? BusinessFeatures.fromJson(featuresMap) : bType.defaultFeatures;

        currentBusiness = Business(
          id: map['id'] ?? 'biz_$userId',
          accountId: userId,
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
        isBusinessConfigured = true;
      } catch (_) {
        currentBusiness = null;
      }
    } else {
      currentBusiness = null;
    }

    if (!isBusinessConfigured || currentBusiness == null) {
      try {
        final driftBiz = await BusinessLocalDataSourceImpl().getCurrentBusiness();
        if (driftBiz != null) {
          currentBusiness = driftBiz;
          isBusinessConfigured = true;
          await prefs.setBool(userConfiguredKey, true);
        }
      } catch (_) {}
    }

    // Load items
    if (itemsStr != null) {
      try {
        final List<dynamic> list = jsonDecode(itemsStr);
        items = list.map((itemMap) {
          final tStr = itemMap['type'] ?? 'product';
          final type = tStr == 'service' ? ItemType.service : (tStr == 'roomCharge' ? ItemType.roomCharge : ItemType.product);
          return Item(
            id: itemMap['id'],
            businessId: itemMap['businessId'] ?? currentBusiness?.id ?? 'biz_$userId',
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
      } catch (_) {
        items = [];
      }
    } else {
      items = [];
    }

    // Load customers
    if (custStr != null) {
      try {
        final List<dynamic> list = jsonDecode(custStr);
        customers = list.map((cMap) => Customer(
          id: cMap['id'],
          businessId: cMap['businessId'] ?? currentBusiness?.id ?? 'biz_$userId',
          name: cMap['name'],
          phone: cMap['phone'] ?? '',
          email: cMap['email'] ?? '',
          address: cMap['address'] ?? '',
          gstin: cMap['gstin'] ?? '',
          outstandingBalance: ((cMap['outstandingBalance'] ?? 0.0) as num).toDouble(),
          totalInvoices: cMap['totalInvoices'] ?? 0,
        )).toList();
      } catch (_) {
        customers = [];
      }
    } else {
      customers = [];
    }

    // Load invoices
    if (invStr != null) {
      try {
        final List<dynamic> list = jsonDecode(invStr);
        invoices = list.map((invMap) => Invoice(
          id: invMap['id'] ?? '',
          businessId: invMap['businessId'] ?? currentBusiness?.id ?? 'biz_$userId',
          invoiceNumber: invMap['invoiceNumber'] ?? '',
          invoiceDate: DateTime.tryParse(invMap['invoiceDate'] ?? '') ?? DateTime.now(),
          customerId: invMap['customerId'] ?? '',
          customerName: invMap['customerName'] ?? '',
          customerPhone: invMap['customerPhone'] ?? '',
          items: (invMap['items'] as List<dynamic>? ?? []).map((i) => InvoiceItem(
            id: i['id'] ?? '',
            productId: i['productId'] ?? '',
            productName: i['productName'] ?? '',
            quantity: i['quantity'] ?? 1,
            unitPrice: ((i['unitPrice'] ?? 0.0) as num).toDouble(),
            discountAmount: ((i['discountAmount'] ?? 0.0) as num).toDouble(),
            gstRate: ((i['gstRate'] ?? 0.0) as num).toDouble(),
            taxAmount: ((i['taxAmount'] ?? 0.0) as num).toDouble(),
            totalAmount: ((i['totalAmount'] ?? 0.0) as num).toDouble(),
          )).toList(),
          subtotal: ((invMap['subtotal'] ?? 0.0) as num).toDouble(),
          discount: ((invMap['discount'] ?? 0.0) as num).toDouble(),
          cgst: ((invMap['cgst'] ?? 0.0) as num).toDouble(),
          sgst: ((invMap['sgst'] ?? 0.0) as num).toDouble(),
          igst: ((invMap['igst'] ?? 0.0) as num).toDouble(),
          grandTotal: ((invMap['grandTotal'] ?? 0.0) as num).toDouble(),
          paymentType: PaymentType.values.firstWhere((p) => p.name == invMap['paymentType'], orElse: () => PaymentType.cash),
          paidAmount: ((invMap['paidAmount'] ?? 0.0) as num).toDouble(),
          dueAmount: ((invMap['dueAmount'] ?? 0.0) as num).toDouble(),
          status: InvoiceStatus.values.firstWhere((s) => s.name == invMap['status'], orElse: () => InvoiceStatus.paid),
        )).toList();
      } catch (_) {
        invoices = [];
      }
    } else {
      invoices = [];
    }

    // Load expenses
    if (expStr != null) {
      try {
        final List<dynamic> list = jsonDecode(expStr);
        expenses = list.map((eMap) => Expense(
          id: eMap['id'] ?? '',
          businessId: eMap['businessId'] ?? currentBusiness?.id ?? 'biz_$userId',
          category: eMap['category'] ?? 'General',
          title: eMap['title'] ?? '',
          description: eMap['description'] ?? '',
          amount: ((eMap['amount'] ?? 0.0) as num).toDouble(),
          date: DateTime.tryParse(eMap['date'] ?? '') ?? DateTime.now(),
          paymentMethod: eMap['paymentMethod'] ?? 'Cash',
          reference: eMap['reference'] ?? '',
          customerId: eMap['customerId'],
          customerName: eMap['customerName'],
        )).toList();
      } catch (_) {
        expenses = [];
      }
    } else {
      expenses = [];
    }
  }

  void loadDemoData() {
    isDemoMode = true;
    isLoggedIn = true;
    isBusinessConfigured = true;
    currentBusiness = Business(
      id: 'biz_demo',
      name: 'Demo Store & Services',
      businessType: BusinessType.retail,
      phone: '9876543210',
      address: '123 Demo Street',
      gstEnabled: true,
      gstin: '27AABCU9603R1ZM',
      invoicePrefix: 'INV',
      nextInvoiceNumber: 1001,
      features: BusinessType.retail.defaultFeatures,
    );
    items = [
      Item(
        id: 'item_demo_1',
        businessId: 'biz_demo',
        name: 'Demo Product',
        type: ItemType.product,
        sellingPrice: 100.0,
        purchasePrice: 60.0,
        currentStock: 50,
      ),
    ];
    customers = [];
    invoices = [];
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

  /// Saves active user's local state isolated to activeUserId
  Future<void> saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);

    if (activeUserId != null && activeUserId!.isNotEmpty) {
      final userId = activeUserId!;
      await prefs.setString('active_user_id', userId);
      await prefs.setBool('user_${userId}_is_business_configured', isBusinessConfigured);
      await prefs.setString('user_${userId}_invoice_settings_json', invoiceDisplaySettings.toJsonString());

      if (currentBusiness != null) {
        await prefs.setString('user_${userId}_business_json', jsonEncode({
          'id': currentBusiness!.id,
          'accountId': userId,
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

        await prefs.setString('user_${userId}_items_json', jsonEncode(items.map((i) => {
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

        await prefs.setString('user_${userId}_customers_json', jsonEncode(customers.map((c) => {
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

        await prefs.setString('user_${userId}_invoices_json', jsonEncode(invoices.map((inv) => {
          'id': inv.id,
          'businessId': inv.businessId,
          'invoiceNumber': inv.invoiceNumber,
          'invoiceDate': inv.invoiceDate.toIso8601String(),
          'customerId': inv.customerId,
          'customerName': inv.customerName,
          'customerPhone': inv.customerPhone,
          'items': inv.items.map((i) => {
            'id': i.id,
            'productId': i.productId,
            'productName': i.productName,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'discountAmount': i.discountAmount,
            'gstRate': i.gstRate,
            'taxAmount': i.taxAmount,
            'totalAmount': i.totalAmount,
          }).toList(),
          'subtotal': inv.subtotal,
          'discount': inv.discount,
          'cgst': inv.cgst,
          'sgst': inv.sgst,
          'igst': inv.igst,
          'grandTotal': inv.grandTotal,
          'paymentType': inv.paymentType.name,
          'paidAmount': inv.paidAmount,
          'dueAmount': inv.dueAmount,
          'status': inv.status.name,
        }).toList()));

        await prefs.setString('user_${userId}_expenses_json', jsonEncode(expenses.map((e) => {
          'id': e.id,
          'businessId': e.businessId,
          'category': e.category,
          'title': e.title,
          'description': e.description,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
          'paymentMethod': e.paymentMethod,
          'reference': e.reference,
          'customerId': e.customerId,
          'customerName': e.customerName,
        }).toList()));
      }
    }
  }

  /// Clears active session state on logout (data remains safely isolated on disk)
  Future<void> clearActiveSessionOnLogout() async {
    isLoggedIn = false;
    isBusinessConfigured = false;
    isDemoMode = false;
    activeUserId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('active_user_id');

    clearMemoryState();
  }

  /// Clears all in-memory domain data
  void clearMemoryState() {
    currentBusiness = null;
    items = [];
    customers = [];
    customerPayments = [];
    invoices = [];
    expenses = [];
    smartInsights = [];
    isBusinessConfigured = false;
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
