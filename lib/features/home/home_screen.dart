import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/labels.dart';
import '../../core/reddit_url.dart';
import '../../core/widgets/common.dart';
import '../../data/db/summaries_dao.dart';
import '../../l10n/l10n.dart';

/// Home: wordmark, URL field, history (spec D-2, D-12, D-22).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// The first-run setup is pushed once per app launch (spec D-11).
  static bool setupShownThisLaunch = false;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  /// The field holds something that is not a Reddit thread link.
  bool _notAThread = false;
  bool _hasKey = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _notAThread = false));
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(historyProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkKey(firstRun: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _checkKey({bool firstRun = false}) async {
    final service = ref.read(summaryServiceProvider);
    final hasAny = await service.hasAnyKey();
    final hasActive = await service.hasKeyForActiveProvider();
    if (!mounted) return;
    setState(() => _hasKey = hasActive);
    if (firstRun && !hasAny && !HomeScreen.setupShownThisLaunch) {
      HomeScreen.setupShownThisLaunch = true;
      await context.push('/setup');
      if (mounted) _checkKey();
    }
  }

  void _submit([String? text]) {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty) return;
    final url = extractRedditUrl(value);
    if (url == null) {
      setState(() => _notAThread = true);
      return;
    }
    _controller.clear();
    FocusScope.of(context).unfocus();
    context.push('/summary/new?url=${Uri.encodeQueryComponent(url)}').then((_) => _checkKey());
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.homeClipboardEmpty)));
      return;
    }
    _controller.text = text;
    if (extractRedditUrl(text) != null) {
      _submit(text);
    } else {
      setState(() => _notAThread = true);
    }
  }

  Future<void> _delete(HistoryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final entry = await ref.read(historyProvider.notifier).remove(item.id);
    if (entry == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 5),
      content: Text(l.homeSummaryDeleted),
      action: SnackBarAction(
        label: l.homeUndo,
        onPressed: () => ref.read(historyProvider.notifier).restore(entry),
      ),
    ));
  }

  Future<void> _itemMenu(HistoryItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(context.l10n.homeShare),
            onTap: () => Navigator.pop(context, 'share'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: context.scheme.error),
            title: Text(context.l10n.homeDelete, style: TextStyle(color: context.scheme.error)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ]),
      ),
    );
    if (!mounted) return;
    final language = context.appLanguageCode;
    if (action == 'delete') await _delete(item);
    if (action == 'share') {
      final entry = await ref.read(summariesDaoProvider).getById(item.id);
      if (entry == null) return;
      await SharePlus.instance.share(ShareParams(
        text: '${entry.thread.title}\n\n${entry.displayedIn(language).shortSummary}\n\n'
            '${entry.thread.permalink}\n— via TL;DR+',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    // A key saved or deleted from any screen (setup on the way to a summary,
    // settings) updates the « add a key » banner.
    ref.listen(keyRevisionProvider, (_, _) => _checkKey());
    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(),
        actions: [
          IconButton(
            tooltip: context.l10n.homeSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings').then((_) => _checkKey()),
          ),
        ],
      ),
      body: ReadableWidth(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xxs, Tokens.gutter, 0),
              sliver: SliverToBoxAdapter(child: _urlField(context)),
            ),
            if (!_hasKey)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.md, Tokens.gutter, 0),
                  child: _KeyBanner(onTap: () => context.push('/setup').then((_) => _checkKey())),
                ),
              ),
            if (history.loading && history.items.isEmpty)
              const SliverToBoxAdapter(child: SizedBox.shrink())
            else if (history.items.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.lg, Tokens.gutter, Tokens.xxs),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                      header: true,
                      child: Text(context.l10n.homeRecent, style: context.text.sectionLabel)),
                ),
              ),
              SliverList.builder(
                itemCount: history.items.length + (history.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= history.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(Tokens.md),
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  final item = history.items[index];
                  return _HistoryRow(
                    item: item,
                    onTap: () => context.push('/summary/${item.id}'),
                    onDelete: () => _delete(item),
                    onLongPress: () => _itemMenu(item),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: Tokens.xl)),
          ],
        ),
      ),
    );
  }

  Widget _urlField(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Tokens.rSm),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: context.l10n.homePasteLink,
                icon: const Icon(Icons.content_paste),
                onPressed: _paste,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _submit(),
                  style: context.text.body,
                  decoration: InputDecoration(
                    hintText: context.l10n.homeUrlHint,
                    hintStyle: context.text.bodyMuted,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                ),
              ),
              if (_controller.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: Tokens.xxs),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHighest,
                      foregroundColor: scheme.onSurface,
                      minimumSize: const Size(48, 40),
                    ),
                    onPressed: _submit,
                    child: Text(context.l10n.homeSummarize),
                  ),
                ),
            ],
          ),
        ),
        if (_notAThread)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.xs),
            child: Semantics(
              liveRegion: true,
              child: Text(context.l10n.homeNotAThread,
                  style: context.text.caption.copyWith(color: scheme.error)),
            ),
          ),
      ],
    );
  }
}

class _KeyBanner extends StatelessWidget {
  const _KeyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tokens.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(Tokens.rMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Tokens.md),
            child: Row(children: [
              const Icon(Icons.key_outlined, size: 20),
              const SizedBox(width: Tokens.sm),
              Expanded(
                  child: Text(context.l10n.homeAddKey, style: context.text.label)),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.scheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Tokens.gutter),
        child: Icon(Icons.delete_outline, color: context.scheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: context.l10n.homeDelete): onDelete,
        },
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Tokens.md),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.scheme.outlineVariant)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: context.text.listTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: Tokens.xxs),
                        SubredditMeta(
                          subreddit: item.subreddit,
                          nsfw: item.isNsfw,
                          trailing:
                              '${relativeDate(item.createdAt, context.l10n)} · ${item.provider.label} · '
                              '${emotionLabel(item.topEmotion, context.l10n)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Tokens.sm),
                  Semantics(
                    label: context.l10n
                        .homeSentiment(sentimentLabel(item.sentiment, context.l10n).toLowerCase()),
                    excludeSemantics: true,
                    child: Text(sentimentEmoji(item.sentiment),
                        style: const TextStyle(fontSize: 18, height: 22 / 18)),
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

/// Teaches the share gesture (spec D-12).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isIos = !kIsWeb && Platform.isIOS;
    Widget step(IconData icon, String text) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          minLeadingWidth: 24,
          leading: Icon(icon, size: 22, color: context.scheme.onSurfaceVariant),
          title: Text(text, style: context.text.body),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xl, Tokens.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(context.l10n.homeEmptyTitle, style: context.text.titleScreen),
          ),
          const SizedBox(height: Tokens.sm),
          step(Icons.article_outlined, context.l10n.homeEmptyStep1),
          step(isIos ? Icons.ios_share : Icons.share_outlined, context.l10n.homeEmptyStep2),
          step(Icons.bolt_outlined, context.l10n.homeEmptyStep3),
          if (isIos)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.xxs),
              child: Text(
                context.l10n.homeEmptyIosHint,
                style: context.text.caption,
              ),
            ),
          const SizedBox(height: Tokens.md),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => context.push('/summary/demo'),
            child: Text(context.l10n.homeSeeExample),
          ),
        ],
      ),
    );
  }
}
