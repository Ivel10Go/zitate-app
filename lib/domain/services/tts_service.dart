import 'package:flutter_tts/flutter_tts.dart';

import '../../data/models/quote.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  Future<void> Function()? onPlaybackCompleted;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      onPlaybackCompleted?.call();
    });

    _tts.setCancelHandler(() {
      _isPlaying = false;
      onPlaybackCompleted?.call();
    });
  }

  bool get isPlaying => _isPlaying;

  Future<void> speak(String text) async {
    if (_isPlaying) {
      await stop();
    }
    _isPlaying = true;
    final clean = text
        .replaceAll('„', '')
        .replaceAll('"', '')
        .replaceAll('“', '');
    await _tts.speak(clean);
  }

  Future<void> speakQuote(Quote quote) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;
    await _tts.speak('${quote.source}, ${quote.year}.');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final quoteText = quote.textEn ?? quote.textDe;
    await _tts.speak(
      quoteText.replaceAll('„', '').replaceAll('"', '').replaceAll('"', ''),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await _tts.speak(quote.explanationShort);
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
