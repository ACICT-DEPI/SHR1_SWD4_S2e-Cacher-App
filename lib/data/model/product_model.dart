class Product {
  late final String? productId;
  final String? name;
  final String? category;
  final String? parcode;
  late final String? salary;
  late final String? cost;
  String? quantity;
  final double? profit;
  final double? firstQuantity;
  bool isRefunded = false;
  bool isReplaced = false;
  bool isReplacedDone = false;
  final DateTime? createdDate;

  Product({
    this.productId,
    this.name,
    this.category,
    this.parcode,
    this.salary,
    this.cost,
    this.quantity,
    this.profit,
    this.firstQuantity,
    required this.isRefunded,
    required this.isReplaced,
    required this.isReplacedDone,
    this.createdDate,
  });


  Product copyWith(
      {String? productId,
      String? name,
      String? category,
      String? parcode,
      String? salary,
      String? cost,
      String? quantity,
      double? profit,
      double? firstQuantity,
      bool isRefunded = false,
      bool isReplaced = false,
      bool isReplacedDone = false,
      DateTime? createdDate}) {
    return Product(
        productId: productId ?? this.productId,
        name: name ?? this.name,
        category: category ?? this.category,
        parcode: parcode ?? this.parcode,
        salary: salary ?? this.salary,
        cost: cost ?? this.cost,
        quantity: quantity ?? this.quantity,
        profit: profit ?? this.profit,
        firstQuantity: firstQuantity ?? this.firstQuantity,
        isRefunded: isRefunded,
        isReplaced: isReplaced,
        isReplacedDone: isReplacedDone,
        createdDate: createdDate ?? this.createdDate);
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'product_name': name,
        'product_category': category,
        'product_parcode': parcode,
        'product_salary': salary,
        'product_cost': cost,
        'product_quantity': quantity,
        'product_profit': profit,
        'product_firstQuantity': firstQuantity,
        'isRefunded': isRefunded,
        'isReplaced': isReplaced,
        'isReplacedDone': isReplacedDone,
        'product_createdDate': DateTime.now().toIso8601String(),
      };

  static Product fromJson(Map<String, dynamic> json) => Product(
        productId: json['productId'],
        name: json['product_name'],
        category: json['product_category'],
        parcode: json['product_parcode'],
        salary: json['product_salary'],
        cost: json['product_cost'],
        quantity: json['product_quantity'],
        profit: json['product_profit'],
        firstQuantity: json['product_firstQuantity'],
        isRefunded: json['isRefunded'] ?? false,
        isReplaced: json['isReplaced'] ?? false,
        isReplacedDone: json['isReplacedDone'] ?? false,
        createdDate: DateTime.parse(json['product_createdDate']),
      );
}
