import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/model/product_model.dart';
import '../../../data/repositories/invoice_repo_impl.dart';
import '../../../domain/repositories/invoice_repo.dart';
import 'profit_states.dart';

class ProfitCubit extends Cubit<ProfitStates> {
  ProfitCubit() : super(ProfitInitState());

  InvoiceRepo invoicesRepo = InvoiceRepoImpl();
  List<Product?> products = [];

  void fetchProductsFromInvoices() async {
    try {
      emit(ProfitLoadingState());
      final invoices = await invoicesRepo.getInvoices();
      for (var invoice in invoices) {
        products.addAll(invoice.products);
      }
      emit(ProfitSuccessState());
    } catch (e) {
      emit(ProfitErrorState(e.toString()));
    }
  }

  double totalProfit() {
    double sum = 0;
    for (var product in products) {
      sum += product?.profit ?? 0.0;
    }
    return sum;
  }
}
