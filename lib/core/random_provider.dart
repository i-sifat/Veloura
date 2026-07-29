import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared injectable random source for deterministic game tests.
final randomProvider = Provider<Random>((ref) => Random.secure());
