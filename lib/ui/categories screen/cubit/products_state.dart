// Base state for products
import '../../../data/model/product_model.dart';

class ProductsState {}

// Loading states
class ProductsStateLoading extends ProductsState {}
class CategoriesStateLoading extends ProductsState {}
class OperationsStateLoading extends ProductsState {}
class ProductUploadStateLoading extends ProductsState {}
class ProductDownloadStateLoading extends ProductsState {}
class LowStockLoaded extends ProductsState {
  final List<Product> lowStockProducts;
  LowStockLoaded(this.lowStockProducts);
}

class ProductsStateIsUsed extends ProductsState{
   String message;
   ProductsStateIsUsed(this.message);
}

// Success states
class ProductsStateSuccess extends ProductsState {}
class CategoriesStateSuccess extends ProductsState {}
class OperationsStateSuccess extends ProductsState {}
class UploadImageSuccess extends ProductsState {}
class ProductUploadStateSuccess extends ProductsState {}
class ProductDownloadStateSuccess extends ProductsState {}

// Warning states
class ProductsStateWarning extends ProductsState {
  final String warning;
  ProductsStateWarning(this.warning);
}

// Error states
class ProductsStateError extends ProductsState {
  final String error;
  ProductsStateError(this.error);
}
class CategoriesStateError extends ProductsState {
  final String error;
  CategoriesStateError(this.error);
}
class OperationsStateError extends ProductsState {
  final String error;
  OperationsStateError(this.error);
}
class UploadImageError extends ProductsState {
  final String error;
  UploadImageError(this.error);
}
class ProductUploadStateError extends ProductsState {
  final String error;
  ProductUploadStateError(this.error);
}
class ProductDownloadStateError extends ProductsState {
  final String error;
  ProductDownloadStateError(this.error);
}

// Empty state (for situations where no data is available)
class ProductsStateEmpty extends ProductsState {}
class CategoriesStateEmpty extends ProductsState {}
