import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/component_detail_screen.dart';
import 'screens/builder_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/build_comparison_screen.dart';
import 'screens/search_screen.dart';
import 'screens/builds_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppTheme.primary,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PcBuilderApp());
}

class PcBuilderApp extends StatelessWidget {
  const PcBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp.router(
        title: 'PC Builder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return _MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/builder',
          builder: (context, state) => const BuilderScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/builds',
          builder: (context, state) => const BuildsScreen(),
        ),
      ],
    ),
    // Outside shell (full screen)
    GoRoute(
      path: '/category/:key',
      builder: (context, state) => CategoryScreen(
        categoryKey: state.pathParameters['key'] ?? 'cpu',
      ),
    ),
    GoRoute(
      path: '/component/:id',
      builder: (context, state) => ComponentDetailScreen(
        componentId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => const ComparisonScreen(),
    ),
    GoRoute(
      path: '/compare-builds',
      builder: (context, state) => BuildComparisonScreen(
        buildId1: state.uri.queryParameters['id1'] ?? '',
        buildId2: state.uri.queryParameters['id2'] ?? '',
      ),
    ),
  ],
);

class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/builder')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/builds')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final provider = context.watch<AppProvider>();
    final buildCount = provider.currentBuild.components.length;
    final compareCount = provider.compareComponents.length;

    // PopScope предотвращает выход из приложения кнопкой/жестом назад
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Каталог',
                    selected: selectedIndex == 0,
                    onTap: () => context.go('/'),
                  ),
                  _NavItem(
                    icon: Icons.build_rounded,
                    label: 'Сборка',
                    selected: selectedIndex == 1,
                    badge: buildCount > 0 ? buildCount.toString() : null,
                    onTap: () => context.go('/builder'),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: 'Поиск',
                    selected: selectedIndex == 2,
                    onTap: () => context.go('/search'),
                  ),
                  _NavItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Сборки',
                    selected: selectedIndex == 3,
                    badge: provider.savedBuilds.isNotEmpty
                        ? provider.savedBuilds.length.toString()
                        : null,
                    onTap: () => context.go('/builds'),
                  ),
                  if (compareCount > 0)
                    _NavItem(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Сравнить',
                      selected: false,
                      badge: compareCount.toString(),
                      onTap: () => context.push('/compare'),
                      color: AppTheme.accent,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;
  final Color? color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    final iconColor = selected ? activeColor : const Color(0xFF9CA3AF);
    final textColor = selected ? activeColor : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
