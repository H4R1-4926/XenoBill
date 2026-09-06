import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class InvoiceActionButtons extends StatelessWidget {
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;
  final double grandTotal;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const InvoiceActionButtons({
    super.key,
    required this.subtotal,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    required this.totalTax,
    required this.grandTotal,
    required this.isSaving,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    final double gstPercentage = subtotal > 0 ? (totalTax / subtotal) * 100 : 5.0;
    final String gstLabel = 'GST (${gstPercentage.toStringAsFixed(0)}%):';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Financial Breakdown Rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'subtotal:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(subtotal),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (totalTax > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    gstLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalTax),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Grand Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nearBlack,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(grandTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nearBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons Row (Save & Save & Print)
            Row(
              children: [
                // Save Outlined Capsule Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onSave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.nearBlack,
                      side: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nearBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Save & Print Primary Capsule Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSaveAndPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Print',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
