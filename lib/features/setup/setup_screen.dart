import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/summary_service.dart';
import '../settings/key_form.dart';

/// First-run setup in 2 steps (spec D-11). [pendingUrl] resumes a share.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.pendingUrl});

  final String? pendingUrl;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  ProviderCatalog? _catalog;
  ProviderId _provider = ProviderId.gemini;
  int _step = 1;
  bool _done = false;

  static const _subtitles = {
    ProviderId.gemini: 'Offre gratuite disponible',
    ProviderId.anthropic: 'Claude, par Anthropic',
    ProviderId.openai: 'GPT, par OpenAI',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(summaryServiceProvider);
    final catalog = await service.catalog();
    final provider = await service.settings.activeProvider();
    if (mounted) {
      setState(() {
        _catalog = catalog;
        _provider = provider;
      });
    }
  }

  Future<void> _continue() async {
    await ref.read(settingsProvider).setActiveProvider(_provider);
    if (mounted) setState(() => _step = 2);
  }

  Future<void> _onSaved(KeySaveResult result) async {
    if (result != KeySaveResult.valid && result != KeySaveResult.unverified) return;
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final url = widget.pendingUrl;
    if (url != null) {
      context.pushReplacement('/summary/new?url=${Uri.encodeQueryComponent(url)}');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _back() {
    if (_step == 2) {
      setState(() => _step = 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: _step == 1 ? const Wordmark() : null,
        ),
        body: catalog == null
            ? const SizedBox.shrink()
            : ReadableWidth(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xs, Tokens.gutter, Tokens.xl),
                  children: _step == 1 ? _stepOne(context) : _stepTwo(context, catalog),
                ),
              ),
      ),
    );
  }

  List<Widget> _stepOne(BuildContext context) => [
        Text('Étape 1 sur 2', style: context.text.meta),
        const SizedBox(height: Tokens.xs),
        Text('Résume n\'importe quel thread Reddit avec ta propre IA.',
            style: context.text.readingLead),
        const SizedBox(height: Tokens.xl),
        Text('Choisis ton fournisseur', style: context.text.sectionLabel),
        const SizedBox(height: Tokens.xs),
        RadioGroup<ProviderId>(
          groupValue: _provider,
          onChanged: (value) => setState(() => _provider = value ?? _provider),
          child: Column(children: [
            for (final p in ProviderId.values)
              RadioListTile<ProviderId>(
                value: p,
                contentPadding: EdgeInsets.zero,
                title: Text(p.label, style: context.text.body),
                subtitle: Text(_subtitles[p]!, style: context.text.meta),
              ),
          ]),
        ),
        const SizedBox(height: Tokens.lg),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: _continue, child: const Text('Continuer')),
        ),
      ];

  List<Widget> _stepTwo(BuildContext context, ProviderCatalog catalog) => [
        Text('Étape 2 sur 2', style: context.text.meta),
        const SizedBox(height: Tokens.xs),
        Text('Colle ta clé ${_provider.label}', style: context.text.titleScreen),
        const SizedBox(height: Tokens.lg),
        KeyForm(
          provider: _provider,
          catalogProvider: catalog.provider(_provider),
          buttonLabel: 'Vérifier',
          onSaved: _onSaved,
        ),
        if (_done) ...[
          const SizedBox(height: Tokens.lg),
          Semantics(
            liveRegion: true,
            child: Text('C\'est prêt ✓',
                style: context.text.titleScreen.copyWith(color: context.colors.positive)),
          ),
        ],
      ];
}
