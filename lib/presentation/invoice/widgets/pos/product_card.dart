import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/item.dart';

class ProductCard extends StatelessWidget {
  final Item product;
  final VoidCallback onAddTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProduct = product.isProduct;
    final int stock = product.currentStock;
    final bool isOutOfStock = isProduct && stock <= 0;
    final bool hasImage = product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOutOfStock ? Colors.grey.shade300 : AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOutOfStock ? null : onAddTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Product Image or 'No Photo' Placeholder Box
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: hasImage
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildNoPhotoFallback(),
                              )
                            : _buildNoPhotoFallback(),
                      ),
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Out of stock',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Details Section (Product Name & Price)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isOutOfStock ? Colors.grey.shade600 : AppColors.nearBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(product.sellingPrice),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isOutOfStock ? Colors.grey.shade500 : AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPhotoFallback() {
    return Container(
      color: const Color(0xFFEFEFEF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'no photo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
