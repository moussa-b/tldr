import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Centred column capped at 640 dp (spec D-19).
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Tokens.maxContentWidth),
          child: child,
        ),
      );
}

/// « TL;DR+ » with the « + » in Reddit orange (DESIGN.md).
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'TL;DR+',
        excludeSemantics: true,
        child: Text.rich(TextSpan(
          style: context.text.wordmark,
          children: [
            const TextSpan(text: 'TL;DR'),
            TextSpan(text: '+', style: TextStyle(color: context.colors.accent)),
          ],
        )),
      );
}

/// 6 dp orange square before every r/sub: « the door back to the noise ».
class RedditMark extends StatelessWidget {
  const RedditMark({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(width: 6, height: 6, color: context.colors.accent),
      );
}

class NsfwBadge extends StatelessWidget {
  const NsfwBadge({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Contenu adulte',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: context.scheme.error,
            borderRadius: BorderRadius.circular(Tokens.rXs),
          ),
          child: Text('NSFW',
              style: context.text.caption.copyWith(
                  color: context.scheme.onError,
                  fontWeight: FontWeight.w500,
                  fontSize: 11)),
        ),
      );
}

/// `r/sub · <trailing>` with the orange mark and optional NSFW badge.
class SubredditMeta extends StatelessWidget {
  const SubredditMeta({
    super.key,
    required this.subreddit,
    required this.trailing,
    this.nsfw = false,
    this.style,
  });

  final String subreddit;
  final String trailing;
  final bool nsfw;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? context.text.meta;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        const RedditMark(),
        Text('r/$subreddit', style: textStyle),
        if (nsfw) const NsfwBadge(),
        if (trailing.isNotEmpty) Text('· $trailing', style: textStyle),
      ],
    );
  }
}

/// Section title + content with the spacing rhythm of DESIGN.md.
class Section extends StatelessWidget {
  const Section({super.key, required this.label, required this.child, this.top = Tokens.section});

  final String label;
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(label, style: context.text.sectionLabel)),
            const SizedBox(height: Tokens.xs),
            child,
          ],
        ),
      );
}

/// Durations collapse to zero when the system asks to reduce motion (D-16).
Duration motion(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: milliseconds);
