// Dart imports:
import 'dart:async';
import 'dart:developer';

// Package imports:
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

// Project imports:

const String callRingName = 'audio/CallRing.wav';

class NotificationRing {
  NotificationRing._internal();
  factory NotificationRing() => shared;
  static late final NotificationRing shared = NotificationRing._internal();

  bool isRingTimerRunning = false;
  AudioPlayer? audioPlayer;

  void init() {
    audioPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  }

  void uninit() async {
    stopRing();

    await audioPlayer?.dispose();
    audioPlayer = null;
  }

  void startRing() async {
    assert(audioPlayer != null);
    if (isRingTimerRunning) {
      log('ring is running');
      return;
    }
    isRingTimerRunning = true;
    audioPlayer!.play(AssetSource(callRingName));
    Vibrate.vibrate();
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (!isRingTimerRunning) {
        audioPlayer!.stop();
        timer.cancel();
      } else {
        Vibrate.vibrate();
      }
    });
  }

  void stopRing() async {
    assert(audioPlayer != null);
    isRingTimerRunning = false;
    audioPlayer!.stop();
  }
}
