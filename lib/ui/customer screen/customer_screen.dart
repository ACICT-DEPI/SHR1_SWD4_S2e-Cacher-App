import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/customer%20screen/cubit/customer_cubit.dart';
import 'package:flutter_application_1/ui/customer%20screen/cubit/customer_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../invoice detail screen/invoice_detail_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerCubit()..getClients(),
      child: CustomersScreenContent(),
    );
  }
}

class CustomersScreenContent extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  CustomersScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العملاء', style: TextStyle(color: Colors.white, fontFamily: 'font1')),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 25,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xff4e00e8),
          centerTitle: true,
        ),
        body: BlocBuilder<CustomerCubit, CustomerStates>(
          builder: (context, state) {
            if (state is CustomersLoadingState || state is CustomersLoadingFromCacheState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CustomersErrorState) {
              return Center(child: Text(state.error));
            }

            final customerCubit = context.read<CustomerCubit>();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث بالاسم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      customerCubit.filterClients(value);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: customerCubit.filteredClients.isEmpty
                        ? customerCubit.clients.length
                        : customerCubit.filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = customerCubit.filteredClients.isEmpty
                          ? customerCubit.clients[index]
                          : customerCubit.filteredClients[index];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(client.clientName.isEmpty ? 'مجهول' : client.clientName),
                          subtitle: Text(client.clientPhone.isEmpty ? 'مجهول' : client.clientPhone),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailScreen(
                                  clientId: client.clientId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

