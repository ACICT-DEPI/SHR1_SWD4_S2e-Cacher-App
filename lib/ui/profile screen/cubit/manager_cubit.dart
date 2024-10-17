import 'package:flutter_application_1/data/repositories/auth_repo_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repo.dart';
import 'manager_states.dart';

class ManagerCubit extends Cubit<ManagerState> {
  AuthRepo authRepo = AuthRepoImpl();

  ManagerCubit() : super(ManagerInitial());

  void fetchManagerData() async {
    try {
      emit(ManagerLoading());
      final manager = await authRepo.fetchManagerData();
      if (manager != null) {
        emit(ManagerLoaded(manager));
      } else {
        emit(ManagerError('Failed to load manager data'));
      }
    } catch (e) {
      emit(ManagerError(e.toString()));
    }
  }
}