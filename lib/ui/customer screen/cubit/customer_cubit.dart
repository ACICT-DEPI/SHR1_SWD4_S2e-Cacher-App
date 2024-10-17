import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/repositories/invoice_repo_impl.dart';
import 'package:flutter_application_1/domain/repositories/invoice_repo.dart';
import 'package:flutter_application_1/ui/customer%20screen/cubit/customer_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/model/cleints_model.dart';
import 'dart:convert';

class CustomerCubit extends Cubit<CustomerStates> {
  CustomerCubit() : super(CustomersInitState());

  InvoiceRepo invoiceRepo = InvoiceRepoImpl();
  List<ClientModel> clients = [];
  List<ClientModel> filteredClients = [];

  void getClients() async {
    emit(CustomersLoadingState());
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedClients = prefs.getStringList('cachedClients');

    if (cachedClients != null) {
      clients = cachedClients.map((clientString) => ClientModel.fromJson(json.decode(clientString))).toList();
      filteredClients = clients;
      emit(CustomersLoadingFromCacheState());
      await Future.delayed(const Duration(seconds: 2)); // Delay for 2 seconds
      emit(CustomersSuccessState());
    }

    try {
      final fetchedClients = await invoiceRepo.getAllClientInfo();
      clients = fetchedClients;
      filteredClients = clients;
      await prefs.setStringList('cachedClients', clients.map((client) => json.encode(client.toJson())).toList());
      emit(CustomersSuccessState());
    } catch (error) {
      emit(CustomersErrorState(error.toString()));
    }
  }

  void filterClients(String query) {
    final lowerCaseQuery = query.toLowerCase();
    filteredClients = clients.where((client) {
      return client.clientName.toLowerCase().contains(lowerCaseQuery);
    }).toList();
    emit(CustomersSuccessState());
  }
}
