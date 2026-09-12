import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/snip_theme.dart';
import 'theme/theme_provider.dart';

class SnipApp extends ConsumerWidget {
  const SnipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SNIP',
      debugShowCheckedModeBanner: false,
      theme: SnipTheme.light,
      darkTheme: SnipTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
