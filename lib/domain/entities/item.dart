import 'package:equatable/equatable.dart';

enum ItemType { product, service, roomCharge }

class Item extends Equatable {
  final String id;
  final String businessId;
  final ItemType type;
  final String name;
  final String description;
  final String sku;
  final String barcode;
  final String category;
  final String unit;
  final double sellingPrice;
  final double purchasePrice;
  final double mrp;
  final double gstRate;
  final bool isTaxable;
  final int currentStock;
  final int lowStockLimit;
  final int durationMinutes; // For services (e.g. 30 mins haircut)
  final bool isActive;
  final String? imageUrl;

  const Item({
    required this.id,
    required this.businessId,
    required this.type,
    required this.name,
    this.description = '',
    this.sku = '',
    this.barcode = '',
    this.category = 'General',
    this.unit = 'Unit',
    required this.sellingPrice,
    this.purchasePrice = 0.0,
    this.mrp = 0.0,
    this.gstRate = 5.0,
    this.isTaxable = true,
    this.currentStock = 0,
    this.lowStockLimit = 5,
    this.durationMinutes = 0,
    this.isActive = true,
    this.imageUrl,
  });

  bool get isProduct => type == ItemType.product;
  bool get isService => type == ItemType.service;
  bool get isRoomCharge => type == ItemType.roomCharge;
  bool get isLowStock => isProduct && currentStock <= lowStockLimit;
  bool get isOutOfStock => isProduct && currentStock <= 0;

  Item copyWith({
    String? id,
    String? businessId,
    ItemType? type,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? sellingPrice,
    double? purchasePrice,
    double? mrp,
    double? gstRate,
    bool? isTaxable,
    int? currentStock,
    int? lowStockLimit,
    int? durationMinutes,
    bool? isActive,
    String? imageUrl,
  }) {
    return Item(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      mrp: mrp ?? this.mrp,
      gstRate: gstRate ?? this.gstRate,
      isTaxable: isTaxable ?? this.isTaxable,
      currentStock: currentStock ?? this.currentStock,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        type,
        name,
        description,
        sku,
        barcode,
        category,
        unit,
        sellingPrice,
        purchasePrice,
        mrp,
        gstRate,
        isTaxable,
        currentStock,
        lowStockLimit,
        durationMinutes,
        isActive,
        imageUrl,
      ];
}
