import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/entities/invoice.dart';

class InvoiceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String invoiceNumber;
  final Customer selectedCustomer;
  final PaymentType selectedPaymentType;
  final VoidCallback onTapCustomer;
  final ValueChanged<PaymentType> onSelectPayment;
  final TextEditingController? nameController;
  final TextEditingController? phoneController;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onPhoneChanged;
  final bool isReadOnly;

  const InvoiceAppBar({
    super.key,
    required this.invoiceNumber,
    required this.selectedCustomer,
    required this.selectedPaymentType,
    required this.onTapCustomer,
    required this.onSelectPayment,
    this.nameController,
    this.phoneController,
    this.onNameChanged,
    this.onPhoneChanged,
    this.isReadOnly = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(165);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate =
        DateFormat('dd/MM/yy h:mm a').format(now).toLowerCase();

    final bool isCredit = selectedPaymentType == PaymentType.credit;
    final bool isWalkIn = selectedCustomer.id == 'cust_walk_in';
    final String customerTitle =
        isWalkIn ? 'walk-in customer' : selectedCustomer.name;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Back Arrow (Left) & Invoice # / Timestamp (Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.nearBlack, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        invoiceNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Customer Section Label (Left) & Cash / Credit Toggle Pills (Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: isCredit ? onTapCustomer : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customerTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: isCredit
                                  ? AppColors.nearBlack
                                  : const Color(0xFF6B7280),
                              fontWeight:
                                  isCredit ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (isCredit) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 18, color: Color(0xFF6B7280)),
                          ],
                        ],
                      ),
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
              const SizedBox(height: 12),

              // Row 3: Name TextField & Phone TextField (Equal Width Input Fields)
              Row(
                children: [
                  // Customer Name Field
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: nameController,
                        onChanged: onNameChanged,
                        readOnly: isReadOnly,
                        enableInteractiveSelection: !isReadOnly,
                        canRequestFocus: !isReadOnly,
                        mouseCursor: isReadOnly
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isReadOnly
                              ? const Color(0xFF6B7280)
                              : AppColors.nearBlack,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isReadOnly
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFFF3F4F6),
                          hintText: 'Name',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade400,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Customer Phone Field
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: phoneController,
                        onChanged: onPhoneChanged,
                        readOnly: isReadOnly,
                        enableInteractiveSelection: !isReadOnly,
                        canRequestFocus: !isReadOnly,
                        mouseCursor: isReadOnly
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.text,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isReadOnly
                              ? const Color(0xFF6B7280)
                              : AppColors.nearBlack,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isReadOnly
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFFF3F4F6),
                          hintText: 'Phone',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade400,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
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
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
