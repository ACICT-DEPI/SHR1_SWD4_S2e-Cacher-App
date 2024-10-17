import 'package:flutter_application_1/data/model/invoice_model.dart';
import 'package:flutter_application_1/data/repositories/invoice_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/invoice_repo.dart';
import 'package:flutter_application_1/domain/repositories/products_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/model/product_model.dart';
import '../../../data/repositories/products_repo_impl.dart';
import 'home_state.dart';

class ProductStatisticsCubit extends Cubit<ProductStatisticsStates> {
  ProductStatisticsCubit() : super(ProductStatisticsLoading());

  final ProductsRepo productsRepo = ProductsRepoImpl();
  final InvoiceRepo invoiceRepo = InvoiceRepoImpl();

  List<Invoice> invoices = [];

  void getAllInvoices() async {
    emit(ProductStatisticsLoading());
    try {
      invoices = await invoiceRepo.getInvoices();
      emit(AllInvoicesLoaded(invoices));
    } catch (onError) {
      emit(ProductStatisticsError(onError.toString()));
    }
  }

  void getLast20Invoices() async {
    emit(ProductStatisticsLoading());
    try {
      invoices = await invoiceRepo.getLast20Invoices();
      emit(Last20InvoicesLoaded(invoices));
    } catch (onError) {
      emit(ProductStatisticsError(onError.toString()));
    }
  }

  Future<void> getLowStockProducts() async {
    try {
      emit(ProductStatisticsLoading());
      List<Product> products = await productsRepo.getProducts();
      List<Product> lowStockProducts = products.where((product) {
        return int.parse(product.quantity!) < 10;
      }).toList();
      emit(LowStockLoaded(lowStockProducts));
    } catch (e) {
      emit(ProductStatisticsError(e.toString()));
    }
  }

  Future<void> getBestSellingProducts() async {
    try {
      emit(ProductStatisticsLoading());
      List<Product> products = await productsRepo.getProducts();
      products.sort((a, b) {
        double aRatio = (double.parse(a.firstQuantity!.toString()) -
            double.parse(a.quantity!));
        double bRatio = (double.parse(b.firstQuantity!.toString()) -
            double.parse(b.quantity!));
        return bRatio.compareTo(aRatio);
      });
      emit(BestSellingLoaded(products));
    } catch (e) {
      emit(ProductStatisticsError(e.toString()));
    }
  }

  Future<void> getMostProfitableProducts() async {
    try {
      emit(ProductStatisticsLoading());
      List<Product> products = await productsRepo.getProducts();
      products.sort((a, b) {
        double aProfit = double.parse(a.salary!) - double.parse(a.cost!);
        double bProfit = double.parse(b.salary!) - double.parse(b.cost!);
        return bProfit.compareTo(aProfit);
      });
      emit(MostProfitableLoaded(products));
    } catch (e) {
      emit(ProductStatisticsError(e.toString()));
    }
  }
}

// Define new states for invoice operations
class AllInvoicesLoaded extends ProductStatisticsStates {
  final List<Invoice> invoices;
  AllInvoicesLoaded(this.invoices);
}

class Last20InvoicesLoaded extends ProductStatisticsStates {
  final List<Invoice> invoices;
  Last20InvoicesLoaded(this.invoices);
}
