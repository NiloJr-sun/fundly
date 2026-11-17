import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device clock for local calendar boundaries; override it in rollover tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
