import 'package:flutter_bloc/flutter_bloc.dart';

class NavBarCubit extends Cubit<int> {
  NavBarCubit() : super(2);

  void updateIndex(int index) {
    emit(index);
  }
}
