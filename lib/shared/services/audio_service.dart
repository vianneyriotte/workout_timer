import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SoundType {
  countdown,
  start,
  intervalChange,
  warning,
  complete,
  rest,
  work,
  tick,
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _enabled = true;
  bool _ttsInitialized = false;
  bool _audioSessionConfigured = false;

  bool get enabled => _enabled;

  set enabled(bool value) {
    _enabled = value;
  }

  /// Initialize the audio service. Call this early in app startup.
  Future<void> init() async {
    await _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    if (_audioSessionConfigured) return;

    // Set global audio context to mix with music and duck it
    AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );

    // Also set on player instance
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );

    // Set player to release mode to not hold audio focus
    await _player.setReleaseMode(ReleaseMode.release);

    _audioSessionConfigured = true;
  }

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Configure TTS to mix with other audio (iOS specific)
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );
    _ttsInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    await _initTts();
    await _tts.speak(text);
  }

  Future<void> announceHalfway() async {
    await speak('Halfway there');
  }

  Future<void> announceTenSeconds() async {
    await speak('Ten seconds');
  }

  Future<void> announceSegmentStart(String segmentType) async {
    await speak(segmentType);
  }

  Future<void> announceEmomRound(int round) async {
    await speak('Round $round');
  }

  Future<void> announceWorkoutComplete() async {
    await speak("Time!");
  }

  Future<void> speakNumber(int number) async {
    final word = switch (number) {
      0 => 'Zero',
      1 => 'One',
      2 => 'Two',
      3 => 'Three',
      4 => 'Four',
      5 => 'Five',
      6 => 'Six',
      7 => 'Seven',
      8 => 'Eight',
      9 => 'Nine',
      10 => 'Ten',
      _ => number.toString(),
    };
    await speak(word);
  }

  Future<void> announceTempoRound(int round) async {
    await speak('Round $round');
  }

  Future<void> announceTempoRep(int rep) async {
    await speak('Rep $rep');
  }

  Future<void> playSound(SoundType type) async {
    if (!_enabled) return;

    final soundFile = switch (type) {
      SoundType.countdown => 'audio/beep_long.mp3',
      SoundType.start => 'audio/beep_long.mp3',
      SoundType.intervalChange => 'audio/beep_long.mp3',
      SoundType.warning => 'audio/beep_long.mp3',
      SoundType.complete => 'audio/beep_long.mp3',
      SoundType.rest => 'audio/beep_long.mp3',
      SoundType.work => 'audio/beep_long.mp3',
      SoundType.tick => 'audio/beep_low.mp3',
    };

    await _playAsset(soundFile);
  }

  Future<void> playCountdownBeep() async {
    await playSound(SoundType.countdown);
  }

  Future<void> playStartBeep() async {
    await playSound(SoundType.start);
  }

  Future<void> playIntervalBeep() async {
    await playSound(SoundType.intervalChange);
  }

  Future<void> playWarningBeep() async {
    await playSound(SoundType.warning);
  }

  Future<void> playCompleteBeep() async {
    await playSound(SoundType.complete);
  }

  Future<void> playRestBeep() async {
    await playSound(SoundType.rest);
  }

  Future<void> playWorkBeep() async {
    await playSound(SoundType.work);
  }

  Future<void> playTickBeep() async {
    await playSound(SoundType.tick);
  }

  Future<void> _playAsset(String assetPath) async {
    if (!_enabled) return;

    try {
      await _configureAudioSession();
      await _player.stop();
      await _player.play(
        AssetSource(assetPath),
        volume: 1.0,
      );
    } catch (e) {
      // Fallback to URL sound if asset fails
      try {
        await _player.play(
          UrlSource(
            'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
          ),
          volume: 1.0,
        );
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }

  void dispose() {
    _player.dispose();
    _tts.stop();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
