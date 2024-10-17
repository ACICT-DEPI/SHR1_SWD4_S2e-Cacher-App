abstract class CustomerStates {}

class CustomersInitState extends CustomerStates {}

class CustomersLoadingState extends CustomerStates {}

class CustomersErrorState extends CustomerStates {
  String error;
  CustomersErrorState(this.error);
}

class CustomersSuccessState extends CustomerStates {}

class CustomersLoadingFromCacheState extends CustomerStates {}

