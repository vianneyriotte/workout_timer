import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _enabled = true;
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
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
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
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      ),
    );

    // Set player to release mode to not hold audio focus
    await _player.setReleaseMode(ReleaseMode.release);

    _audioSessionConfigured = true;
  }

  Future<void> _playVoice(String filename) async {
    await _playAsset('audio/voice/$filename.m4a');
  }

  Future<void> announceHalfway() async {
    await _playVoice('halfway');
  }

  Future<void> announceTenSeconds() async {
    await _playVoice('ten_seconds');
  }

  Future<void> announceSegmentStart(String segmentType) async {
    final filename = switch (segmentType) {
      "AMRAP, Let's go!" => 'amrap',
      "For Time, Let's go!" => 'for_time',
      "EMOM, Let's go!" => 'emom',
      "Tabata, Let's go!" => 'tabata',
      "Tempo, Let's go!" => 'tempo',
      'Rest' => 'rest',
      _ => null,
    };
    if (filename != null) {
      await _playVoice(filename);
    }
  }

  Future<void> announceEmomRound(int round) async {
    if (round >= 1 && round <= 30) {
      await _playVoice('round_$round');
    }
  }

  Future<void> announceWorkoutComplete() async {
    await _playVoice('time');
  }

  Future<void> speakNumber(int number) async {
    final filename = switch (number) {
      0 => 'zero',
      1 => 'one',
      2 => 'two',
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
      10 => 'ten',
      _ => null,
    };
    if (filename != null) {
      await _playVoice(filename);
    }
  }

  Future<void> announceTempoRound(int round) async {
    if (round >= 1 && round <= 30) {
      await _playVoice('round_$round');
    }
  }

  Future<void> announceTempoRep(int rep) async {
    if (rep >= 1 && rep <= 30) {
      await _playVoice('rep_$rep');
    }
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
  }

  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
