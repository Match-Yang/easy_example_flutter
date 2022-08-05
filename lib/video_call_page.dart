import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// CallPage use for display the Caller Video view and the Callee Video view
///
/// TODO You can copy the completed class to your project
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Widget _bigView = Container(
    color: Colors.white,
  );
  Widget _smallView = Container(
    color: Colors.black54,
  );
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _cameraEnable = true;

  void prepareSDK(int appID, String appSign) {
    // TODO You need to call createEngine before call any of other methods of the SDK
    ZegoExpressManager.shared.createEngine(appID, appSign);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          // For one-to-one call we just need to display the other user at the small view
          setState(() {
            _smallView = ZegoExpressManager.shared.getRemoteVideoView(userID)!;
          });
        }
      }
    };
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
  }

  @override
  void didChangeDependencies() {
    // Read data from HomePage
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
        // We are making a Video Call example so we use the options with publish video/audio and auto play video/audio
        ZegoExpressManager.shared.joinRoom(roomID, ZegoUser(userID, userID), [
          ZegoMediaOption.publishLocalAudio,
          ZegoMediaOption.publishLocalVideo,
          ZegoMediaOption.autoPlayAudio,
          ZegoMediaOption.autoPlayVideo
        ]);
        // You can get your own view and display it immediately after joining the room
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
            SizedBox.expand(child: _bigView),
            Positioned(
                top: 100,
                right: 16,
                child: SizedBox(width: 114, height: 170, child: _smallView)),
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
                            primary: Colors.black26),
                        child: Icon(_micEnable ? Icons.mic : Icons.mic_off,
                            size: 28),
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
                        }),
                    // Camera control button
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(10),
                            primary: Colors.black26),
                        child: Icon(
                            _cameraEnable
                                ? Icons.camera_alt
                                : Icons.camera_alt_outlined,
                            size: 28),
                        onPressed: () {
                          ZegoExpressManager.shared
                              .enableCamera(!_cameraEnable);
                          setState(() {
                            _cameraEnable = !_cameraEnable;
                          });
                        }),
                  ],
                )),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
