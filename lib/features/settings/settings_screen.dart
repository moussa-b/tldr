import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import 'key_form.dart';
import '../../l10n/l10n.dart';
import '../../l10n/app_language.dart';
import 'language_picker.dart';

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
          content: Text(context.l10n.settingsModelFallback(f.from, f.to))));
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
        title: Text(context.l10n.settingsClearTitle),
        content: Text(context.l10n.settingsClearBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.settingsCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.settingsClear)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(historyProvider.notifier).clearAll();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.settingsCleared)));
    }
  }

  Future<void> _chooseLanguage() async {
    final chosen = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: LanguagePicker(
          selected: ref.read(appLanguageProvider),
          onSelected: (language) => Navigator.pop(sheet, language),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await ref.read(appLanguageProvider.notifier).set(chosen);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorGenericTitle)));
      }
    }
  }

  String _languageLabel(AppLanguage language) => switch (language) {
        FixedLanguage(:final locale) => LanguagePicker.nameOf(locale),
        SystemLanguage() => context.l10n.settingsDeviceLanguage,
      };

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final l = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle, style: context.text.titleScreen)),
      body: catalog == null
          ? const SizedBox.shrink()
          : ReadableWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.xs, Tokens.gutter, Tokens.xl),
                children: [
                  Text(l.settingsProvider, style: context.text.label),
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
                  Text(l.settingsModel, style: context.text.label),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_provider),
                    initialValue: _model,
                    // Long model names are cut rather than overflowing a narrow phone.
                    isExpanded: true,
                    items: [
                      for (final m in catalog.provider(_provider).models)
                        DropdownMenuItem(
                            value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: _selectModel,
                  ),
                  const SizedBox(height: Tokens.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsLanguage, style: context.text.label),
                    subtitle: Text(_languageLabel(ref.watch(appLanguageProvider)),
                        style: context.text.body),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseLanguage,
                  ),
                  const SizedBox(height: Tokens.md),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsClearHistory,
                        style: context.text.body.copyWith(color: context.scheme.error)),
                    onTap: _clearHistory,
                  ),
                  if (version != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.settingsVersion(version), style: context.text.meta),
                    ),
                ],
              ),
            ),
    );
  }
}
