import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'call_page.dart';
import 'group_call_page.dart';

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
        '/group_call_page': (context) => GroupCallPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // TODO Test data <<<<<<<<<<<<<<
  // Get your AppID/AppSign from ZEGOCLOUD Console [My Projects] : https://console.zegocloud.com/project
  final int appID = ;
  final String appSign = '';

  /// Check the permission or ask for the user if not grant
  ///
  /// TODO Copy to your project
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

  /// Get the necessary arguments to join the room for start the talk or live streaming
  ///
  ///  TODO DO NOT use special characters for userID and roomID.
  ///  We recommend only contain letters, numbers, and '_'.
  Future<Map<String, String>> getJoinRoomArgs(String roomID) async {
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
            style: TextStyle(fontSize: 30, color: Colors.blue),
          ),
          ElevatedButton(
              onPressed: () async {
                await requestPermission();
                // TODO This room id for test only
                //  You can talk to other user with the same roomID
                //  So you need to set an unique roomID for every talk
                Navigator.pushReplacementNamed(context, '/call_page',
                    arguments: await getJoinRoomArgs("123456_1v1"));
              },
              child: const Text('Start 1v1 talk')),
          ElevatedButton(
              onPressed: () async {
                await requestPermission();
                // TODO This room id for test only
                //  You can talk to other user with the same roomID
                //  So you need to set an unique roomID for every talk
                Navigator.pushReplacementNamed(context, '/group_call_page',
                    arguments: await getJoinRoomArgs("654321_group"));
              },
              child: const Text('Start group talk')),
        ],
      ),
    );
  }
}
