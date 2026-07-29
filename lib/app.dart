import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/config/app_router.dart';
import 'package:veloura/theme/app_theme.dart';

/// Root application widget for Veloura.
class VelouraApp extends ConsumerWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
