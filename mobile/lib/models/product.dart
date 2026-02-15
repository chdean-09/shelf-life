import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String barcode;

  late String name;

  String? brand;

  String? imageUrl;

  String? category;

  late DateTime cachedAt;

  // Constructor
  Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.category,
  }) {
    cachedAt = DateTime.now();
  }

  // Empty constructor for Isar
  Product.empty();

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'category': category,
    };
  }

  /// Creates a Product from JSON (API response or OpenFoodFacts).
  factory Product.fromJson(Map<String, dynamic> json) {
    final product = Product(
      barcode: json['barcode'] as String,
      name: json['name'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
    );
    return product;
  }
}
