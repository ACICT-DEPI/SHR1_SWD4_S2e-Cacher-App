import '../../../data/model/product_model.dart';

abstract class ProductStatisticsStates {}

class ProductStatisticsLoading extends ProductStatisticsStates {}

class LowStockLoaded extends ProductStatisticsStates {
  final List<Product> lowStockProducts;
  LowStockLoaded(this.lowStockProducts);
}

class BestSellingLoaded extends ProductStatisticsStates {
  final List<Product> bestSellingProducts;
  BestSellingLoaded(this.bestSellingProducts);
}

class MostProfitableLoaded extends ProductStatisticsStates {
  final List<Product> mostProfitableProducts;
  MostProfitableLoaded(this.mostProfitableProducts);
}

class ProductStatisticsError extends ProductStatisticsStates {
  final String error;
  ProductStatisticsError(this.error);
}

