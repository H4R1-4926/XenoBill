import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScanTap;
  final String hintText;
  final bool isScannerOpen;

  const ProductSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    this.onScanTap,
    this.hintText = 'Search product...',
    this.isScannerOpen = false,
  });

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(ProductSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode = widget.focusNode ?? FocusNode();
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _handleDone() {
    _effectiveFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isFocused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Input TextField (Light Ash Filled TextField)
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleDone(),
              style: const TextStyle(
                color: AppColors.nearBlack,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          widget.controller.clear();
                          widget.onChanged('');
                          setState(() {});
                        },
                        child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 18),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        // Done Action Button (when search is focused)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isFocused
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _handleDone,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Scanner Button
        if (widget.onScanTap != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: widget.onScanTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isScannerOpen ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: widget.isScannerOpen ? Colors.white : AppColors.nearBlack,
                size: 22,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
