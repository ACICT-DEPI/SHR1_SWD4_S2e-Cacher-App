part of 'nav_bar_states.dart';

abstract class NavBarState {}

class NavBarInitial extends NavBarState {
  final int index;
  NavBarInitial(this.index);
}
