// connectivity_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:connectivity_checker/connectivity_checker.dart';

enum ConnectivityState { connected, disconnected }

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit() : super(ConnectivityState.disconnected) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    ConnectivityWrapper.instance.onStatusChange.listen((status) {
      if (status == ConnectivityStatus.DISCONNECTED) {
        emit(ConnectivityState.disconnected);
      } else {
        emit(ConnectivityState.connected);
      }
    });
  }
}
