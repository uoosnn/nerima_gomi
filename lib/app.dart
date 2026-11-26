import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/core/theme/app_theme.dart';
import 'package:nerima_gomi/features/calendar/calendar_screen.dart';
import 'package:nerima_gomi/features/dictionary/dictionary_screen.dart';
import 'package:nerima_gomi/features/home/home_screen.dart';
import 'package:nerima_gomi/features/settings/settings_screen.dart';
import 'package:nerima_gomi/providers/app_providers.dart';

class NerimaGomiApp extends ConsumerWidget {
  const NerimaGomiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return MaterialApp(
      title: state.strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      locale: state.language == AppLanguage.ja
          ? const Locale('ja')
          : const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _MainShell(),
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    DictionaryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final s = state.strings;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: s.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: s.navDictionary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
