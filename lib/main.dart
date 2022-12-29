import 'dart:async';
import 'dart:math' as math;
import 'dart:developer';
import 'dart:convert';
import 'package:easy_example_flutter/group_call_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'bloc/call_bloc.dart';
import 'notification/notification_widget.dart';
import 'notification/notification_manager.dart';
import 'notification/notification_ring.dart';
import 'zego_express_manager.dart';

// step1. Get your AppID and AppSign from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
int appID = ;
String appSign = ;

// step2. Get the server from: https://github.com/ZEGOCLOUD/easy_example_call_server_nodejs
// Heroku server url for example 'https://xxx.herokuapp.com'
String tokenServerUrl = "";

// test data

String userID = math.Random().nextInt(10000).toString();

Future<void> main() async {
  // need ensureInitialized
  WidgetsFlutterBinding.ensureInitialized();

  // need init Notification
  await NotificationManager.shared.init();

  ZegoExpressManager.shared.createEngine(appID, appSign);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CallBloc.shared,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/home_page',
        routes: {
          '/home_page': (context) => const HomePage(),
          '/call_page': (context) => const CallPage(),
          '/group_call_page': (context) => const GroupCallPage()
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ReadyState {
  notReady,
  ready,
  failed,
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static ReadyState firebaseReady = ReadyState.notReady;
  static String firebaseTips = 'starting...';

  StreamSubscription? subscription;
  final targetUserIDController = TextEditingController();

  bool get ready => ReadyState.ready == firebaseReady;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      CallBloc.shared.flushBackgroundCache();
    });

    requestPermission();
    requestNotificationPermission();

    subscription = CallBloc.shared.stream.listen((state) {
      if (state is CallInviteAccepted) {
        var callState = state;
        var roomArgs = {
          'userID': userID,
          'roomID': callState.roomID,
          'appID': appID.toString(),
        };
        if (callState.isGroupCall) {
          Navigator.pushNamed(context, '/group_call_page', arguments: roomArgs);
        } else {
          Navigator.pushNamed(context, '/call_page', arguments: roomArgs);
        }
      }
    });

    if (ReadyState.ready != firebaseReady) requestFCMToken();
  }

  @override
  void dispose() async {
    super.dispose();

    subscription?.cancel();

    targetUserIDController.dispose();

    WidgetsBinding.instance?.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        CallBloc.shared.flushBackgroundCache();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        body: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                'ZEGOCLOUD',
                style: TextStyle(fontSize: 30, color: Colors.blue),
              ),
              Column(
                children: [
                  prepareTips(
                    firebaseReady,
                    firebaseTips,
                    requestFCMToken,
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      'Your UserID is: $userID',
                      style: const TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: TextField(
                      style: const TextStyle(fontSize: 20, color: Colors.blue),
                      keyboardType: TextInputType.number,
                      controller: targetUserIDController,
                      decoration: const InputDecoration(
                        hintStyle: TextStyle(fontSize: 15, color: Colors.blue),
                        hintText: 'please input target UserID',
                      ),
                    ),
                    trailing: ElevatedButton(
                      child: ready
                          ? const Icon(Icons.call)
                          : const Text("please wait"),
                      onPressed: () {
                        if (targetUserIDController.text.isEmpty) {
                          return;
                        }

                        if (ready) {
                          if (targetUserIDController.text.contains(',')) {
                            inviteGroupCall(
                                targetUserIDController.text.split(','));
                          } else {
                            callInvite(targetUserIDController.text);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      BlocBuilder<CallBloc, CallState>(
        builder: (context, state) {
          switch (state.runtimeType) {
            case CallInitial:
              return Container();
            case CallInviteReceiving:
              NotificationRing.shared.startRing();
              var callState = state as CallInviteReceiving;
              return NotifycationWidget(
                callerUserID: callState.callerUserID,
                callerUserName: callState.callerUserName,
                callerIconUrl: callState.callerIconUrl,
                onDecline: () {
                  NotificationRing.shared.stopRing();
                  CallBloc.shared.add(CallInviteDecline());
                },
                onAccept: () {
                  NotificationRing.shared.stopRing();
                  CallBloc.shared.add(CallInviteAccept(
                    callState.roomID,
                    callState.isGroupCall,
                    false,
                  ));
                },
              );
            default:
              return Container();
          }
        },
      ),
    ]);
  }

  void requestFCMToken() async {
    setState(() => firebaseTips = 'Getting fcm token...');
    var fcmToken = await FirebaseMessaging.instance.getToken();

    setState(() => firebaseTips = 'Storing fcm token...');
    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('$tokenServerUrl/store_fcm_token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceType': defaultTargetPlatform.toString().split(".").last,
          'token': fcmToken,
          'userID': userID,
        }),
      );
      setState(() {
        if ((response.statusCode == 200) &&
            (json.decode(response.body)['ret'] == 0)) {
          firebaseReady = ReadyState.ready;
          firebaseTips = 'Store fcm token success';
        } else {
          firebaseReady = ReadyState.failed;
          firebaseTips =
              'Store fcm token failed, ${json.decode(response.body)['message'] ?? ""}';
        }
      });
    } on Exception catch (error) {
      setState(() {
        firebaseReady = ReadyState.failed;
        firebaseTips = 'Store fcm token failed, ${error.toString()}';
      });
      log("[ERROR], store fcm token exception, ${error.toString()}");
    }
  }

  Future<void> requestNotificationPermission() async {
    // setState(() => firebaseTips = 'requesting permission...');
    await NotificationManager.shared.requestNotificationPermission();
  }

  void callInvite(String targetID) {
    if (!ready) {
      return;
    }

    http
        .post(
      Uri.parse('$tokenServerUrl/call_invite'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "targetUserID": targetID,
        "callerUserID": userID,
        "callerUserName": userID,
        "callerIconUrl": "https://img.icons8.com/color/48/000000/avatar.png",
        "roomID": userID,
      }),
    )
        .then((response) {
      if ((response.statusCode == 200) &&
          (json.decode(response.body)["ret"] == 0)) {
        log('call success');

        var roomArgs = {
          'userID': userID,
          'roomID': userID,
          'appID': appID.toString(),
        };
        Navigator.pushNamed(context, '/call_page', arguments: roomArgs);
      } else {
        log('call failed, ${response.statusCode}');
      }
    });
  }

  void inviteGroupCall(List<String> targetIDList) {
    if (!ready) return;
    http
        .post(
      Uri.parse('$tokenServerUrl/group_call_invite'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "targetUserIDList": targetIDList,
        "callerUserID": userID,
        "callerUserName": userID,
        "callerIconUrl": "https://img.icons8.com/color/48/000000/avatar.png",
        "roomID": userID,
      }),
    )
        .then((response) {
      if ((response.statusCode == 200) &&
          (json.decode(response.body)["ret"] == 0)) {
        log('call success');

        var roomArgs = {
          'userID': userID,
          'roomID': userID,
          'appID': appID.toString(),
        };
        Navigator.pushNamed(context, '/group_call_page', arguments: roomArgs);
      } else {
        log('call failed');
      }
    });
  }
}

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  ValueNotifier<Widget?> _bigView = ValueNotifier<Widget?>(Container(
    color: Colors.white,
  ));
  ValueNotifier<Widget?> _smallView = ValueNotifier<Widget?>(Container(
    color: Colors.black54,
  ));
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _cameraEnable = true;

  bool _sdkPrepare = false;

  void prepareSDK(int appID, String appSign) {
    if (_sdkPrepare) {
      return;
    }

    _sdkPrepare = true;
    ZegoExpressManager.shared.createEngine(appID, appSign);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          setState(() {
            _smallView = ZegoExpressManager.shared.getVideoViewNotifier(userID);
          });
        }
      }
    };
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      RouteSettings settings = ModalRoute.of(context)!.settings;
      if (settings.arguments != null) {
        // Read arguments
        Map<String, String> obj = settings.arguments as Map<String, String>;
        var userID = obj['userID'] ?? "";
        var roomID = obj['roomID'] ?? "";
        var appID = int.parse(obj['appID'] ?? "0");
        var appSign = obj['appSign'] ?? "";

        // Prepare SDK
        prepareSDK(appID, appSign);

        // Join room and wait for other...
        if (!_joinedRoom) {
          _joinedRoom = true;

          ZegoExpressManager.shared.joinRoom(roomID, ZegoUser(userID, userID), [
            ZegoMediaOption.publishLocalAudio,
            ZegoMediaOption.publishLocalVideo,
            ZegoMediaOption.autoPlayAudio,
            ZegoMediaOption.autoPlayVideo
          ]).then((value) {
            setState(() {
              _bigView = ZegoExpressManager.shared.createVideoView(userID);
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: ValueListenableBuilder<Widget?>(
                  valueListenable: _bigView,
                  builder: (context, videoView, _) {
                    return videoView ?? Container(color: Colors.green);
                  }),
            ),
            Positioned(
                top: 100,
                right: 16,
                child: SizedBox(
                  width: 114,
                  height: 170,
                  child: ValueListenableBuilder<Widget?>(
                      valueListenable: _smallView,
                      builder: (context, videoView, _) {
                        return videoView ?? Container(color: Colors.red);
                      }),
                )),
            Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Microphone control button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.black26,
                        padding: const EdgeInsets.all(10),
                      ),
                      child: Icon(
                        _micEnable ? Icons.mic : Icons.mic_off,
                        size: 28,
                      ),
                      onPressed: () {
                        ZegoExpressManager.shared.enableMic(!_micEnable);
                        setState(() {
                          _micEnable = !_micEnable;
                        });
                      },
                    ),
                    // End call button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(10),
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: 28,
                      ),
                      onPressed: () {
                        ZegoExpressManager.shared.leaveRoom();

                        _bigView.value = Container(
                          color: Colors.white,
                        );
                        _smallView.value = Container(
                          color: Colors.black54,
                        );
                        _joinedRoom = false;

                        // Back to home page
                        Navigator.pop(context, '/home_page');
                      },
                    ),
                    // Camera control button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.black26,
                        padding: const EdgeInsets.all(10),
                      ),
                      child: Icon(
                        _cameraEnable
                            ? Icons.camera_alt
                            : Icons.camera_alt_outlined,
                        size: 28,
                      ),
                      onPressed: () {
                        ZegoExpressManager.shared.enableCamera(!_cameraEnable);
                        setState(() {
                          _cameraEnable = !_cameraEnable;
                        });
                      },
                    ),
                  ],
                )),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Future<bool> requestPermission() async {
  log("requestPermission...");
  try {
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      log('Error: Microphone permission not granted!!!');
      return false;
    }
  } on Exception catch (error) {
    log("[ERROR], request microphone permission exception, ${error.toString()}");
  }

  try {
    PermissionStatus cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      log('Error: Camera permission not granted!!!');
      return false;
    }
  } on Exception catch (error) {
    log("[ERROR], request camera permission exception, ${error.toString()}");
  }

  return true;
}

Widget prepareTips(ReadyState readyState, String tips, VoidCallback retry) {
  late Widget icon;
  switch (readyState) {
    case ReadyState.notReady:
      icon = const CircularProgressIndicator(strokeWidth: 2.0);
      break;
    case ReadyState.ready:
      icon = const Icon(Icons.check_circle, color: Colors.green);
      break;
    case ReadyState.failed:
      icon = const Icon(Icons.report_problem, color: Colors.red);
      break;
  }

  var listTitle = ListTile(
    leading: icon,
    title: Text(
      tips,
      style: const TextStyle(fontSize: 20, color: Colors.blue),
    ),
  );

  return readyState == ReadyState.failed
      ? GestureDetector(
          onTap: retry,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.red)),
            child: listTitle,
          ),
        )
      : listTitle;
}
