import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Plays an emergency siren (audio + vibration) in short cycles.
///
/// Intended for "someone nearby needs help" alerts where you want an audible
/// buzzer that other people can notice, but that still auto-stops.
class EmergencyBuzzerService {
  EmergencyBuzzerService._();

  static final EmergencyBuzzerService instance = EmergencyBuzzerService._();

  static const int maxCycles = 5;
  static const Duration onDuration = Duration(seconds: 3);
  static const Duration offDuration = Duration(seconds: 5);

  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  int _cycle = 0;
  bool _active = false;

  bool get isActive => _active;
  int get cycle => _cycle;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _cycle = 0;

    try {
      await _player.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('EmergencyBuzzerService setReleaseMode error: $e');
    }

    _playOneCycle();
  }

  void _playOneCycle() {
    if (!_active || _cycle >= maxCycles) {
      stop();
      return;
    }

    _cycle++;

    try {
      _player.play(AssetSource('siren.mp3'));
    } catch (e) {
      debugPrint('EmergencyBuzzerService play error: $e');
    }

    Vibration.vibrate(pattern: const [0, 600, 200, 600, 200, 600]);

    _timer = Timer(onDuration, () async {
      try {
        await _player.stop();
      } catch (_) {}
      Vibration.cancel();

      if (!_active) return;
      _timer = Timer(offDuration, _playOneCycle);
    });
  }

  void stop() {
    _active = false;
    _cycle = 0;
    _timer?.cancel();
    _timer = null;
    try {
      _player.stop();
    } catch (_) {}
    Vibration.cancel();
  }

  void dispose() {
    stop();
    _player.dispose();
  }
}

