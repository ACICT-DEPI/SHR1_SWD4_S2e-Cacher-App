import '../../data/model/product_model.dart';

abstract class ProductsRepo {
  Future<void> addProduct(String name, String category, String parcode,
      String quantity, String salary, String cost);
  Future<List<Product>> getProducts();
  Future<void> updateProduct(String barcode, Map<String, dynamic> updatedData);
  Future<bool> isBarcodeUsed(String barcode);
  Future<Product?> getProductByBarcode(String barcode);
  Future<Product?> getProductById(String productId);
  Future<void> deleteProduct(String barcode);
  Future<List<Product>> getProductsByCategory(String category);
  Future<void> updateProductQuantity(String barcode, int quantityChange);
  Future<List<Product>> getLatestProducts({int limit = 50});
}
