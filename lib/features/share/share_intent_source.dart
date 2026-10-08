import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Text shared to the app from another app (Reddit's share sheet).
abstract interface class ShareIntentSource {
  /// Text that launched the app, if any.
  Future<String?> initial();

  /// Texts shared while the app is running.
  Stream<String> get stream;
}

class PluginShareIntentSource implements ShareIntentSource {
  static String? _text(List<SharedMediaFile> files) {
    for (final f in files) {
      if (f.type == SharedMediaType.text || f.type == SharedMediaType.url) {
        return f.message == null || f.message!.isEmpty ? f.path : '${f.message} ${f.path}';
      }
    }
    return null;
  }

  @override
  Future<String?> initial() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    final text = _text(files);
    if (text != null) ReceiveSharingIntent.instance.reset();
    return text;
  }

  @override
  Stream<String> get stream => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(_text)
      .where((t) => t != null)
      .cast<String>();
}

/// Test double.
class FakeShareIntentSource implements ShareIntentSource {
  FakeShareIntentSource({this.initialText});

  final String? initialText;
  final _controller = StreamController<String>.broadcast();

  void share(String text) => _controller.add(text);

  @override
  Future<String?> initial() async => initialText;

  @override
  Stream<String> get stream => _controller.stream;
}
