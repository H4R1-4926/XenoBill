import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/repositories.dart';
import '../../infrastructure/database/app_database.dart';

class TopProductData extends Equatable {
  final String name;
  final int quantitySold;
  final double totalAmount;

  const TopProductData({
    required this.name,
    required this.quantitySold,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [name, quantitySold, totalAmount];
}

class TopCustomerData extends Equatable {
  final String initials;
  final String name;
  final int invoiceCount;
  final double totalAmount;

  const TopCustomerData({
    required this.initials,
    required this.name,
    required this.invoiceCount,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [initials, name, invoiceCount, totalAmount];
}

class TaxRateSummaryData extends Equatable {
  final double rate;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double totalTax;

  const TaxRateSummaryData({
    required this.rate,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
  });

  @override
  List<Object?> get props => [rate, taxableAmount, cgst, sgst, totalTax];
}

class HsnSummaryData extends Equatable {
  final String hsnCode;
  final String description;
  final int quantity;
  final double totalTax;

  const HsnSummaryData({
    required this.hsnCode,
    required this.description,
    required this.quantity,
    required this.totalTax,
  });

  @override
  List<Object?> get props => [hsnCode, description, quantity, totalTax];
}

class GstInvoiceData extends Equatable {
  final String invoiceNumber;
  final String customerName;
  final double taxableAmount;
  final double taxAmount;

  const GstInvoiceData({
    required this.invoiceNumber,
    required this.customerName,
    required this.taxableAmount,
    required this.taxAmount,
  });

  @override
  List<Object?> get props => [invoiceNumber, customerName, taxableAmount, taxAmount];
}

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReportsEvent extends ReportsEvent {
  final String dateRange; // 'Today', 'Yesterday', '7 Days', '30 Days', 'This Month'
  const LoadReportsEvent({this.dateRange = 'Today'});
  @override
  List<Object?> get props => [dateRange];
}

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}
class ReportsLoading extends ReportsState {}
class ReportsLoaded extends ReportsState {
  final String selectedDateRange;
  final double grossSales;
  final double totalDiscount;
  final double totalTax;
  final double netSales;
  final double cashTotal;
  final double creditTotal;
  final double upiTotal;
  final double cardTotal;
  final int totalInvoices;
  final double taxableSales;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;

  final List<TopProductData> topProducts;
  final List<TopCustomerData> topCustomers;
  final List<TaxRateSummaryData> taxRateSummaries;
  final List<HsnSummaryData> hsnSummaries;
  final int b2bInvoices;
  final double b2bTaxable;
  final double b2bTax;
  final int b2cInvoices;
  final double b2cTaxable;
  final double b2cTax;
  final List<GstInvoiceData> gstInvoices;
  final List<double> trendPoints;

  const ReportsLoaded({
    required this.selectedDateRange,
    required this.grossSales,
    required this.totalDiscount,
    required this.totalTax,
    required this.netSales,
    required this.cashTotal,
    required this.creditTotal,
    required this.upiTotal,
    required this.cardTotal,
    required this.totalInvoices,
    required this.taxableSales,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    this.topProducts = const [],
    this.topCustomers = const [],
    this.taxRateSummaries = const [],
    this.hsnSummaries = const [],
    this.b2bInvoices = 0,
    this.b2bTaxable = 0.0,
    this.b2bTax = 0.0,
    this.b2cInvoices = 0,
    this.b2cTaxable = 0.0,
    this.b2cTax = 0.0,
    this.gstInvoices = const [],
    this.trendPoints = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  @override
  List<Object?> get props => [
        selectedDateRange,
        grossSales,
        totalDiscount,
        totalTax,
        netSales,
        cashTotal,
        creditTotal,
        upiTotal,
        cardTotal,
        totalInvoices,
        taxableSales,
        cgstTotal,
        sgstTotal,
        igstTotal,
        topProducts,
        topCustomers,
        taxRateSummaries,
        hsnSummaries,
        b2bInvoices,
        b2bTaxable,
        b2bTax,
        b2cInvoices,
        b2cTaxable,
        b2cTax,
        gstInvoices,
        trendPoints,
      ];
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final InvoiceRepository repository;

  ReportsBloc({required this.repository}) : super(ReportsInitial()) {
    on<LoadReportsEvent>((event, emit) async {
      emit(ReportsLoading());

      final dbInvoices = AppDatabase.instance.invoices;
      List<Invoice> repoInvoices = [];
      try {
        repoInvoices = await repository.getInvoices('biz_1');
      } catch (_) {}

      final invoiceMap = <String, Invoice>{};
      for (final inv in repoInvoices) {
        invoiceMap[inv.id] = inv;
      }
      for (final inv in dbInvoices) {
        invoiceMap[inv.id] = inv;
      }
      final allInvoices = invoiceMap.values.toList();

      final filteredInvoices = allInvoices.where((inv) {
        if (inv.status == InvoiceStatus.cancelled) return false;
        return _isInvoiceInDateRange(inv.invoiceDate, event.dateRange);
      }).toList();

      double gross = 0.0;
      double disc = 0.0;
      double tax = 0.0;
      double net = 0.0;
      double cash = 0.0;
      double credit = 0.0;
      double upi = 0.0;
      double card = 0.0;
      double taxable = 0.0;
      double cgst = 0.0;
      double sgst = 0.0;
      double igst = 0.0;

      final prodMap = <String, Map<String, dynamic>>{};
      final custMap = <String, Map<String, dynamic>>{};
      final taxRateMap = <double, Map<String, double>>{};
      final hsnMap = <String, Map<String, dynamic>>{};

      double b2bTaxable = 0.0, b2bTax = 0.0;
      int b2bCount = 0;
      double b2cTaxable = 0.0, b2cTax = 0.0;
      int b2cCount = 0;

      final gstInvoicesList = <GstInvoiceData>[];
      final trendValues = List<double>.filled(7, 0.0);
      final now = DateTime.now();

      for (final inv in filteredInvoices) {
        gross += inv.subtotal;
        disc += inv.discount;
        cgst += inv.cgst;
        sgst += inv.sgst;
        igst += inv.igst;
        final invTax = inv.cgst + inv.sgst + inv.igst;
        tax += invTax;
        net += inv.grandTotal;
        final invTaxable = inv.subtotal - inv.discount;
        taxable += invTaxable;

        // Daily trend bucket calculation
        final diffDays = now.difference(inv.invoiceDate).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          trendValues[6 - diffDays] += inv.grandTotal;
        }

        switch (inv.paymentType) {
          case PaymentType.cash:
            cash += inv.grandTotal;
            break;
          case PaymentType.credit:
            credit += inv.grandTotal;
            break;
          case PaymentType.upi:
            upi += inv.grandTotal;
            break;
          case PaymentType.card:
            card += inv.grandTotal;
            break;
        }

        // Top Customers
        final cName = inv.customerName.trim().isNotEmpty ? inv.customerName.trim() : 'Walk-in Customer';
        final cInitials = cName.split(' ').where((s) => s.isNotEmpty).map((e) => e[0].toUpperCase()).take(2).join();
        if (!custMap.containsKey(cName)) {
          custMap[cName] = {
            'initials': cInitials.isNotEmpty ? cInitials : 'C',
            'name': cName,
            'count': 0,
            'total': 0.0,
          };
        }
        custMap[cName]!['count'] = (custMap[cName]!['count'] as int) + 1;
        custMap[cName]!['total'] = (custMap[cName]!['total'] as double) + inv.grandTotal;

        // B2B vs B2C
        final isB2b = inv.customerPhone.isNotEmpty && inv.customerName != 'Walk-in Customer';
        if (isB2b) {
          b2bCount++;
          b2bTaxable += invTaxable;
          b2bTax += invTax;
        } else {
          b2cCount++;
          b2cTaxable += invTaxable;
          b2cTax += invTax;
        }

        if (invTax > 0) {
          gstInvoicesList.add(GstInvoiceData(
            invoiceNumber: inv.invoiceNumber,
            customerName: cName,
            taxableAmount: invTaxable,
            taxAmount: invTax,
          ));
        }

        // Items breakdown for Top Products, Tax Rates, and HSN
        for (final item in inv.items) {
          final pName = item.productName.trim().isNotEmpty ? item.productName.trim() : 'General Item';
          if (!prodMap.containsKey(pName)) {
            prodMap[pName] = {'name': pName, 'qty': 0, 'total': 0.0};
          }
          prodMap[pName]!['qty'] = (prodMap[pName]!['qty'] as int) + item.quantity;
          prodMap[pName]!['total'] = (prodMap[pName]!['total'] as double) + item.totalAmount;

          final rate = item.gstRate;
          if (!taxRateMap.containsKey(rate)) {
            taxRateMap[rate] = {'taxable': 0.0, 'cgst': 0.0, 'sgst': 0.0, 'tax': 0.0};
          }
          taxRateMap[rate]!['taxable'] = (taxRateMap[rate]!['taxable']!) + item.totalAmount;
          taxRateMap[rate]!['cgst'] = (taxRateMap[rate]!['cgst']!) + (item.taxAmount / 2.0);
          taxRateMap[rate]!['sgst'] = (taxRateMap[rate]!['sgst']!) + (item.taxAmount / 2.0);
          taxRateMap[rate]!['tax'] = (taxRateMap[rate]!['tax']!) + item.taxAmount;

          final hsn = item.productId.length >= 4 ? item.productId.substring(0, 4) : '1000';
          if (!hsnMap.containsKey(hsn)) {
            hsnMap[hsn] = {'hsn': hsn, 'desc': pName, 'qty': 0, 'tax': 0.0};
          }
          hsnMap[hsn]!['qty'] = (hsnMap[hsn]!['qty'] as int) + item.quantity;
          hsnMap[hsn]!['tax'] = (hsnMap[hsn]!['tax'] as double) + item.taxAmount;
        }
      }

      final topProducts = prodMap.values
          .map((m) => TopProductData(name: m['name'], quantitySold: m['qty'], totalAmount: m['total']))
          .toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      final topCustomers = custMap.values
          .map((m) => TopCustomerData(initials: m['initials'], name: m['name'], invoiceCount: m['count'], totalAmount: m['total']))
          .toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      final taxRateSummaries = taxRateMap.entries
          .map((e) => TaxRateSummaryData(
                rate: e.key,
                taxableAmount: e.value['taxable']!,
                cgst: e.value['cgst']!,
                sgst: e.value['sgst']!,
                totalTax: e.value['tax']!,
              ))
          .toList()
        ..sort((a, b) => a.rate.compareTo(b.rate));

      final hsnSummaries = hsnMap.values
          .map((m) => HsnSummaryData(hsnCode: m['hsn'], description: m['desc'], quantity: m['qty'], totalTax: m['tax']))
          .toList();

      emit(ReportsLoaded(
        selectedDateRange: event.dateRange,
        grossSales: gross,
        totalDiscount: disc,
        totalTax: tax,
        netSales: net,
        cashTotal: cash,
        creditTotal: credit,
        upiTotal: upi,
        cardTotal: card,
        totalInvoices: filteredInvoices.length,
        taxableSales: taxable,
        cgstTotal: cgst,
        sgstTotal: sgst,
        igstTotal: igst,
        topProducts: topProducts,
        topCustomers: topCustomers,
        taxRateSummaries: taxRateSummaries,
        hsnSummaries: hsnSummaries,
        b2bInvoices: b2bCount,
        b2bTaxable: b2bTaxable,
        b2bTax: b2bTax,
        b2cInvoices: b2cCount,
        b2cTaxable: b2cTaxable,
        b2cTax: b2cTax,
        gstInvoices: gstInvoicesList,
        trendPoints: trendValues,
      ));
    });
  }

  bool _isInvoiceInDateRange(DateTime invDate, String range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final invoiceDay = DateTime(invDate.year, invDate.month, invDate.day);

    switch (range) {
      case 'Today':
        return invoiceDay.isAtSameMomentAs(todayStart);
      case 'Yesterday':
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        return invoiceDay.isAtSameMomentAs(yesterdayStart);
      case '7 Days':
        final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));
        return !invoiceDay.isBefore(sevenDaysAgo) && !invoiceDay.isAfter(todayStart);
      case '30 Days':
        final thirtyDaysAgo = todayStart.subtract(const Duration(days: 29));
        return !invoiceDay.isBefore(thirtyDaysAgo) && !invoiceDay.isAfter(todayStart);
      case 'This Month':
        return invDate.year == now.year && invDate.month == now.month;
      default:
        return true;
    }
  }
}
