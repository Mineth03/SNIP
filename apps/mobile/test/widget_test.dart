import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snip_mobile/shared/widgets/snip_logo.dart';
import 'package:snip_mobile/shared/widgets/theme_toggle_button.dart';
import 'package:snip_mobile/theme/snip_colors.dart';
import 'package:snip_mobile/theme/theme_provider.dart';

void main() {
  test('SNIP brand primary color matches kit', () {
    expect(SnipColors.primary, const Color(0xFF14B8A6));
    expect(SnipColors.dark, const Color(0xFF1F2937));
  });

  test('themeModeProvider toggles correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    container.read(themeModeProvider.notifier).toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.light);

    container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('ThemeToggleButton renders and toggles theme', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ThemeToggleButton(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ThemeToggleButton), findsOneWidget);
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
  });

  testWidgets('SnipLogo renders main logo and dark mode logo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SnipLogo(size: 36, isDarkMode: false),
              SnipLogo(size: 36, isDarkMode: true),
              SnipLogo(size: 28, showText: false),
              SnipLogo(variant: SnipLogoVariant.stacked, size: 60),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SnipLogo), findsNWidgets(4));
  });
}
