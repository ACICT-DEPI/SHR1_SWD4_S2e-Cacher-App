abstract class ProfitStates {}

class ProfitInitState extends ProfitStates {}

class ProfitLoadingState extends ProfitStates {}

class ProfitSuccessState extends ProfitStates {}

class ProfitErrorState extends ProfitStates {
  String error;
  ProfitErrorState(this.error);
}
