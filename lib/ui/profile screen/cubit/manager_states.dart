import '../../../data/model/manager_model.dart';

abstract class ManagerState {}

class ManagerInitial extends ManagerState {}

class ManagerLoading extends ManagerState {}

class ManagerLoaded extends ManagerState {
  final ManagerModel manager;

  ManagerLoaded(this.manager);
}

class ManagerError extends ManagerState {
  final String message;

  ManagerError(this.message);
}