import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../application/invoice/invoice_bloc.dart';
import 'full_cart_modal.dart';

class CollapsibleCart extends StatefulWidget {
  final List<InvoiceItem> items;
  final int totalItemCount;

  const CollapsibleCart({
    super.key,
    required this.items,
    required this.totalItemCount,
  });

  @override
  State<CollapsibleCart> createState() => _CollapsibleCartState();
}

class _CollapsibleCartState extends State<CollapsibleCart> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // COLLAPSED CART BAR (Header)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CART',
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.nearBlack,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${widget.totalItemCount} items',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // EXPANDED CART ITEMS PREVIEW
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      if (widget.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Cart is empty. Tap products to add.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(
                            children: widget.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    // Item Details (Name & 1×100)
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.nearBlack,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.quantity}×${item.unitPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Stepper [- 1 +]
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              context.read<InvoiceBloc>().add(
                                                    UpdateCartQuantityEvent(
                                                      productId: item.productId,
                                                      delta: -1,
                                                    ),
                                                  );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              child: Icon(Icons.remove, size: 14, color: AppColors.nearBlack),
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.nearBlack,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              context.read<InvoiceBloc>().add(
                                                    UpdateCartQuantityEvent(
                                                      productId: item.productId,
                                                      delta: 1,
                                                    ),
                                                  );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              child: Icon(Icons.add, size: 14, color: AppColors.nearBlack),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Tag Price Badge (🏷️ ₹ 100)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.local_offer_outlined, size: 12, color: Color(0xFF6B7280)),
                                          const SizedBox(width: 4),
                                          Text(
                                            CurrencyFormatter.format(item.totalAmount),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.nearBlack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        // View Full Cart Button
                        InkWell(
                          onTap: () => FullCartModal.show(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Full Cart Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.darkNavy),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
