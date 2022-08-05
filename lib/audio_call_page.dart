import 'package:easy_example_flutter/zego_express_manager.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// AudioCallPage use for display the Caller Video view and the Callee Video view
///
/// TODO You can copy the completed class to your project
class AudioCallPage extends StatefulWidget {
  const AudioCallPage({Key? key}) : super(key: key);

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _speakerEnable = true;
  String _remoteUserID = "";

  void prepareSDK(int appID, String appSign) {
    // TODO You need to call createEngine before call any of other methods of the SDK
    ZegoExpressManager.shared.createEngine(appID, appSign);
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
        ZegoExpressManager.shared
            .joinRoom(roomID, ZegoUser(userID, userID), [
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
