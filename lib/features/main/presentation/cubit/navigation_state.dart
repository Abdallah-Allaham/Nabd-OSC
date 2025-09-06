abstract class NavigationState {
  final int index;
  const NavigationState(this.index);
}

class NavigationInitial extends NavigationState {
  NavigationInitial() : super(0);
}

class NavigationChanged extends NavigationState {
  NavigationChanged(int index) : super(index);
}
