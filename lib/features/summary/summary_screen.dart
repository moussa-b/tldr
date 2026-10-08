import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/errors.dart';
import '../../core/labels.dart';
import '../../core/reddit_url.dart';
import '../../core/widgets/common.dart';
import '../../data/api/tldr_api.dart';
import '../../data/db/summaries_dao.dart';
import '../../data/models/models.dart';
import '../../data/settings/settings_repository.dart';
import 'summary_widgets.dart';

enum SummaryMode { entry, create, demo }

/// Summary screen (spec D-1, D-6 to D-10, D-15).
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen.entry({super.key, required String this.entryId})
      : mode = SummaryMode.entry,
        url = null,
        resume = false;

  const SummaryScreen.create({super.key, required String this.url, this.resume = false})
      : mode = SummaryMode.create,
        entryId = null;

  const SummaryScreen.demo({super.key})
      : mode = SummaryMode.demo,
        entryId = null,
        url = null,
        resume = false;

  final SummaryMode mode;
  final String? entryId;
  final String? url;

  /// Replays the pending request (eng review R2, spec D-20).
  final bool resume;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  SummaryEntry? _entry;
  ApiError? _error;
  bool _loading = false;
  bool _regenerating = false;
  bool _translating = false;
  String? _translationError;
  DateTime? _duplicateOf;
  String _modelName = '';
  ApiCancelToken? _cancelToken;
  ProviderId? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    switch (widget.mode) {
      case SummaryMode.entry:
        final entry = await ref.read(summariesDaoProvider).getById(widget.entryId!);
        if (!mounted) return;
        if (entry == null) {
          context.go('/');
          return;
        }
        _show(entry);
      case SummaryMode.demo:
        final raw = await rootBundle.loadString('assets/fixtures/api/summary_fr.json');
        final result = SummaryResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _show(SummaryEntry(
          id: 'demo',
          sourceUrl: result.thread.permalink,
          thread: result.thread,
          provider: result.meta.provider,
          model: result.meta.model,
          analysis: result.analysis,
          analysisFr: null,
          displayLang: 'orig',
          commentsAnalyzed: result.meta.commentsAnalyzed,
          commentsTotal: result.meta.commentsTotal,
          createdAt: DateTime.now(),
        ));
      case SummaryMode.create:
        await _create();
    }
  }

  Future<void> _create() async {
    final service = ref.read(summaryServiceProvider);
    final url = widget.url!;
    PendingSummary? pending;
    if (widget.resume) {
      pending = await service.freshPending();
    } else {
      final existing = await service.findExisting(url);
      if (!mounted) return;
      if (existing != null) {
        _duplicateOf = existing.createdAt;
        _show(existing);
        return;
      }
    }
    if (pending == null && !await service.hasKeyForActiveProvider()) {
      if (!mounted) return;
      context.pushReplacement('/setup?url=${Uri.encodeQueryComponent(url)}');
      return;
    }
    final provider = pending?.provider ?? await service.settings.activeProvider();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _provider = provider;
    });
    _cancelToken = ApiCancelToken();
    try {
      final entry = await service.summarize(
        url,
        resume: pending,
        cancelToken: _cancelToken,
        onModelFallback: _announceFallbacks,
      );
      ref.read(historyProvider.notifier).reload();
      if (!mounted) return;
      setState(() => _loading = false);
      _show(entry);
    } on ApiError catch (e) {
      if (!mounted || e.code == 'CANCELLED') return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _announceFallbacks(List<dynamic> fallbacks) {
    if (!mounted || fallbacks.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Modèle indisponible : le modèle par défaut a été utilisé.')));
  }

  Future<void> _show(SummaryEntry entry) async {
    final name = await ref.read(summaryServiceProvider).modelName(entry.provider, entry.model);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _modelName = name;
    });
  }

  Future<void> _cancel() async {
    _cancelToken?.cancel();
    await ref.read(settingsProvider).clearPendingSummary();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _regenerate() async {
    final entry = _entry!;
    if (entry.analysisFr != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Régénérer ce résumé ?'),
          content: const Text('La traduction française sera supprimée.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(context, true), child: const Text('Régénérer')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _regenerating = true;
      _duplicateOf = null;
    });
    try {
      final updated = await ref.read(summaryServiceProvider).regenerate(entry);
      ref.read(historyProvider.notifier).reload();
      if (!mounted) return;
      setState(() => _regenerating = false);
      _show(updated);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _regenerating = false);
      _snack(errorCopy(e, providerLabel: entry.provider.label).title,
          retry: e.retryable ? _regenerate : null);
    }
  }

  Future<void> _translate() async {
    setState(() {
      _translating = true;
      _translationError = null;
    });
    try {
      final updated = await ref.read(summaryServiceProvider).translate(_entry!);
      if (!mounted) return;
      setState(() {
        _translating = false;
        _entry = updated;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _translating = false;
        _translationError = errorCopy(e, providerLabel: _entry!.provider.label).title;
      });
    }
  }

  Future<void> _setLang(String lang) async {
    final entry = _entry!;
    await ref.read(summariesDaoProvider).setDisplayLang(entry.id, lang);
    final updated = await ref.read(summariesDaoProvider).getById(entry.id);
    if (mounted && updated != null) setState(() => _entry = updated);
  }

  void _snack(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: retry == null ? null : SnackBarAction(label: 'Réessayer', onPressed: retry),
    ));
  }

  Future<void> _share() async {
    final entry = _entry!;
    final a = entry.displayed;
    await SharePlus.instance.share(ShareParams(
      text: '${entry.thread.title}\n\n${a.shortSummary}\n\n${entry.thread.permalink}\n— via TL;DR+',
      subject: entry.thread.title,
    ));
  }

  Future<void> _openReddit() async {
    final uri = Uri.parse(_entry!.thread.permalink);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _snack('Impossible d\'ouvrir Reddit');
    }
  }

  void _goHome() => context.go('/');

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final isDemo = widget.mode == SummaryMode.demo;
    return PopScope(
      canPop: !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _loading) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () {
            if (_loading) {
              _cancel();
            } else if (context.canPop()) {
              context.pop();
            } else {
              _goHome();
            }
          }),
          actions: [
            if (entry != null && !isDemo) ...[
              IconButton(
                tooltip: 'Partager le résumé',
                icon: const Icon(Icons.ios_share),
                onPressed: _share,
              ),
              IconButton(
                tooltip: 'Ouvrir dans Reddit',
                icon: const Icon(Icons.open_in_new),
                onPressed: _openReddit,
              ),
              PopupMenuButton<String>(
                tooltip: 'Plus d\'options',
                enabled: !_regenerating,
                onSelected: (_) => _regenerate(),
                itemBuilder: (_) =>
                    const [PopupMenuItem(value: 'regen', child: Text('Régénérer'))],
              ),
            ],
          ],
          bottom: _regenerating
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : null,
        ),
        body: _body(context, entry, isDemo),
      ),
    );
  }

  Widget _body(BuildContext context, SummaryEntry? entry, bool isDemo) {
    if (_error != null) {
      return SummaryErrorView(
        key: ValueKey(_error),
        error: _error!,
        providerLabel: _providerLabel(),
        onRetry: _create,
        onHome: _goHome,
        onSettings: () async {
          await context.push('/settings');
          if (mounted && await ref.read(summaryServiceProvider).hasKeyForActiveProvider()) {
            _create();
          }
        },
      );
    }
    if (_loading || entry == null) {
      return SummaryLoading(
        subreddit: widget.url == null ? null : extractSubreddit(widget.url!),
        onCancel: _cancel,
      );
    }
    return AnimatedSwitcher(
      duration: motion(context, 250),
      switchInCurve: Curves.easeOut,
      child: _SummaryContent(
        key: ValueKey('${entry.id}-${entry.createdAt.millisecondsSinceEpoch}-${entry.displayLang}'),
        entry: entry,
        modelName: _modelName,
        isDemo: isDemo,
        duplicateOf: _duplicateOf,
        onDismissDuplicate: () => setState(() => _duplicateOf = null),
        onRegenerate: _regenerate,
        translating: _translating,
        translationError: _translationError,
        onTranslate: _translate,
        onLang: _setLang,
      ),
    );
  }

  String _providerLabel() => (_entry?.provider ?? _provider)?.label ?? 'le fournisseur';
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    super.key,
    required this.entry,
    required this.modelName,
    required this.isDemo,
    required this.duplicateOf,
    required this.onDismissDuplicate,
    required this.onRegenerate,
    required this.translating,
    required this.translationError,
    required this.onTranslate,
    required this.onLang,
  });

  final SummaryEntry entry;
  final String modelName;
  final bool isDemo;
  final DateTime? duplicateOf;
  final VoidCallback onDismissDuplicate;
  final VoidCallback onRegenerate;
  final bool translating;
  final String? translationError;
  final VoidCallback onTranslate;
  final ValueChanged<String> onLang;

  @override
  Widget build(BuildContext context) {
    final a = entry.displayed;
    final t = context.text;
    final thread = entry.thread;
    return ListView(
      padding: const EdgeInsets.only(bottom: Tokens.xl),
      children: [
        if (isDemo)
          MaterialBanner(
            content: const Text('Exemple : ce résumé n\'utilise pas ta clé et n\'est pas enregistré.'),
            actions: [TextButton(onPressed: () => context.go('/'), child: const Text('Fermer'))],
          ),
        if (duplicateOf != null)
          MaterialBanner(
            content: Text('Déjà résumé ${_bannerDate(duplicateOf!)}'),
            actions: [
              TextButton(onPressed: onDismissDuplicate, child: const Text('Fermer')),
              TextButton(onPressed: onRegenerate, child: const Text('Régénérer')),
            ],
          ),
        ReadableWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Tokens.xs),
                SubredditMeta(
                  subreddit: thread.subreddit,
                  trailing: relativeDate(thread.createdAt),
                  nsfw: thread.isNsfw,
                ),
                const SizedBox(height: Tokens.xs),
                Semantics(
                  header: true,
                  label: thread.title,
                  excludeSemantics: true,
                  child: Text(thread.title,
                      style: t.titleThread, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
                if (entry.canTranslate && !isDemo) ...[
                  const SizedBox(height: Tokens.md),
                  _LanguageControl(
                    entry: entry,
                    translating: translating,
                    error: translationError,
                    onTranslate: onTranslate,
                    onLang: onLang,
                  ),
                ],
                Section(
                  label: 'En bref',
                  top: Tokens.md,
                  child: Text(a.shortSummary, style: t.readingLead),
                ),
                const SizedBox(height: Tokens.md),
                VerdictLine(analysis: a),
                Section(
                  label: 'Points de vue',
                  child: ExpandableText(
                      text: a.detailedSummary, style: t.readingBody),
                ),
                const SizedBox(height: Tokens.section),
                _AiTake(text: a.aiTake),
                const SizedBox(height: Tokens.xl),
                const Divider(),
                const SizedBox(height: Tokens.md),
                Text(
                  '${compactNumber(thread.score)} points · ${percent(thread.upvoteRatio)} upvotés · '
                  '${thread.numComments} commentaires',
                  style: t.caption,
                ),
                const SizedBox(height: Tokens.xxs),
                Text(
                  '${entry.commentsAnalyzed} commentaires analysés sur ${entry.commentsTotal} · $modelName',
                  style: t.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _bannerDate(DateTime date) {
    final label = relativeDate(date);
    return label.startsWith('il y a') || label == 'hier' || label == 'à l\'instant'
        ? label
        : 'le $label';
  }
}

class _AiTake extends StatelessWidget {
  const _AiTake({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Tokens.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tokens.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(children: [
              Icon(Icons.psychology_outlined, size: 18, color: scheme.onSurface),
              const SizedBox(width: 6),
              Text('L\'avis de l\'IA', style: context.text.sectionLabel),
            ]),
          ),
          const SizedBox(height: 6),
          Text(text, style: context.text.readingOpinion),
        ],
      ),
    );
  }
}

/// « Traduire en français », then « VO (EN) | FR » (spec D-9).
class _LanguageControl extends StatelessWidget {
  const _LanguageControl({
    required this.entry,
    required this.translating,
    required this.error,
    required this.onTranslate,
    required this.onLang,
  });

  final SummaryEntry entry;
  final bool translating;
  final String? error;
  final VoidCallback onTranslate;
  final ValueChanged<String> onLang;

  @override
  Widget build(BuildContext context) {
    final code = entry.analysis.language.toUpperCase();
    final Widget control;
    if (entry.analysisFr == null) {
      control = OutlinedButton.icon(
        onPressed: translating ? null : onTranslate,
        icon: translating
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.translate, size: 18),
        label: const Text('Traduire en français'),
      );
    } else {
      control = SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'orig', label: Text('VO ($code)')),
          const ButtonSegment(value: 'fr', label: Text('FR')),
        ],
        selected: {entry.displayLang},
        onSelectionChanged: (s) => onLang(s.first),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        control,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.xxs),
            child: Row(children: [
              Flexible(
                child: Text(error!,
                    style: context.text.meta.copyWith(color: context.scheme.error)),
              ),
              TextButton(onPressed: onTranslate, child: const Text('Réessayer')),
            ]),
          ),
      ],
    );
  }
}
