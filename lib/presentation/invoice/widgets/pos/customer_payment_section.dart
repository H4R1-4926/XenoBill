import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/entities/invoice.dart';

class CustomerPaymentSection extends StatelessWidget {
  final Customer selectedCustomer;
  final PaymentType selectedPaymentType;
  final VoidCallback onTapCustomer;
  final ValueChanged<PaymentType> onSelectPayment;
  final String customerLabel;
  final TextEditingController? phoneController;

  const CustomerPaymentSection({
    super.key,
    required this.selectedCustomer,
    required this.selectedPaymentType,
    required this.onTapCustomer,
    required this.onSelectPayment,
    this.customerLabel = 'credit customer',
    this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Section Label + Payment Toggle Pills (Cash / Credit)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                customerLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPaymentPill(PaymentType.cash, 'Cash'),
                  const SizedBox(width: 6),
                  _buildPaymentPill(PaymentType.credit, 'Credit'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Customer Name Selector & Inner White Phone Field Box
          Row(
            children: [
              // Customer Name Selector Box
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: onTapCustomer,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedCustomer.name.isNotEmpty
                                ? selectedCustomer.name
                                : 'customer name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selectedCustomer.name.isNotEmpty
                                  ? AppColors.nearBlack
                                  : Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Phone Field Outer Light Grey Box & Inner White Box (As in User Screenshot)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: phoneController,
                      readOnly: selectedCustomer.id != 'cust_walk_in' && selectedCustomer.phone.isNotEmpty,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.nearBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: selectedCustomer.phone.isNotEmpty ? selectedCustomer.phone : 'Phone',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(PaymentType type, String label) {
    final bool isSelected = selectedPaymentType == type;
    return InkWell(
      onTap: () => onSelectPayment(type),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26282B) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
