// Dart imports:
import 'dart:async';
import 'dart:developer';

// Package imports:
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

// Project imports:

const String callRingName = 'CallRing.wav';

class NotificationRing {
  static var shared = NotificationRing();

  bool isRingTimerRunning = false;
  AudioPlayer? audioPlayer;
  late AudioCache audioCache;

  void init() {
    audioCache = AudioCache(
      prefix: 'assets/audio/',
      fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP),
    );
  }

  void uninit() async {
    stopRing();

    await audioCache.clearAll();
  }

  void startRing() async {
    if (isRingTimerRunning) {
      log('ring is running');
      return;
    }

    log('start ring');

    isRingTimerRunning = true;

    await audioCache.loop(callRingName).then((player) => audioPlayer = player);
    Vibrate.vibrate();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      log('ring timer periodic');
      if (!isRingTimerRunning) {
        log('ring timer ended');

        audioPlayer?.stop();

        timer.cancel();
      } else {
        Vibrate.vibrate();
      }
    });
  }

  void stopRing() async {
    log('stop ring');

    isRingTimerRunning = false;

    audioPlayer?.stop();
  }
}
