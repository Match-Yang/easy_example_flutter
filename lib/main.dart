import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:http/http.dart' as http;

// TODO mark is for let you know you need to do something, please check all of it!
//\/\/\/\/\/\/\/\/\/\/\/\/\/ 👉👉👉👉 READ THIS IF YOU WANT TO DO MORE 👈👈👈 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// For how to use ZEGOCLOUD's API: https://docs.zegocloud.com/article/5560
//\/\/\/\/\/\/\/\/\/\/\/\/\ 👉👉👉👉 READ THIS IF YOU WANT TO DO MORE 👈👈👈 /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

void main() {
  runApp(const MyApp());
}

/// MyApp class is use for example only
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
  const HomePage({Key? key}) : super(key: key);

  // TODO Test data <<<<<<<<<<<<<<
  // Get your AppID from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
  final int appID = 0;

  // TODO This room id for test only
  //  You can talk to other user with the same roomID
  //  So you need to set an unique roomID for every talk or live streaming
  final String roomID = '123456';

  // TODO Heroku server url for example
  // Get the server from: https://github.com/ZEGOCLOUD/dynamic_token_server_nodejs
  final String tokenServerUrl = ''; // https://xxx.herokuapp.com


  /// Check the permission or ask for the user if not grant
  ///
  /// TODO Copy to your project
  Future<bool> requestPermission() async {
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      log('Error: Microphone permission not granted!!!');
      return false;
    }
    return true;
  }

  /// Get the ZEGOCLOUD's API access token
  ///
  /// There are some API of ZEGOCLOUD need to pass the token to use.
  /// We use Heroku service for test.
  /// You can get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project  for both User1 and User2.
  /// Read more about the token: https://docs.zegocloud.com/article/14140
  Future<String> getToken(String userID) async {
    final response =
        await http.get(Uri.parse('$tokenServerUrl/access_token?uid=$userID'));
    if (response.statusCode == 200) {
      final jsonObj = jsonDecode(response.body);
      return jsonObj['token'];
    } else {
      return "";
    }
  }

  /// Get the necessary arguments to join the room for start the talk or live streaming
  ///
  ///  TODO DO NOT use special characters for userID and roomID.
  ///  We recommend only contain letters, numbers, and '_'.
  Future<Map<String, String>> getJoinRoomArgs() async {
    final userID = math.Random().nextInt(10000).toString();
    final String token = await getToken(userID);
    return {
      'userID': userID,
      'token': token,
      'roomID': roomID,
      'appID': appID.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text('ZEGOCLOUD',
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                  decoration: TextDecoration.none)),
          ElevatedButton(
              onPressed: () async {
                await requestPermission();
                Navigator.pushReplacementNamed(context, '/call_page',
                    arguments: await getJoinRoomArgs());
              },
              child: const Text('Join Room'))
        ],
      ),
    );
  }
}

/// CallPage use for display the Caller Video view and the Callee Video view
///
/// TODO You can copy the completed class to your project
class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _speakerEnable = true;
  String _remoteUserID = "";

  void prepareSDK(int appID) {
    // TODO You need to call createEngine before call any of other methods of the SDK
    ZegoExpressManager.shared.createEngine(appID);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
          // For one-to-one call we just need to display the other user at the small view
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          setState(() {
            _remoteUserID = userID;
          });
          break;
        }
      } else {
        setState(() {
          _remoteUserID = "";
        });
      }
    };
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
    ZegoExpressManager.shared.onRoomTokenWillExpire =
        (int remainTimeInSecond, String roomID) {
      // TODO You need to request a new token when this callback is trigger
    };
  }

  @override
  void didChangeDependencies() {
    // Read data from HomePage
    RouteSettings settings = ModalRoute.of(context)!.settings;
    if (settings.arguments != null) {
      // Read arguments
      Map<String, String> obj = settings.arguments as Map<String, String>;
      var userID = obj['userID'] ?? "";
      var token = obj['token'] ?? "";
      var roomID = obj['roomID'] ?? "";
      var appID = int.parse(obj['appID'] ?? "0");

      // Prepare SDK
      prepareSDK(appID);

      // Join room and wait for other...
      if (!_joinedRoom) {
        assert(token.isNotEmpty,
            "Token is empty! Get your temporary token from ZEGOCLOUD Console [My Projects -> project's Edit -> Basic Configurations] : https://console.zegocloud.com/project");
        // We are making a Video Call example so we use the options with publish video/audio and auto play video/audio
        ZegoExpressManager.shared
            .joinRoom(roomID, ZegoUser(userID, userID), token, [
          ZegoMediaOption.publishLocalAudio,
          ZegoMediaOption.autoPlayAudio,
        ]);
        // You can get your own view and display it immediately after joining the room
        setState(() {
          _joinedRoom = true;
        });
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.lightBlue),
        child: Column(
          children: <Widget>[
            Text(_remoteUserID,
                style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15.0,
                    decoration: TextDecoration.none)),
            const Expanded(child: Text('')),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Microphone control button
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        primary: Colors.black26),
                    child:
                        Icon(_micEnable ? Icons.mic : Icons.mic_off, size: 28),
                    onPressed: () {
                      ZegoExpressManager.shared.enableMic(!_micEnable);
                      setState(() {
                        _micEnable = !_micEnable;
                      });
                    }),
                // End call button
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        primary: Colors.red),
                    child: const Icon(Icons.call_end, size: 28),
                    onPressed: () {
                      ZegoExpressManager.shared.leaveRoom();
                      setState(() {
                        _joinedRoom = false;
                      });
                      // Back to home page
                      Navigator.pushReplacementNamed(context, '/home_page');
                    }),
                // Camera control button
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        primary: Colors.black26),
                    child: Icon(
                        _speakerEnable
                            ? Icons.speaker_phone
                            : Icons.headphones,
                        size: 28),
                    onPressed: () {
                      ZegoExpressManager.shared.enableSpeaker(!_speakerEnable);
                      setState(() {
                        _speakerEnable = !_speakerEnable;
                      });
                    })
              ],
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
