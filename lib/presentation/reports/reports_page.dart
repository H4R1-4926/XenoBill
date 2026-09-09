import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../application/reports/reports_bloc.dart';
import '../../infrastructure/database/app_database.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedReportType = 0; // 0 = Sales Reports, 1 = GST Reports
  String _selectedDateRange = 'Today';
  String _selectedGstSubTab = 'Tax Rate Summary';

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadReportsEvent(dateRange: _selectedDateRange));
  }

  Future<void> _downloadPdfReport(ReportsLoaded? state, bool isGstEnabled) async {
    if (state == null) return;

    final pdf = pw.Document();
    final biz = AppDatabase.instance.currentBusiness;
    final bizName = biz?.name ?? 'Xenobill Business';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(bizName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      if (biz != null && biz.phone.isNotEmpty) pw.Text('Phone: ${biz.phone}'),
                      if (isGstEnabled && biz != null && biz.gstin.isNotEmpty) pw.Text('GSTIN: ${biz.gstin}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Period: ${state.selectedDateRange}'),
                      pw.Text('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Sales Summary
            pw.Text('Sales Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Amount'],
              data: [
                ['Gross Sales', CurrencyFormatter.format(state.grossSales)],
                ['Total Discount', '-${CurrencyFormatter.format(state.totalDiscount)}'],
                ['Tax Collected', CurrencyFormatter.format(state.totalTax)],
                ['Net Sales Total', CurrencyFormatter.format(state.netSales)],
                ['Total Invoices Count', '${state.totalInvoices}'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),

            // Payment Methods
            pw.Text('Payment Mode Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Payment Mode', 'Amount'],
              data: [
                ['Cash', CurrencyFormatter.format(state.cashTotal)],
                ['Credit', CurrencyFormatter.format(state.creditTotal)],
                ['UPI', CurrencyFormatter.format(state.upiTotal)],
                ['Card', CurrencyFormatter.format(state.cardTotal)],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),

            // Top Products
            if (state.topProducts.isNotEmpty) ...[
              pw.Text('Top Selling Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Product Name', 'Qty Sold', 'Total Revenue'],
                data: state.topProducts
                    .take(5)
                    .map((p) => [p.name, '${p.quantitySold}', CurrencyFormatter.format(p.totalAmount)])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
            ],

            // GST Summary
            if (isGstEnabled) ...[
              pw.Text('GST & Tax Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Tax Category', 'Amount'],
                data: [
                  ['Taxable Sales', CurrencyFormatter.format(state.taxableSales)],
                  ['CGST Total', CurrencyFormatter.format(state.cgstTotal)],
                  ['SGST Total', CurrencyFormatter.format(state.sgstTotal)],
                  ['IGST Total', CurrencyFormatter.format(state.igstTotal)],
                  ['Total GST Collected', CurrencyFormatter.format(state.totalTax)],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Xenobill_Report_${state.selectedDateRange}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final isGstEnabled = AppDatabase.instance.currentBusiness?.gstEnabled ?? true;
    if (!isGstEnabled && _selectedReportType != 0) {
      _selectedReportType = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkNavy),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        actions: [
          BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              ReportsLoaded? loadedState;
              if (state is ReportsLoaded) {
                loadedState = state;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () async {
                    if (loadedState == null) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating PDF report...')),
                    );
                    await _downloadPdfReport(loadedState, isGstEnabled);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppColors.darkNavy, size: 20),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show segmented switcher only if GST is enabled
              if (isGstEnabled)
                _buildSegmentedTabSwitcher()
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Sales Reports',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                ),

              const SizedBox(height: 14),

              // Date Filter Chips
              _buildDateRangeChips(),
              const SizedBox(height: 18),

              // Dynamic Body based on active tab
              BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, state) {
                  ReportsLoaded? loadedState;
                  if (state is ReportsLoaded) {
                    loadedState = state;
                  }

                  if (_selectedReportType == 0 || !isGstEnabled) {
                    return _buildSalesReportView(loadedState);
                  } else {
                    return _buildGstReportView(loadedState);
                  }
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP SEGMENTED SWITCHER
  // ==========================================
  Widget _buildSegmentedTabSwitcher() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedReportType = 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedReportType == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedReportType == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sales Reports',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedReportType == 0 ? AppColors.darkNavy : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedReportType = 1),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedReportType == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedReportType == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'GST Reports',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedReportType == 1 ? AppColors.darkNavy : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DATE RANGE CHIPS
  // ==========================================
  Widget _buildDateRangeChips() {
    final ranges = ['Today', 'Yesterday', '7 Days', '30 Days'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ranges.map((range) {
          final isSelected = _selectedDateRange == range;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                range,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.darkNavy,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0B1329),
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedDateRange = range);
                  context.read<ReportsBloc>().add(LoadReportsEvent(dateRange: range));
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // SALES REPORT VIEW
  // ==========================================
  Widget _buildSalesReportView(ReportsLoaded? state) {
    final grossSales = state?.grossSales ?? 0.0;
    final totalDiscount = state?.totalDiscount ?? 0.0;
    final totalTax = state?.totalTax ?? 0.0;
    final netSales = state?.netSales ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sales Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
              ),
              const SizedBox(height: 14),
              _buildSummaryRow('Gross sales', CurrencyFormatter.format(grossSales)),
              const SizedBox(height: 10),
              _buildSummaryRow('Discount', '-${CurrencyFormatter.format(totalDiscount)}'),
              const SizedBox(height: 10),
              _buildSummaryRow('Tax collected', CurrencyFormatter.format(totalTax)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Color(0xFFF1F5F9), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net sales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                  Text(
                    CurrencyFormatter.format(netSales),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Sales Trend Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SalesTrendChartPainter(trendPoints: state?.trendPoints ?? const [0, 0, 0, 0, 0, 0, 0]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                  return Text(
                    day,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. By Payment Method Card
        _buildPaymentMethodCard(state),

        const SizedBox(height: 22),

        // 4. Top Products Section
        const Text(
          'Top products',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
        ),
        const SizedBox(height: 10),
        _buildTopProductsCard(state?.topProducts ?? []),

        const SizedBox(height: 22),

        // 5. Top Customers Section
        const Text(
          'Top customers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
        ),
        const SizedBox(height: 10),
        _buildTopCustomersCard(state?.topCustomers ?? []),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(ReportsLoaded? state) {
    final cashVal = state?.cashTotal ?? 0.0;
    final creditVal = state?.creditTotal ?? 0.0;
    final upiVal = state?.upiTotal ?? 0.0;
    final cardVal = state?.cardTotal ?? 0.0;

    final total = cashVal + creditVal + upiVal + cardVal;
    final cashPct = total > 0 ? ((cashVal / total) * 100).round() : 0;
    final creditPct = total > 0 ? ((creditVal / total) * 100).round() : 0;
    final upiPct = total > 0 ? ((upiVal / total) * 100).round() : 0;
    final cardPct = total > 0 ? ((cardVal / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By payment method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),
          _buildProgressItem('Cash', cashVal, cashPct, const Color(0xFF00B2FF)),
          const SizedBox(height: 12),
          _buildProgressItem('Credit', creditVal, creditPct, const Color(0xFF0B1329)),
          const SizedBox(height: 12),
          _buildProgressItem('UPI', upiVal, upiPct, const Color(0xFF38BDF8)),
          const SizedBox(height: 12),
          _buildProgressItem('Card', cardVal, cardPct, const Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double amount, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
            Text('${CurrencyFormatter.format(amount)} · $pct%', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct > 0 ? (pct / 100.0).clamp(0.02, 1.0) : 0.0,
            backgroundColor: const Color(0xFFF1F5F9),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(List<TopProductData> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No products sold in this period',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(products.length, (index) {
          final item = products[index];
          final isLast = index == products.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1329),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                          const SizedBox(height: 2),
                          Text('${item.quantitySold} units sold', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.format(item.totalAmount), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: Color(0xFFF1F5F9), height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopCustomersCard(List<TopCustomerData> customers) {
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No customer transactions in this period',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(customers.length, (index) {
          final item = customers[index];
          final isLast = index == customers.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1329),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                          const SizedBox(height: 2),
                          Text('${item.invoiceCount} invoices', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Text(CurrencyFormatter.format(item.totalAmount), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: Color(0xFFF1F5F9), height: 16),
            ],
          );
        }),
      ),
    );
  }

  // ==========================================
  // GST REPORT VIEW
  // ==========================================
  Widget _buildGstReportView(ReportsLoaded? state) {
    final taxableSales = state?.taxableSales ?? 0.0;
    final totalTax = state?.totalTax ?? 0.0;
    final cgst = state?.cgstTotal ?? 0.0;
    final sgst = state?.sgstTotal ?? 0.0;
    final igst = state?.igstTotal ?? 0.0;
    final invoicesCount = state?.totalInvoices ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Grid of 6 KPI Cards (2 Columns)
        Row(
          children: [
            Expanded(child: _buildKpiCard('Taxable sales', CurrencyFormatter.format(taxableSales), isDark: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildKpiCard('Total tax', CurrencyFormatter.format(totalTax))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKpiCard('CGST', CurrencyFormatter.format(cgst))),
            const SizedBox(width: 12),
            Expanded(child: _buildKpiCard('SGST', CurrencyFormatter.format(sgst))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKpiCard('IGST', CurrencyFormatter.format(igst))),
            const SizedBox(width: 12),
            Expanded(child: _buildKpiCard('GST invoices', '$invoicesCount')),
          ],
        ),

        const SizedBox(height: 20),

        // 2. GST Sub-tab Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Tax Rate Summary', 'HSN Summary', 'B2B vs B2C', 'GST Invoice List'].map((subTab) {
              final isSelected = _selectedGstSubTab == subTab;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    subTab,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.darkNavy,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0B1329),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _selectedGstSubTab = subTab);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Dynamic Sub-tab Table Cards
        if (_selectedGstSubTab == 'Tax Rate Summary') _buildTaxRateSummaryCard(state?.taxRateSummaries ?? []),
        if (_selectedGstSubTab == 'HSN Summary') _buildHsnSummaryCard(state?.hsnSummaries ?? []),
        if (_selectedGstSubTab == 'B2B vs B2C') _buildB2bB2cSummaryCard(state),
        if (_selectedGstSubTab == 'GST Invoice List') _buildGstInvoiceListCard(state?.gstInvoices ?? []),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, {bool isDark = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1329) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRateSummaryCard(List<TaxRateSummaryData> rates) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tax rate summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),
          if (rates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: Text('No tax data in this period', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else ...[
            const Row(
              children: [
                Expanded(flex: 2, child: Text('RATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 3, child: Text('TAXABLE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 2, child: Text('CGST', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 2, child: Text('SGST', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 3, child: Text('TOTAL TAX', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            ...rates.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('${row.rate.toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                    Expanded(flex: 3, child: Text(CurrencyFormatter.format(row.taxableAmount), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 2, child: Text(CurrencyFormatter.format(row.cgst), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 2, child: Text(CurrencyFormatter.format(row.sgst), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 3, child: Text(CurrencyFormatter.format(row.totalTax), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildHsnSummaryCard(List<HsnSummaryData> hsnList) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HSN summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),
          if (hsnList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: Text('No HSN data in this period', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else ...[
            const Row(
              children: [
                Expanded(flex: 2, child: Text('HSN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 4, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 2, child: Text('QTY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 3, child: Text('TAX', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            ...hsnList.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(row.hsnCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                    Expanded(flex: 4, child: Text(row.description, style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 2, child: Text('${row.quantity}', style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 3, child: Text(CurrencyFormatter.format(row.totalTax), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildB2bB2cSummaryCard(ReportsLoaded? state) {
    final b2bCount = state?.b2bInvoices ?? 0;
    final b2bTaxable = state?.b2bTaxable ?? 0.0;
    final b2bTax = state?.b2bTax ?? 0.0;

    final b2cCount = state?.b2cInvoices ?? 0;
    final b2cTaxable = state?.b2cTaxable ?? 0.0;
    final b2cTax = state?.b2cTax ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'B2B vs B2C summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(flex: 4, child: Text('TYPE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Expanded(flex: 2, child: Text('INVOICES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Expanded(flex: 3, child: Text('TAXABLE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              Expanded(flex: 3, child: Text('TAX', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                const Expanded(flex: 4, child: Text('B2B (Registered)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                Expanded(flex: 2, child: Text('$b2bCount', style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                Expanded(flex: 3, child: Text(CurrencyFormatter.format(b2bTaxable), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                Expanded(flex: 3, child: Text(CurrencyFormatter.format(b2bTax), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                const Expanded(flex: 4, child: Text('B2C (Consumer)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                Expanded(flex: 2, child: Text('$b2cCount', style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                Expanded(flex: 3, child: Text(CurrencyFormatter.format(b2cTaxable), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                Expanded(flex: 3, child: Text(CurrencyFormatter.format(b2cTax), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstInvoiceListCard(List<GstInvoiceData> invoices) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GST Invoices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
          ),
          const SizedBox(height: 14),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: Text('No GST invoices in this period', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else ...[
            const Row(
              children: [
                Expanded(flex: 3, child: Text('INV NO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 4, child: Text('CUSTOMER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 3, child: Text('TAXABLE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
                Expanded(flex: 3, child: Text('TAX', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)))),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            ...invoices.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(row.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy))),
                    Expanded(flex: 4, child: Text(row.customerName, style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 3, child: Text(CurrencyFormatter.format(row.taxableAmount), style: const TextStyle(fontSize: 13, color: AppColors.darkNavy))),
                    Expanded(flex: 3, child: Text(CurrencyFormatter.format(row.taxAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTER FOR SALES TREND SMOOTH CHART
// ==========================================
class _SalesTrendChartPainter extends CustomPainter {
  final List<double> trendPoints;

  _SalesTrendChartPainter({this.trendPoints = const [0, 0, 0, 0, 0, 0, 0]});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF00B2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00B2FF).withValues(alpha: 0.25),
          const Color(0xFF00B2FF).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final maxVal = trendPoints.fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final count = trendPoints.length > 1 ? trendPoints.length : 7;

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final val = i < trendPoints.length ? trendPoints[i] : 0.0;
      final x = size.width * (i / (count - 1));
      final normY = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
      final y = size.height * (0.85 - (normY * 0.70));
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SalesTrendChartPainter oldDelegate) {
    return oldDelegate.trendPoints != trendPoints;
  }
}
