import 'package:flutter/material.dart';

import 'home_shell.dart';

/// Root widget of the Fundly app.
class FundlyApp extends StatelessWidget {
  const FundlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Fundly', home: HomeShell());
  }
}
