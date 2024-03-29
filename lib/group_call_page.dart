import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'zego_express_manager.dart';

class GroupCallPage extends StatefulWidget {
  const GroupCallPage({Key? key}) : super(key: key);

  @override
  State<GroupCallPage> createState() => _GroupCallPageState();
}

class _GroupCallPageState extends State<GroupCallPage> {
  bool _joinedRoom = false;
  bool _micEnable = true;
  bool _cameraEnable = true;
  List<String> _userIDList = [];

  void onVideoViewUpdated() {
    setState(() {});
  }

  void prepareSDK(int appID, String appSign) {
    ZegoExpressManager.shared.createEngine(appID, appSign);
    ZegoExpressManager.shared.onRoomUserUpdate =
        (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
      if (updateType == ZegoUpdateType.Add) {
        for (final userID in userIDList) {
          if (!_userIDList.contains(userID)) {
            ZegoExpressManager.shared
                .getVideoViewNotifier(userID)
                .addListener(onVideoViewUpdated);

            setState(() {
              _userIDList = List.from(_userIDList)..add(userID);
            });
          }
        }
      } else {
        for (final userID in userIDList) {
          ZegoExpressManager.shared
              .getVideoViewNotifier(userID)
              .removeListener(onVideoViewUpdated);

          if (_userIDList.contains(userID)) {
            setState(() {
              _userIDList = List.from(_userIDList)..remove(userID);
            });
          }
        }
      }
    };
    ZegoExpressManager.shared.onRoomUserDeviceUpdate =
        (ZegoDeviceUpdateType updateType, String userID, String roomID) {};
  }

  @override
  void didChangeDependencies() {
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
        ZegoExpressManager.shared.joinRoom(roomID, ZegoUser(userID, userID), [
          ZegoMediaOption.publishLocalAudio,
          ZegoMediaOption.publishLocalVideo,
          ZegoMediaOption.autoPlayAudio,
          ZegoMediaOption.autoPlayVideo
        ]);
        setState(() {
          // _bigView = ZegoExpressManager.shared.getLocalVideoView()!;
          setState(() {
            _userIDList = [userID];
          });
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
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20),
                  itemCount: _userIDList.length,
                  itemBuilder: (BuildContext ctx, index) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(15)),
                      child: index == 0
                          ? ZegoExpressManager.shared
                                  .getVideoViewNotifier(
                                      ZegoExpressManager.shared.localUserID)
                                  .value ??
                              Container(
                                color: Colors.white,
                              )
                          : ZegoExpressManager.shared
                                  .getVideoViewNotifier(_userIDList[index])
                                  .value ??
                              Container(
                                color: Colors.black54,
                              ),
                    );
                  }),
            ),
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
                        setState(() {
                          _userIDList = [];
                        });
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
