import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:easy_example_flutter/audio_call_page.dart';
import 'package:easy_example_flutter/video_call_page.dart';
import 'package:easy_example_flutter/zego_express_manager.dart';

// TODO mark is for let you know you need to do something, please check all of it!
//\/\/\/\/\/\/\/\/\/\/\/\/\/ 👉👉👉👉 READ THIS IF YOU WANT TO DO MORE 👈👈👈 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// For how to use ZEGOCLOUD's API: https://docs.zegocloud.com/article/5560
//\/\/\/\/\/\/\/\/\/\/\/\/\ 👉👉👉👉 READ THIS IF YOU WANT TO DO MORE 👈👈👈 /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

// TODO Get your AppID/AppSign from ZEGOCLOUD Console [My Projects] :  https://console.zegocloud.com/project

const int appID = ;
const String appSign = '';

// TODO This room id for test only
//  You can talk to other user with the same roomID
//  So you need to set an unique roomID for every talk or live streaming
const String roomID = '123456';

void main() {
  // need ensureInitialized
  WidgetsFlutterBinding.ensureInitialized();
  // You need to call createEngine before call any of other methods of the SDK
  ZegoExpressManager.shared.createEngine(appID, appSign);
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
        '/home_page': (context) => const HomePage(),
        '/video_call_page': (context) => const VideoCallPage(),
        '/audio_call_page': (context) => const AudioCallPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  /// Check the permission or ask for the user if not grant
  /// TODO Copy to your project
  Future<bool> requestPermission(ZegoMediaOptions options) async {
    if (options.contains(ZegoMediaOption.publishLocalAudio)) {
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        log('Error: Microphone permission not granted!!!');
      }
    }

    if (options.contains(ZegoMediaOption.publishLocalVideo)) {
      PermissionStatus cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        log('Error: Camera permission not granted!!!');
      }
    }
    return true;
  }

  /// Get the necessary arguments to join the room for start the talk or live streaming
  ///
  ///  TODO DO NOT use special characters for userID and roomID.
  ///  We recommend only contain letters, numbers, and '_'.
  Future<Map<String, String>> getJoinRoomArgs() async {
    final userID = math.Random().nextInt(10000).toString();
    return {
      'userID': userID,
      'roomID': roomID,
      'appID': appID.toString(),
      'appSign': appSign.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text(
            'ZEGOCLOUD',
            style: TextStyle(
                fontSize: 30,
                color: Colors.blue,
                decoration: TextDecoration.none),
          ),
          toolBar(context),
        ],
      ),
    );
  }

  Widget toolBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            onPressed: () async {
              await requestPermission([
                ZegoMediaOption.publishLocalVideo,
                ZegoMediaOption.publishLocalAudio
              ]);

              Navigator.pushReplacementNamed(context, '/video_call_page',
                  arguments: await getJoinRoomArgs());
            },
            child: const Text('Start Video Call')),
        ElevatedButton(
            onPressed: () async {
              await requestPermission([ZegoMediaOption.publishLocalAudio]);

              Navigator.pushReplacementNamed(context, '/audio_call_page',
                  arguments: await getJoinRoomArgs());
            },
            child: const Text('Start Audio Call'))
      ],
    );
  }
}
