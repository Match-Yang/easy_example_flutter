@JS()
library ZegoExpressManager;

import 'dart:html';
import 'package:js/js.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

typedef ZegoMediaOptions = List<ZegoMediaOption>;

enum ZegoMediaOption {
  noUse0,
  autoPlayAudio,
  autoPlayVideo,
  noUse3,
  publishLocalAudio,
  noUse5,
  noUse6,
  noUse7,
  publishLocalVideo
}

typedef onRoomUserDeviceUpdateCallback = void Function(
    ZegoDeviceUpdateType updateType, String userID, String roomID);
typedef onRoomUserDeviceUpdateCallbackWeb = void Function(
    int updateType, String userID, String roomID);

typedef onRoomTokenWillExpireCallback = void Function(String roomID);

typedef onRoomUserUpdateCallback = void Function(
    ZegoUpdateType updateType, List<String> userIdList, String roomID);

typedef onRoomUserUpdateCallbackWeb = void Function(
    String updateType, List<dynamic> userIdList, String roomID);

enum ZegoDeviceUpdateType { cameraOpen, cameraClose, micUnMute, micMute }

// key is user id, value is view id
typedef UserIDViewIDMap = Map<String, int>;

@JS()
class ZegoExpressManager {
  external static ZegoExpressManager shared;
  external static ZegoExpressEngine engine;
  external static ZegoExpressEngine getEngine();
  external ZegoExpressEngine createEngine(int appID, String server);
  external Future<bool> checkWebRTC();
  external Future<bool> checkCamera();
  external Future<bool> checkMicrophone();
  external Future<bool> joinRoom(
      String roomID, String token, String user, ZegoMediaOptions options);
  external bool enableCamera(bool enable);
  external bool enableMic(bool enable);
  external VideoElement getLocalVideoView();
  external VideoElement getRemoteVideoView(String userID);
  external void leaveRoom();
  external bool onRoomUserUpdate(onRoomUserUpdateCallbackWeb call);
  external bool onRoomUserDeviceUpdate(onRoomUserDeviceUpdateCallbackWeb call);
  external bool onRoomTokenWillExpire(onRoomTokenWillExpireCallback call);
}

@JS()
@anonymous
class ZegoExpressEngine {
  external String get userID;
  external String get userName;
}
