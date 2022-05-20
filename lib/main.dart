import 'dart:math' as math;
import 'dart:developer';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'bloc/call_bloc.dart';
import 'firebase_options.dart';
import 'notification/notification_widget.dart';
import 'notification/notification_manager.dart';
import 'notification/notification_ring.dart';
import 'zego_express_manager.dart';

// step1. Get your AppID from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
int appID = 0;

// step2. Get the server from: https://github.com/ZEGOCLOUD/dynamic_token_server_nodejs
// Heroku server url for example 'https://xxx.herokuapp.com'
String tokenServerUrl = '';

// test data
String roomID = '123456';
String userID = math.Random().nextInt(10000).toString();
String targetID = '';

RemoteMessage? backendMessage;

Future<void> main() async {

  // need ensureInitialized
  WidgetsFlutterBinding.ensureInitialized();

  // need init Notification
  await NotificationManager.shared.init();

  ZegoExpressManager.shared.createEngine(appID);

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
          '/call_page': (context) => const CallPage()
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

class _HomePageState extends State<HomePage> {
  static bool expressReady = false;
  static String expressTips = 'starting...';

  static bool firebaseReady = false;
  static String firebaseTips = 'starting...';

  bool get ready => expressReady && firebaseReady;

  @override
  void initState() {
    super.initState();
    requestPermission();
    if (!expressReady) requestExpressToken();
    if (!firebaseReady) requestFCMToken();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallInviteAccepted) {
          var callState = state;
          roomID = callState.roomID;
          Navigator.pushNamed(context, '/call_page');
        }
      },
      child: Stack(children: [
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
                    prepareTips(firebaseReady, firebaseTips),
                    prepareTips(expressReady, expressTips),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        'Your UserID is: $userID',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: TextField(
                        style:
                            const TextStyle(fontSize: 20, color: Colors.blue),
                        keyboardType: TextInputType.number,
                        onChanged: (input) => targetID = input,
                        decoration: InputDecoration(
                          hintStyle:
                              const TextStyle(fontSize: 15, color: Colors.blue),
                          hintText: targetID.isEmpty
                              ? 'please input target UserID'
                              : targetID,
                        ),
                      ),
                      trailing: ElevatedButton(
                        child: ready
                            ? const Icon(Icons.call)
                            : const Text("please wait"),
                        onPressed: () {
                          if (ready) callInvite(targetID);
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
                return Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: NotifycationWidget(
                      callerUserID: callState.callerUserID,
                      callerUserName: callState.callerUserName,
                      callerIconUrl: callState.callerIconUrl,
                      onDecline: () {
                        NotificationRing.shared.stopRing();
                        CallBloc.shared.add(CallInviteDecline());
                      },
                      onAccept: () {
                        NotificationRing.shared.stopRing();
                        CallBloc.shared.add(CallInviteAccept(callState.roomID));
                      },
                    ),
                  ),
                );
              default:
                return Container();
            }
          },
        ),
      ]),
    );
  }

  void requestFCMToken() async {
    setState(() => firebaseTips = 'initializing firebase...');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    setState(() => firebaseTips = 'Getting fcm token...');
    var fcmToken = await FirebaseMessaging.instance.getToken();

    setState(() => firebaseTips = 'Storing fcm token...');
    var response = await http.post(
      Uri.parse('$tokenServerUrl/store_fcm_token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'token': fcmToken,
        'userID': userID,
      }),
    );

    setState(() => firebaseTips = 'requesting permission...');
    NotificationManager.shared.requestNotificationPermission();

    setState(() {
      if ((response.statusCode == 200) &&
          (json.decode(response.body)['ret'] == 0)) {
        firebaseReady = true;
        firebaseTips = 'Store fcm token success';
      } else {
        firebaseReady = false;
        firebaseTips = 'Store fcm token failed';
      }
    });
  }

  void requestExpressToken({bool needReNewToken = false}) {
    if (ZegoExpressManager.shared.token.isEmpty || needReNewToken) {
      setState(() => expressTips = 'getting express token...');

      getExpressToken(userID).then((token) {
        ZegoExpressManager.shared.renewToken(token);
        setState(() {
          expressReady = ZegoExpressManager.shared.token.isNotEmpty;
          expressTips = ZegoExpressManager.shared.token.isEmpty
              ? "Get express token faild, please check your tokenServerUrl"
              : "Get express token success";
        });
      });
    }
  }

  void callInvite(String targetID) {
    if (!ready) return;
    http
        .post(
      Uri.parse('$tokenServerUrl/call_invite'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "targetUserID": targetID,
        "callerUserID": userID,
        "callerUserName": userID,
        "callerIconUrl": "https://img.icons8.com/color/48/000000/avatar.png",
        "roomID": "${userID}_$targetID",
      }),
    )
        .then((response) {
      if ((response.statusCode == 200) &&
          (json.decode(response.body)["ret"] == 0)) {
        log('call success');
        roomID = '${userID}_$targetID';
        // Navigator.pushNamed(context, '/call_page');
      } else {
        log('call failed');
      }
    });
  }
}

class CallPage extends StatefulWidget {
  const CallPage({
    Key? key,
  }) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Widget? _localView = Container(color: Colors.white);
  final GlobalKey _localViewKey = GlobalKey();

  Widget _remoteView = Container(color: Colors.black54);
  final GlobalKey _remoteViewKey = GlobalKey();

  bool needLoadUserView = true;

  bool _micEnable = true;
  bool _cameraEnable = true;

  String roomState = 'None';
  int roomErrorCode = 0;

  @override
  void initState() {
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
    ZegoExpressManager.shared.onRoomTokenWillExpire =
        (int remainTimeInSecond, String roomID) {
      getExpressToken(ZegoExpressManager.shared.localParticipant.userID)
          .then((token) {
        ZegoExpressManager.shared.renewToken(token);
      });
    };
    ZegoExpressManager.shared.onRoomStateUpdate =
        (ZegoRoomState state, int errorCode) {
      setState(() {
        roomState = state.toString();
        roomErrorCode = errorCode;
      });
    };

    ZegoExpressManager.shared.joinRoom(
        roomID, ZegoUser(userID, userID), ZegoExpressManager.shared.token, [
      ZegoMediaOption.publishLocalAudio,
      ZegoMediaOption.publishLocalVideo,
      ZegoMediaOption.autoPlayAudio,
      ZegoMediaOption.autoPlayVideo
    ]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // we need loadUserView after First build
    // to get the view element size
    if (needLoadUserView) {
      needLoadUserView = false;
      Future.delayed(const Duration(), () {
        loadUserViewAfterFirstBuild();
      });
    }

    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            SizedBox.expand(key: _localViewKey, child: _localView),
            Positioned(
                top: 100,
                right: 16,
                child: SizedBox(
                  key: _remoteViewKey,
                  // default use 9:16
                  width: 108,
                  height: 192,
                  child: _remoteView,
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
                        padding: const EdgeInsets.all(10),
                        primary: Colors.black26,
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
                        padding: const EdgeInsets.all(10),
                        primary: Colors.red,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: 28,
                      ),
                      onPressed: () {
                        ZegoExpressManager.shared.leaveRoom();
                        setState(() {
                          _localView = Container(color: Colors.white);
                          _remoteView = Container(color: Colors.black54);
                        });
                        // Back to home page
                        Navigator.pushReplacementNamed(context, '/home_page');
                      },
                    ),
                    // Camera control button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        primary: Colors.black26,
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
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                child: roomErrorCode != 0
                    ? Text(
                        '$roomState\nerror: ',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void loadUserViewAfterFirstBuild() {
    double devicePixelRatio =
        WidgetsFlutterBinding.ensureInitialized().window.devicePixelRatio;
    RenderBox? localViewRenderBox =
        _localViewKey.currentContext?.findRenderObject() as RenderBox;

    final localViewSize = localViewRenderBox.size * devicePixelRatio;

    ZegoExpressManager.shared
        // .getLocalVideoView(widget.screenWidthPx, widget.screenHeightPx)
        .getLocalVideoView(
            (localViewSize.width).floor(), (localViewSize.height).floor())
        .then((texture) {
      setState(() {
        _localView = texture!;
      });
    });

    RenderBox? remoteViewRenderBox =
        _localViewKey.currentContext?.findRenderObject() as RenderBox;
    final remoteViewSize = remoteViewRenderBox.size * devicePixelRatio;
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          ZegoExpressManager.shared
              .getRemoteVideoView(userID, (remoteViewSize.width).floor(),
                  (remoteViewSize.height).floor())
              .then((texture) {
            setState(() {
              _remoteView = texture!;
            });
          });
        }
      } else {
        setState(() {
          _remoteView = Container(color: Colors.black54);
        });
      }
    };
  }
}

Future<bool> requestPermission() async {
  PermissionStatus microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus != PermissionStatus.granted) {
    log('Error: Microphone permission not granted!!!');
    return false;
  }
  PermissionStatus cameraStatus = await Permission.camera.request();
  if (cameraStatus != PermissionStatus.granted) {
    log('Error: Camera permission not granted!!!');
    return false;
  }
  return true;
}

// Get your token from tokenServer
Future<String> getExpressToken(String userID) async {
  final response =
      await http.get(Uri.parse('$tokenServerUrl/access_token?uid=$userID'));
  if (response.statusCode == 200) {
    final jsonObj = json.decode(response.body);
    return jsonObj['token'];
  } else {
    return "";
  }
}

ListTile prepareTips(bool ready, String tips) {
  return ListTile(
    leading: ready
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.report_problem, color: Colors.red),
    title: Text(
      tips,
      style: const TextStyle(fontSize: 20, color: Colors.blue),
    ),
  );
}
