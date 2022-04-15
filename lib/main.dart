import 'dart:developer';

import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // Test data
  // Get your AppID from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
  final int appID = 1166801465;
  final String roomID = '123456';
  final String user1ID = 'user1';
  final String user2ID = 'user2';

  // Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project  for both User1 and User2.
  // TODO Token get from ZEGOCLOUD's console is for test only, please get it from your server: https://docs.zegocloud.com/article/14140
  final String tokenForUser1JoinRoom = '';
  final String tokenForUser2JoinRoom = '';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget _bigView = Container(
    color: Colors.red,
  );
  Widget _smallView = Container(
    color: Colors.green,
  );
  bool _user1Pressed = false;
  bool _user2Pressed = false;

  @override
  void initState() {
    ZegoExpressManager.shared.createEngine(widget.appID);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          if (!ZegoExpressManager.shared.isLocalUser(userID)) {
            setState(() {
              _smallView =
                  ZegoExpressManager.shared.getRemoteVideoView(userID)!;
            });
          }
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

  Future<PermissionStatus> requestCameraPermission() async {
    PermissionStatus cameraStatus = await Permission.camera.request();
    return cameraStatus;
  }

  Future<PermissionStatus> requestMicrophonePermission() async {
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    return microphoneStatus;
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
                right: 0,
                child: SizedBox(
                  width: 180,
                  height: 360,
                  child: _smallView,
                )),
            Positioned(
                bottom: 40,
                left: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _user2Pressed
                        ? Container()
                        : ElevatedButton(
                            child: Text(_user1Pressed
                                ? 'Leave Room'
                                : 'Join Room as User1'),
                            onPressed: () async {
                              if (_user1Pressed) {
                                ZegoExpressManager.shared.leaveRoom();
                                setState(() {
                                  _bigView = Container(
                                    color: Colors.red,
                                  );
                                  _smallView = Container(
                                    color: Colors.blue,
                                  );
                                  _user1Pressed = false;
                                });
                              } else {
                                var micPermission =
                                    await requestMicrophonePermission();
                                if (micPermission != PermissionStatus.granted) {
                                  return;
                                }
                                var cameraPermission =
                                    await requestCameraPermission();
                                if (cameraPermission !=
                                    PermissionStatus.granted) {
                                  return;
                                }
                                assert(widget.tokenForUser1JoinRoom.isNotEmpty,
                                    "Token is empty! Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project");
                                ZegoExpressManager.shared.joinRoom(
                                    widget.roomID,
                                    ZegoUser(widget.user1ID, widget.user1ID),
                                    widget.tokenForUser1JoinRoom, [
                                  ZegoMediaOption.publishLocalAudio,
                                  ZegoMediaOption.publishLocalVideo,
                                  ZegoMediaOption.autoPlayAudio,
                                  ZegoMediaOption.autoPlayVideo
                                ]);
                                setState(() {
                                  _bigView = ZegoExpressManager.shared
                                      .getLocalVideoView()!;
                                  _user1Pressed = true;
                                });
                              }
                            },
                          ),
                    _user1Pressed
                        ? Container()
                        : ElevatedButton(
                            child: Text(_user2Pressed
                                ? 'Leave Room'
                                : 'Join Room as User2'),
                            onPressed: () async {
                              if (_user2Pressed) {
                                ZegoExpressManager.shared.leaveRoom();
                                setState(() {
                                  _bigView = Container(
                                    color: Colors.red,
                                  );
                                  _smallView = Container(
                                    color: Colors.blue,
                                  );
                                  _user2Pressed = false;
                                });
                              } else {
                                var micPermission =
                                    await requestMicrophonePermission();
                                if (micPermission != PermissionStatus.granted) {
                                  return;
                                }
                                var cameraPermission =
                                    await requestCameraPermission();
                                if (cameraPermission !=
                                    PermissionStatus.granted) {
                                  return;
                                }
                                assert(widget.tokenForUser2JoinRoom.isNotEmpty,
                                    "Token is empty! Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project");
                                ZegoExpressManager.shared.joinRoom(
                                    widget.roomID,
                                    ZegoUser(widget.user2ID, widget.user2ID),
                                    widget.tokenForUser2JoinRoom, [
                                  ZegoMediaOption.publishLocalAudio,
                                  ZegoMediaOption.publishLocalVideo,
                                  ZegoMediaOption.autoPlayAudio,
                                  ZegoMediaOption.autoPlayVideo
                                ]);
                                setState(() {
                                  _bigView = ZegoExpressManager.shared
                                      .getLocalVideoView()!;
                                  _user2Pressed = true;
                                });
                              }
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
