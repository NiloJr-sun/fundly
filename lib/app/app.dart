import 'package:flutter/material.dart';

/// Root widget of the Fundly app.
///
/// The home screen is a temporary placeholder until the navigation shell
/// (roadmap task 0.3) replaces it.
class FundlyApp extends StatelessWidget {
  const FundlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Fundly',
      home: Scaffold(body: Center(child: Text('Fundly'))),
    );
  }
}
