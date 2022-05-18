import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:http/http.dart' as http;

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
        '/live_page': (context) => LivePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  // TODO Test data <<<<<<<<<<<<<<
  // Get your AppID from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
  final int appID = 0;

  // Heroku server url for example
  // Get the server from: https://github.com/ZEGOCLOUD/easy_example_call_server_nodejs
  final String tokenServerUrl = ''; // https://xxx.herokuapp.com

  // TODO Test data >>>>>>>>>>>>>>
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String roomID = "0";

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

  // Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project  for both User1 and User2.
  // TODO Token get from ZEGOCLOUD's console is for test only, please get it from your server: https://docs.zegocloud.com/article/14140
  Future<String> getToken(String userID) async {
    String tokenUrl = '${widget.tokenServerUrl}/access_token?uid=$userID';
    tokenUrl = tokenUrl.replaceAll('herokuapp.com//', 'herokuapp.com/');
    final response = await http.get(Uri.parse(tokenUrl));
    if (response.statusCode == 200) {
      final jsonObj = jsonDecode(response.body);
      return jsonObj['token'];
    } else {
      return "";
    }
  }

  Future<Map<String, String>> getJoinRoomArgs(String role) async {
    final userID = math.Random().nextInt(10000).toString();
    final String token = await getToken(userID);
    return {
      'userID': userID,
      'token': token,
      'roomID': roomID,
      'appID': widget.appID.toString(),
      'role': role,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text(
              'ZEGOCLOUD',
              style: TextStyle(fontSize: 30, color: Colors.blue),
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Room ID',
              ),
              onChanged: (String value) {
                setState(() {
                  roomID = value;
                });
              },
            ),
            ElevatedButton(
                onPressed: () async {
                  await requestPermission();
                  Navigator.pushReplacementNamed(context, '/live_page',
                      arguments: await getJoinRoomArgs('host'));
                },
                child: const Text('Join Live As Host')),
            ElevatedButton(
                onPressed: () async {
                  await requestPermission();
                  Navigator.pushReplacementNamed(context, '/live_page',
                      arguments: await getJoinRoomArgs('audience'));
                },
                child: const Text('Join Live As Audience')),
          ],
        ),
      ),
    );
  }
}

class LivePage extends StatefulWidget {
  const LivePage({Key? key}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  Widget _bigView = Container(
    color: Colors.white,
  );
  Widget _smallView = Container(
    color: Colors.transparent,
  );
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _cameraEnable = true;
  bool _isHost = true;
  bool _isCoHost = false;
  String _hostID = "";
  String _coHostID = "";
  String _userID = "";

  void prepareSDK(int appID) {
    ZegoExpressManager.shared.createEngine(appID);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          setState(() {
            if (userID == _hostID) {
              _bigView = ZegoExpressManager.shared.getRemoteVideoView(userID)!;
            }
          });
        }
      } else {
        for (final userID in userIDList) {
          // Host or Co-Host left room, set coHostID to empty
          if (_coHostID.isNotEmpty &&
              (userID == _coHostID || userID == _hostID)) {
            ZegoExpressManager.shared.setRoomExtraInfo('coHostID', "");
            setState(() {
              _coHostID = "";
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
    ZegoExpressManager.shared.onRoomExtraInfoUpdate =
        (List<ZegoRoomExtraInfo> infoList) {
      for (final info in infoList) {
        if (info.key == 'hostID') {
          setState(() {
            _hostID = info.value;
          });
        } else if (info.key == 'coHostID') {
          setState(() {
            _coHostID = info.value;
            if (_coHostID.isNotEmpty) {
              _smallView =
                  ZegoExpressManager.shared.getRemoteVideoView(_coHostID)!;
            } else {
              _smallView = Container(
                color: Colors.transparent,
              );
            }
          });
        }
      }
    };
    ZegoExpressManager.shared.onRoomStateUpdate = (ZegoRoomState state) {
      if (state == ZegoRoomState.Connected) {
        if (_isHost) {
          // Set to room extra-info and let audiences know who is the host
          ZegoExpressManager.shared.setRoomExtraInfo('hostID', _userID);

          setState(() {
            _bigView = ZegoExpressManager.shared.getLocalVideoView()!;
            _hostID = _userID;
          });
        }

        setState(() {
          _joinedRoom = true;
        });
      }
    };
  }

  @override
  void didChangeDependencies() {
    RouteSettings settings = ModalRoute.of(context)!.settings;
    if (settings.arguments != null) {
      // Join room and wait for other...
      if (!_joinedRoom) {
        // Read arguments
        Map<String, String> obj = settings.arguments as Map<String, String>;
        var userID = obj['userID'] ?? "";
        var token = obj['token'] ?? "";
        var roomID = obj['roomID'] ?? "";
        var appID = int.parse(obj['appID'] ?? "0");
        var role = obj['role'] ?? "host";
        setState(() {
          _userID = userID;
          _isHost = role == 'host';
        });

        // Prepare SDK
        prepareSDK(appID);

        assert(token.isNotEmpty,
            "Token is empty! Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project");
        const ZegoMediaOptions optionsForHost = [
          ZegoMediaOption.publishLocalAudio,
          ZegoMediaOption.publishLocalVideo,
          ZegoMediaOption.autoPlayAudio,
          ZegoMediaOption.autoPlayVideo
        ];
        const ZegoMediaOptions optionsForAudience = [
          ZegoMediaOption.autoPlayAudio,
          ZegoMediaOption.autoPlayVideo
        ];
        var options = _isHost ? optionsForHost : optionsForAudience;
        ZegoExpressManager.shared
            .joinRoom(roomID, ZegoUser(userID, userID), token, options);
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    void requestToCoHost() {
      if (_coHostID.isNotEmpty) {
        log('Already co-host in the view!');
        return;
      }
      setState(() {
        _smallView = ZegoExpressManager.shared.getLocalVideoView()!;
        _isCoHost = true;
        _coHostID = _userID;
      });

      // Set to room extra-info and let audiences know who is the co-host
      ZegoExpressManager.shared.setRoomExtraInfo('coHostID', _userID);
      ZegoExpressManager.shared.enableCamera(true);
      ZegoExpressManager.shared.enableMic(true);
    }

    void requestToAudience() {
      if (_coHostID.isEmpty || _coHostID != _userID) {
        return;
      }
      setState(() {
        _smallView = Container(
          color: Colors.transparent,
        );
        _isCoHost = false;
        _coHostID = "";
      });

      // Set to room extra-info and let audiences know co-host is offline now
      ZegoExpressManager.shared.setRoomExtraInfo('coHostID', '');
      ZegoExpressManager.shared.enableCamera(false);
      ZegoExpressManager.shared.enableMic(false);
    }

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
                        // Set role back to audience when leave room
                        if (_isCoHost) {
                          requestToAudience();
                        }
                        setState(() {
                          _bigView = Container(
                            color: Colors.white,
                          );
                          _smallView = Container(
                            color: Colors.transparent,
                          );
                          _joinedRoom = false;
                        });
                        // Back to home page
                        Navigator.pushReplacementNamed(context, '/home_page');
                      },
                    ),
                    (_isHost || _isCoHost)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                  ZegoExpressManager.shared
                                      .enableMic(!_micEnable);
                                  setState(() {
                                    _micEnable = !_micEnable;
                                  });
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
                                  ZegoExpressManager.shared
                                      .enableCamera(!_cameraEnable);
                                  setState(() {
                                    _cameraEnable = !_cameraEnable;
                                  });
                                },
                              ),
                            ],
                          )
                        : Container(),
                    _isHost
                        ? Container()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(10),
                              primary: Colors.black26,
                            ),
                            child: Icon(
                              _isCoHost
                                  ? Icons.account_circle
                                  : Icons.account_circle_outlined,
                              size: 28,
                            ),
                            onPressed: () {
                              if (!_isCoHost) {
                                requestToCoHost();
                              } else {
                                requestToAudience();
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
