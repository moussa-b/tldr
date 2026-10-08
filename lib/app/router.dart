import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_screen.dart';
import '../features/summary/summary_screen.dart';

/// Routes (spec D-3). A share always opens on top of Home so back/Annuler
/// land on Home.
GoRouter buildRouter({GlobalKey<NavigatorState>? navigatorKey}) => GoRouter(
      navigatorKey: navigatorKey,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/summary/new',
          builder: (context, state) => SummaryScreen.create(
            url: state.uri.queryParameters['url'] ?? '',
            resume: state.uri.queryParameters['resume'] == '1',
          ),
        ),
        GoRoute(path: '/summary/demo', builder: (context, state) => const SummaryScreen.demo()),
        GoRoute(
          path: '/summary/:id',
          builder: (context, state) => SummaryScreen.entry(entryId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/setup',
          builder: (context, state) =>
              SetupScreen(pendingUrl: state.uri.queryParameters['url']),
        ),
      ],
    );

/// Opens a shared link: Home, then the summary on top.
void openSharedUrl(GoRouter router, String url) {
  router.go('/');
  router.push('/summary/new?url=${Uri.encodeQueryComponent(url)}');
}
