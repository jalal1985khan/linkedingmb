import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

extension NavigationBackExtension on WidgetRef {
  void handleSmartBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      read(bottomNavIndexProvider.notifier).state = 0;
    }
  }
}
