import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../data/summary_service.dart';

const privacyNote =
    'Ta clé est enregistrée uniquement sur ce téléphone et n\'est envoyée qu\'à '
    'ton fournisseur IA.';

/// API key field + « Obtenir une clé » + save with automatic validation
/// (spec D-5). Shared by the settings and the first-run setup.
class KeyForm extends ConsumerStatefulWidget {
  const KeyForm({
    super.key,
    required this.provider,
    required this.catalogProvider,
    required this.onSaved,
    this.buttonLabel = 'Enregistrer',
  });

  final ProviderId provider;
  final CatalogProvider catalogProvider;
  final ValueChanged<KeySaveResult> onSaved;
  final String buttonLabel;

  @override
  ConsumerState<KeyForm> createState() => _KeyFormState();
}

class _KeyFormState extends ConsumerState<KeyForm> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _hasStoredKey = false;
  KeySaveResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() => setState(() => _result = null));
  }

  @override
  void didUpdateWidget(KeyForm old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) _load();
  }

  Future<void> _load() async {
    final stored = await ref.read(keyStoreProvider).read(widget.provider);
    if (!mounted) return;
    setState(() {
      _controller.text = stored ?? '';
      _hasStoredKey = stored != null;
      _result = null;
      _obscure = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _patternMismatch {
    final value = _controller.text.trim();
    if (value.isEmpty) return false;
    try {
      return !RegExp(widget.catalogProvider.keyPattern).hasMatch(value);
    } on FormatException {
      return false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result =
        await ref.read(summaryServiceProvider).saveKey(widget.provider, _controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = result;
      if (result == KeySaveResult.valid || result == KeySaveResult.unverified) {
        _hasStoredKey = true;
      }
    });
    widget.onSaved(result);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la clé ${widget.provider.label} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(keyStoreProvider).delete(widget.provider);
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _hasStoredKey = false;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final colors = context.colors;
    final label = widget.provider.label;
    final (resultText, resultColor) = switch (_result) {
      KeySaveResult.valid => ('✓ Clé valide', colors.positive),
      KeySaveResult.refused => ('✗ Clé refusée par $label', scheme.error),
      KeySaveResult.unverified => ('Enregistrée, non vérifiée', scheme.onSurfaceVariant),
      KeySaveResult.empty => ('Colle ta clé avant d\'enregistrer', scheme.error),
      null => (null, null),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clé API $label', style: context.text.label),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          style: context.text.body,
          decoration: InputDecoration(
            hintText: 'Colle ta clé ici',
            hintStyle: context.text.bodyMuted,
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: _obscure ? 'Afficher la clé' : 'Masquer la clé',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              if (_hasStoredKey)
                IconButton(
                  tooltip: 'Supprimer la clé',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        if (_patternMismatch)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Ce format ne ressemble pas à une clé $label.',
                style: context.text.caption),
          ),
        Text(privacyNote, style: context.text.caption),
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => launchUrl(Uri.parse(widget.catalogProvider.keyHelpUrl),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text('Obtenir une clé $label'),
        ),
        const SizedBox(height: Tokens.xs),
        Row(
          children: [
            Expanded(
              child: resultText == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      liveRegion: true,
                      child: Text(resultText,
                          style: context.text.label.copyWith(color: resultColor)),
                    ),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.buttonLabel),
            ),
          ],
        ),
      ],
    );
  }
}
