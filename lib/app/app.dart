import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors.dart';
import '../core/reddit_url.dart';
import '../features/share/share_intent_source.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Root widget: theme, router, share intents and resume of an interrupted
/// summary (spec D-3, D-20).
class TldrApp extends ConsumerStatefulWidget {
  const TldrApp({super.key, this.shareSource});

  final ShareIntentSource? shareSource;

  @override
  ConsumerState<TldrApp> createState() => _TldrAppState();
}

class _TldrAppState extends ConsumerState<TldrApp> {
  late final GoRouter _router = buildRouter();
  late final ShareIntentSource _share = widget.shareSource ?? PluginShareIntentSource();
  StreamSubscription<String>? _shareSub;
  AppLifecycleListener? _lifecycle;
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    _shareSub = _share.stream.listen(_onShared);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _share.initial();
      if (initial != null) {
        _onShared(initial);
      } else {
        _resumePending();
      }
    });
    _lifecycle = AppLifecycleListener(onResume: _resumePending);
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _lifecycle?.dispose();
    _router.dispose();
    super.dispose();
  }

  void _onShared(String text) {
    final url = extractRedditUrl(text);
    if (url == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Ce lien n\'est pas un thread Reddit')));
      return;
    }
    openSharedUrl(_router, url);
  }

  /// Spec D-20: show the resumed summary only on Home (or the same summary);
  /// elsewhere replay in the background and notify.
  Future<void> _resumePending() async {
    if (_resuming) return;
    final service = ref.read(summaryServiceProvider);
    final pending = await service.freshPending();
    if (pending == null) return;
    final location = _router.routerDelegate.currentConfiguration.uri.toString();
    if (location.startsWith('/summary/new')) return; // That screen owns the request.
    _resuming = true;
    try {
      if (location == '/') {
        _router.push('/summary/new?url=${Uri.encodeQueryComponent(pending.url)}&resume=1');
        return;
      }
      final entry = await service.summarize(pending.url, resume: pending);
      ref.read(historyProvider.notifier).reload();
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: const Text('Résumé prêt'),
        action: SnackBarAction(label: 'Voir', onPressed: () => _router.push('/summary/${entry.id}')),
      ));
    } on ApiError catch (e) {
      if (e.code != 'CANCELLED') {
        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: const Text('Le résumé a échoué'),
          action: SnackBarAction(
            label: 'Détails',
            onPressed: () => _router.push(
                '/summary/new?url=${Uri.encodeQueryComponent(pending.url)}'),
          ),
        ));
      }
    } finally {
      _resuming = false;
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'TL;DR+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: _router,
      );
}
