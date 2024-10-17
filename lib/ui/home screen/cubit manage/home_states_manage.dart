class HomeTabStates {}

class HomeTabSuccessState extends HomeTabStates {}

class HomeTabStateError extends HomeTabStates {
  String error;
  HomeTabStateError(this.error);
}

class HomeTabStateLoading extends HomeTabStates {}

class HomeTabStatePDFLoading extends HomeTabStates {}
