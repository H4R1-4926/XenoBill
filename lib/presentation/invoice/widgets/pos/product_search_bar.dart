import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScanTap;
  final String hintText;

  const ProductSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    this.onScanTap,
    this.hintText = 'Search Product name, SKU or barcode',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Input Container
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.darkNavy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.nearBlack,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  ),
              ],
            ),
          ),
        ),
        if (onScanTap != null) ...[
          const SizedBox(width: 8),
          // Barcode Icon Button (Square Tile)
          InkWell(
            onTap: onScanTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.line_weight_sharp, // Barcode representation icon
                color: AppColors.darkNavy,
                size: 22,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
