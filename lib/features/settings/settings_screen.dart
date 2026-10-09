import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import 'key_form.dart';

/// Settings (spec D-5).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ProviderCatalog? _catalog;
  ProviderId _provider = ProviderId.gemini;
  String? _model;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(summaryServiceProvider);
    final fallbacks = await service.refreshCatalog();
    final catalog = await service.catalog();
    final provider = await service.settings.activeProvider();
    final model = await service.effectiveModel(provider);
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _provider = provider;
      _model = model;
    });
    for (final f in fallbacks) {
      if (!mounted) break;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Modèle ${f.from} indisponible, ${f.to} utilisé.')));
    }
  }

  Future<void> _selectProvider(ProviderId provider) async {
    final service = ref.read(summaryServiceProvider);
    await service.settings.setActiveProvider(provider);
    final model = await service.effectiveModel(provider);
    if (mounted) {
      setState(() {
        _provider = provider;
        _model = model;
      });
    }
  }

  Future<void> _selectModel(String? modelId) async {
    if (modelId == null) return;
    await ref.read(settingsProvider).setModel(_provider, modelId);
    if (mounted) setState(() => _model = modelId);
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique ?'),
        content: const Text('Tous les résumés enregistrés sur ce téléphone seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Effacer')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(historyProvider.notifier).clearAll();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Historique effacé')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return Scaffold(
      appBar: AppBar(title: Text('Réglages', style: context.text.titleScreen)),
      body: catalog == null
          ? const SizedBox.shrink()
          : ReadableWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xs, Tokens.gutter, Tokens.xl),
                children: [
                  Text('Fournisseur IA', style: context.text.label),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ProviderId>(
                      showSelectedIcon: false,
                      segments: [
                        for (final p in ProviderId.values)
                          ButtonSegment(value: p, label: Text(p.label)),
                      ],
                      selected: {_provider},
                      onSelectionChanged: (s) => _selectProvider(s.first),
                    ),
                  ),
                  const SizedBox(height: Tokens.lg),
                  KeyForm(
                    provider: _provider,
                    catalogProvider: catalog.provider(_provider),
                    onSaved: (_) {},
                  ),
                  const SizedBox(height: Tokens.lg),
                  Text('Modèle', style: context.text.label),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_provider),
                    initialValue: _model,
                    items: [
                      for (final m in catalog.provider(_provider).models)
                        DropdownMenuItem(value: m.id, child: Text(m.name)),
                    ],
                    onChanged: _selectModel,
                  ),
                  const SizedBox(height: Tokens.xl),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Effacer l\'historique',
                        style: context.text.body.copyWith(color: context.scheme.error)),
                    onTap: _clearHistory,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Version 1.0.0', style: context.text.meta),
                  ),
                ],
              ),
            ),
    );
  }
}
