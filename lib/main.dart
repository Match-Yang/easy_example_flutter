import 'dart:developer';

import 'platform_impl/types.dart';
import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home_page',
      routes: {
        '/home_page': (context) => HomePage(),
        '/call_page': (context) => CallPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  // Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project  for both User1 and User2.
  // TODO Token get from ZEGOCLOUD's console is for test only, please get it from your server: https://docs.zegocloud.com/article/14140
  final Map<String, String> user1Arguments = {'userID': 'user1', 'token': ''};
  final Map<String, String> user2Arguments = {'userID': 'user2', 'token': ''};

  HomePage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
              onPressed: () async {
                if (!kIsWeb) {
                  await requestPermission();
                }
                Navigator.pushReplacementNamed(context, '/call_page',
                    arguments: user1Arguments);
              },
              child: const Text('Join Room As User1')),
          TextButton(
              onPressed: () async {
                if (!kIsWeb) {
                  await requestPermission();
                }
                Navigator.pushReplacementNamed(context, '/call_page',
                    arguments: user2Arguments);
              },
              child: const Text('Join Room As User2')),
        ],
      ),
    );
  }
}

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  // TODO Test data
  // Get your AppID and ServerUrl from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
  final int appID = 0;
  final String roomID = '123456';
  // serverUrl is for web only
  final String serverUrl = '';

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Widget _bigView = Container(
    color: Colors.white,
  );
  Widget _smallView = Container(
    color: Colors.black54,
  );
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _cameraEnable = true;

  @override
  void initState() {
    ZegoExpressManager.shared
        .createEngine(widget.appID, serverUrl: widget.serverUrl);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          setState(() {
            _smallView = ZegoExpressManager.shared.getRemoteVideoView(userID)!;
          });
        }
      }
    };
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
    ZegoExpressManager.shared.onRoomTokenWillExpire =
        (int remainTimeInSecond, String roomID) {
      // TODO You need to request a new token when this callback is trigger
    };
    super.initState();
  }

  @override
  void didChangeDependencies() {
    RouteSettings settings = ModalRoute.of(context)!.settings;
    if (settings.arguments != null) {
      Map<String, String> obj = settings.arguments as Map<String, String>;
      var userID = obj['userID'] ?? "";
      var token = obj['token'] ?? "";
      if (!_joinedRoom) {
        assert(token.isNotEmpty,
            "Token is empty! Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project");
        ZegoExpressManager.shared
            .joinRoom(widget.roomID, ZegoUser(userID, userID), token, [
          ZegoMediaOption.publishLocalAudio,
          ZegoMediaOption.publishLocalVideo,
          ZegoMediaOption.autoPlayAudio,
          ZegoMediaOption.autoPlayVideo
        ]);
        setState(() {
          _bigView = ZegoExpressManager.shared.getLocalVideoView()!;
          _joinedRoom = true;
        });
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: _bigView,
            ),
            Positioned(
                top: 100,
                right: 16,
                child: SizedBox(
                  width: 114,
                  height: 170,
                  child: _smallView,
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
                          _bigView = Container(
                            color: Colors.white,
                          );
                          _smallView = Container(
                            color: Colors.black54,
                          );
                          _joinedRoom = false;
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
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
