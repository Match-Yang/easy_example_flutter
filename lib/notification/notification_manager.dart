// Dart imports:
import 'dart:async';
import 'dart:math' as math;
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Project imports:
import '../bloc/call_bloc.dart';
import '../firebase_options.dart';
import 'notification_ring.dart';

const firebaseChannelGroupName = 'firebase_channel_group';
const firebaseChannelKey = 'firebase_channel';

class NotificationManager {
  static var shared = NotificationManager();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
        // set the icon to null if you want to use the default app icon
        '',
        [
          NotificationChannel(
              channelGroupKey: firebaseChannelGroupName,
              channelKey: firebaseChannelKey,
              channelName: 'Firebase notifications',
              channelDescription: 'Notification channel for firebase',
              defaultColor: const Color(0xFF9D50DD),
              playSound: true,
              enableVibration: true,
              vibrationPattern: lowVibrationPattern,
              onlyAlertOnce: false,
              ledColor: Colors.white)
        ],
        // Channel groups are only visual and are not required
        channelGroups: [
          NotificationChannelGroup(
              channelGroupkey: firebaseChannelGroupName,
              channelGroupName: 'Firebase group')
        ]);

    NotificationRing.shared.init();
  }

  void uninit() async {
    NotificationRing.shared.uninit();
  }

  Future<void> requestNotificationPermission() async {
    requestFirebaseMessagePermission();
    requestAwesomeNotificationsPermission();

    FirebaseMessaging.onBackgroundMessage(onFirebaseBackgroundMessage);

    listenAwesomeNotification();
  }

  void requestFirebaseMessagePermission() async {
    // 1. Instantiate Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();
    log("FCM Token $token");

    // 2. On iOS, this helps to take the user permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 3. Grant permission, for iOS only, Android ignore by default
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');

      // For handling the received notifications
      FirebaseMessaging.onMessage.listen(onFirebaseForegroundMessage);
    } else {
      assert(false);
      log('User declined or has not accepted permission');
    }
  }

  void requestAwesomeNotificationsPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        log('requestPermissionToSendNotifications');

        AwesomeNotifications()
            .requestPermissionToSendNotifications()
            .then((bool hasPermission) {
          log('User granted permission: $hasPermission');
        });
      }
    });
  }

  void listenAwesomeNotification() {
    //  BEFORE!! MaterialApp widget, starts to listen the notification actions
    AwesomeNotifications()
        .actionStream
        .listen((ReceivedNotification receivedAction) {
      if (receivedAction.channelKey != firebaseChannelKey) {
        log('unknown channel key');
        return;
      }

      // var model = ZegoNotificationModel.fromMap(
      //     receivedAction.payload ?? <String, String>{});
      // log('receive:${model.toMap()}');

      //  dispatch notification message
      // var caller = ZegoUserInfo(model.callerID, model.callerName);
      // var callType =
      //     ZegoCallTypeExtension.mapValue[int.parse(model.callTypeID)] ??
      //         ZegoCallType.kZegoCallTypeVoice;
      // ZegoServiceManager.shared.callService.delegate
      //     ?.onReceiveCallInvite(caller, callType);
      //  do nothing! cause can't receive call cancel
    });
  }

  Future<void> onFirebaseForegroundMessage(RemoteMessage message) async {
    // for more reliable and faster notification in foreground,
    // use listener in firebase manager

    log('Got a message whilst in the foreground!');
    log('Message data: ${message.data}');

    if (message.notification != null) {
      log('Message also contained a notification: ${message.notification}');
    }

    CallBloc.shared.add(CallReceiveInvited(
        message.data['callerUserID'],
        message.data['callerUserName'],
        message.data['callerIconUrl'],
        message.data['roomID']));
  }

  Future<void> onFirebaseRemoteMessageReceive(RemoteMessage message) async {
    log('remote message receive: ${message.data}');

    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: math.Random().nextInt(2147483647),
            groupKey: firebaseChannelGroupName,
            channelKey: firebaseChannelKey,
            title: "You have a new call",
            body: "xxx is calling you.",
            largeIcon: 'https://img.icons8.com/color/48/000000/avatar.png',
            payload: {"aa": "bb"},
            notificationLayout: NotificationLayout.Default));
  }
}

// Declared as global, outside of any class
Future<void> onFirebaseBackgroundMessage(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  NotificationManager.shared.onFirebaseRemoteMessageReceive(message);
}
