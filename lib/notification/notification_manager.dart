// Dart imports:
import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:developer';
import 'dart:ui';

// Flutter imports:
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

// Project imports:
import '../bloc/call_bloc.dart';
import '../firebase_options.dart';
import 'notification_ring.dart';

const firebaseChannelGroupKey = 'firebase_channel_group';
const firebaseChannelGroupName = 'Firebase group';
const firebaseChannelKey = 'firebase_channel';
const firebaseChannelName = 'Firebase notifications';
const firebasechannelDescription = 'Notification channel for firebase';
const backgroundIsolatePortName = 'notification_manager_isolate_port';

class NotificationManager {
  static var shared = NotificationManager();
  StreamSubscription<dynamic>? actionStreamSubscription;

  Future<void> init() async {
    log("notification manager init");

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(onFirebaseBackgroundMessage);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications. we don't need this
    // await FirebaseMessaging.instance
    //     .setForegroundNotificationPresentationOptions(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    NotificationRing.shared.init();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await AwesomeNotifications().initialize(
          // set the icon to null if you want to use the default app icon
          '',
          [
            NotificationChannel(
                channelGroupKey: firebaseChannelGroupKey,
                channelKey: firebaseChannelKey,
                channelName: firebaseChannelName,
                channelDescription: firebasechannelDescription,
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
                channelGroupkey: firebaseChannelGroupKey,
                channelGroupName: firebaseChannelGroupName)
          ]);
    }
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('FCM token: $token');

    listenAwesomeNotification();
  }

  void uninit() async {
    actionStreamSubscription?.cancel();

    NotificationRing.shared.uninit();
  }

  Future<void> requestNotificationPermission() async {
    requestFirebaseMessagePermission();

    if (defaultTargetPlatform == TargetPlatform.android) {
      requestAwesomeNotificationsPermission();
    }
  }

  void requestFirebaseMessagePermission() async {
    // 1. Instantiate Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();
    log("FCM Token $token");

    late NotificationSettings settings;
    try {
      // 2. On iOS, this helps to take the user permissions
      settings = await messaging.requestPermission(
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
      } else {
        assert(false);
        log('User declined or has not accepted permission');
      }
    } on Exception catch (error) {
      log("[ERROR], request firebase message permission exception, ${error.toString()}");
    }

    // For handling the received notifications
    FirebaseMessaging.onMessage.listen(onFirebaseForegroundMessage);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      FirebaseMessaging.onMessageOpenedApp.listen(onFirebaseOpenedAppMessage);
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          onFirebaseForegroundMessage(message);
        }
      });
    }
  }

  Future<void> requestAwesomeNotificationsPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      List<NotificationPermission> requestedPermissions = [
        NotificationPermission.Sound,
        NotificationPermission.FullScreenIntent,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
      ];

      try {
        await AwesomeNotifications()
            .checkPermissionList(
                channelKey: firebaseChannelKey,
                permissions: requestedPermissions)
            .then((List<NotificationPermission> permissions) async {
          var targetPermissions = List.from(requestedPermissions);
          targetPermissions.remove(NotificationPermission.FullScreenIntent);
          if (!Set.of(permissions).containsAll(Set.of(targetPermissions))) {
            await AwesomeNotifications().requestPermissionToSendNotifications(
              channelKey: firebaseChannelKey,
              permissions: requestedPermissions,
            );
          }
        });
      } on Exception catch (error) {
        log("[ERROR], request notification permission exception, ${error.toString()}");
      }
    }
  }

  void listenAwesomeNotification() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      actionStreamSubscription ??= AwesomeNotifications().actionStream.listen(onActionStream);
    }
  }

  void onActionStream(ReceivedNotification notification) {
    AndroidForegroundService.stopForeground();
    IsolateNameServer.lookupPortByName(backgroundIsolatePortName)
        ?.send("stop_ring");

    if (notification.channelKey != firebaseChannelKey) {
      log('unknown channel key');
      return;
    }
    if (notification is ReceivedAction) {
      var action = notification;
      switch (action.buttonKeyPressed) {
        case 'decline':
          CallBloc.shared.add(CallInviteDecline());
          return;
        case 'accept':
          CallBloc.shared.add(
            CallInviteAccept(
              notification.payload!['roomID']!,
              notification.payload!.containsKey("targetUserIDList"),
              true,
            ),
          );
          return;
        default:
          break;
      }
    }
    CallBloc.shared.add(CallReceiveInvited(
        notification.payload!['callerUserID']!,
        notification.payload!['callerUserName']!,
        notification.payload!['callerIconUrl']!,
        notification.payload!['roomID']!,
        notification.payload!.containsKey("targetUserIDList")));
  }

  Future<void> onFirebaseOpenedAppMessage(RemoteMessage message) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      onFirebaseForegroundMessage(message);
    }
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
        message.data['roomID'],
        message.data.containsKey("targetUserIDList")));
  }

  Future<void> onFirebaseRemoteMessageReceive(RemoteMessage message) async {
    log('remote message receive: ${message.data}');
    NotificationRing.shared.startRing();
    if (defaultTargetPlatform == TargetPlatform.android) {
      listenAwesomeNotification();
      final ReceivePort backgroundPort = ReceivePort();
      IsolateNameServer.registerPortWithName(
          backgroundPort.sendPort, backgroundIsolatePortName);
      backgroundPort.listen((dynamic message) {
        NotificationRing.shared.stopRing();
        backgroundPort.close();
        IsolateNameServer.removePortNameMapping(backgroundIsolatePortName);
      });

      AndroidForegroundService.startForeground(
        // AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: math.Random().nextInt(2147483647),
          groupKey: firebaseChannelGroupName,
          channelKey: firebaseChannelKey,
          title: "You have a new call",
          ticker: "You have a new call",
          body: "${message.data["callerUserID"]} is calling you.",
          largeIcon: 'asset://assets/images/invite_voice.png',
          category: NotificationCategory.Call,
          backgroundColor: Colors.white,
          roundedLargeIcon: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          payload: message.data.containsKey("targetUserIDList")
              ? {
                  "callerUserID": message.data["callerUserID"],
                  "callerUserName": message.data["callerUserName"],
                  "callerIconUrl": message.data["callerIconUrl"],
                  "roomID": message.data["roomID"],
                  "targetUserIDList": message.data["targetUserIDList"]
                }
              : {
                  "callerUserID": message.data["callerUserID"],
                  "callerUserName": message.data["callerUserName"],
                  "callerIconUrl": message.data["callerIconUrl"],
                  "roomID": message.data["roomID"]
                },
          notificationLayout: NotificationLayout.Default,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'accept',
            icon: 'asset://assets/images/invite_voice.png',
            label: 'Accept Call',
            color: Colors.green,
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'decline',
            icon: 'asset://assets/images/invite_reject.png',
            label: 'Reject Call',
            color: Colors.red,
            autoDismissible: true,
          ),
        ],
      );
    } else {
      onFirebaseForegroundMessage(message);
    }
  }
}

// Declared as global, outside of any class
Future<void> onFirebaseBackgroundMessage(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationRing.shared.init();
  NotificationManager.shared.onFirebaseRemoteMessageReceive(message);
}
