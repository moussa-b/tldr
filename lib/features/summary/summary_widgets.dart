import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/errors.dart';
import '../../core/labels.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../l10n/l10n.dart';

/// One-line verdict (spec D-15).
class VerdictLine extends StatefulWidget {
  const VerdictLine({super.key, required this.analysis});

  final Analysis analysis;

  @override
  State<VerdictLine> createState() => _VerdictLineState();
}

class _VerdictLineState extends State<VerdictLine> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final l = context.l10n;
    final colors = context.colors;
    final scheme = context.scheme;
    final style = context.text.verdict;
    final sentimentColor = switch (a.sentiment) {
      Sentiment.positive => colors.positive,
      Sentiment.negative => colors.negative,
      Sentiment.neutral => scheme.outline,
    };
    final shown = _expanded ? a.emotions : a.emotions.take(2).toList();
    final hidden = a.emotions.length - shown.length;
    final level = toxicityLevel(a.toxicity);
    final toxColor = switch (level) {
      ToxicityLevel.high => scheme.error,
      ToxicityLevel.moderate => scheme.onSurface,
      _ => scheme.onSurfaceVariant,
    };
    final dot = Text(' · ', style: style.copyWith(color: scheme.onSurfaceVariant));
    String emotion(String e) => emotionLabel(e, l);
    final semantics = l.summaryVerdictSemantics(sentimentLabel(a.sentiment, l).toLowerCase(),
        a.emotions.map(emotion).join(', '), toxicityLabel(a.toxicity, l));

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: sentimentColor, shape: BoxShape.circle),
          ),
          Text(sentimentLabel(a.sentiment, l), style: style.copyWith(color: sentimentColor)),
          dot,
          Text(shown.map(emotion).join(', '), style: style),
          if (hidden > 0)
            InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(Tokens.rXs),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                // Factors of 1: a bare Center would fill the Wrap's whole line.
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(' +$hidden',
                      style: style.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
            ),
          dot,
          Text(toxicityLabel(a.toxicity, l), style: style.copyWith(color: toxColor)),
        ],
      ),
    );
  }
}

/// « Points de vue », collapsed to 6 lines with « Lire plus » (spec D-1).
class ExpandableText extends StatefulWidget {
  const ExpandableText({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 6,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: motion(context, 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : 6,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
            ),
          ),
          if (overflows)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? context.l10n.summaryReadLess : context.l10n.summaryReadMore),
            ),
        ],
      );
    });
  }
}

/// Loading state (spec D-6): step label, skeleton, long-wait hint, Annuler.
class SummaryLoading extends StatefulWidget {
  const SummaryLoading({super.key, required this.subreddit, required this.onCancel});

  final String? subreddit;
  final VoidCallback onCancel;

  @override
  State<SummaryLoading> createState() => _SummaryLoadingState();
}

class _SummaryLoadingState extends State<SummaryLoading>
    with SingleTickerProviderStateMixin {
  late final Stopwatch _watch = Stopwatch()..start();
  late final Timer _ticker;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _watch.elapsed.inSeconds;
    final l = context.l10n;
    final step = seconds < 3 ? l.summaryFetchingStep : l.summaryAnalyzingStep;
    final scheme = context.scheme;
    Widget bar(double widthFactor, {double height = 14}) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Tokens.rXs),
            ),
          ),
        );

    return Semantics(
      label: l.summaryInProgress,
      liveRegion: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xs, Tokens.gutter, Tokens.xl),
        children: [
          Row(children: [
            const RedditMark(),
            const SizedBox(width: 6),
            Text(widget.subreddit == null ? l.summaryRedditThread : 'r/${widget.subreddit}',
                style: context.text.meta),
          ]),
          const SizedBox(height: Tokens.sm),
          AnimatedSwitcher(
            duration: motion(context, 250),
            child: Text(step, key: ValueKey(step), style: context.text.bodyMuted),
          ),
          if (seconds >= 15)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.xxs),
              child: Text(l.summaryLongWait,
                  style: context.text.meta),
            ),
          const SizedBox(height: Tokens.lg),
          ExcludeSemantics(
            child: FadeTransition(
              opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(0.9, height: 22),
                  bar(0.6, height: 22),
                  const SizedBox(height: Tokens.lg),
                  bar(0.3),
                  for (final f in [1.0, 0.96, 0.98, 0.9, 0.7]) bar(f, height: 18),
                  const SizedBox(height: Tokens.sm),
                  bar(0.55),
                  const SizedBox(height: Tokens.section),
                  bar(0.3),
                  for (final f in [1.0, 0.94, 0.97]) bar(f),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: widget.onCancel, child: Text(l.summaryCancel)),
          ),
        ],
      ),
    );
  }
}

/// Full-screen error state (spec D-7).
class SummaryErrorView extends StatefulWidget {
  const SummaryErrorView({
    super.key,
    required this.error,
    required this.providerLabel,
    required this.onRetry,
    required this.onSettings,
    required this.onHome,
  });

  final ApiError error;

  /// The AI provider's name; a generic one when unknown.
  final String? providerLabel;
  final VoidCallback onRetry;
  final VoidCallback onSettings;
  final VoidCallback onHome;

  @override
  State<SummaryErrorView> createState() => _SummaryErrorViewState();
}

class _SummaryErrorViewState extends State<SummaryErrorView> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.error.hasCountdown) {
      _remaining = widget.error.retryAfterSeconds ?? 120;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _remaining--);
        if (_remaining <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final l = context.l10n;
    final copy = errorCopy(error, l, providerLabel: widget.providerLabel);
    final icon = switch (error.code) {
      'NETWORK_ERROR' => Icons.wifi_off_outlined,
      'LLM_QUOTA_EXCEEDED' || 'TIMEOUT' => Icons.hourglass_empty,
      'LLM_KEY_INVALID' || 'LLM_KEY_MISSING' => Icons.key_off_outlined,
      _ => Icons.error_outline,
    };

    final Widget primary;
    if (error.isKeyProblem || error.code == 'UNSUPPORTED_MODEL') {
      primary = FilledButton(onPressed: widget.onSettings, child: Text(l.summaryOpenSettings));
    } else if (error.hasCountdown && _remaining > 0) {
      primary = FilledButton(onPressed: null, child: Text(l.summaryRetryIn(_clock(_remaining))));
    } else if (error.retryable) {
      primary = FilledButton(onPressed: widget.onRetry, child: Text(l.summaryRetry));
    } else {
      primary = FilledButton(onPressed: widget.onHome, child: Text(l.summaryBackHome));
    }
    final showHome = error.retryable || error.isKeyProblem;

    return Semantics(
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.gutter),
          child: ReadableWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: context.scheme.onSurfaceVariant),
                const SizedBox(height: Tokens.md),
                Text(copy.title,
                    style: context.text.titleScreen, textAlign: TextAlign.center),
                const SizedBox(height: Tokens.xs),
                Text(copy.body, style: context.text.bodyMuted, textAlign: TextAlign.center),
                const SizedBox(height: Tokens.lg),
                primary,
                if (showHome)
                  TextButton(onPressed: widget.onHome, child: Text(l.summaryBackHome)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
