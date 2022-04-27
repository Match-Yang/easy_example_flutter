import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'platform_impl/types.dart';
import 'platform_impl/mobile_manager.dart'
if (dart.library.html) 'platform_impl/web_manager.dart';

class ZegoExpressManager {
  factory ZegoExpressManager() {
    return _singleton;
  }

  ZegoExpressManager._internal();

  static final shared = ZegoExpressManager();
  static final ZegoExpressManager _singleton = ZegoExpressManager._internal();

  final ManagerImpl _manager = ManagerImpl();

  set onRoomUserUpdate(
      Function(ZegoUpdateType updateType, List<String> userIDList,
              String roomID)?
          callback) {
    _manager.onRoomUserUpdate = callback;
  }

  set onRoomUserDeviceUpdate(
      Function(ZegoDeviceUpdateType updateType, String userID, String roomID)?
          callback) {
    _manager.onRoomUserDeviceUpdate = callback;
  }

  set onRoomTokenWillExpire(
      Function(int remainTimeInSecond, String roomID)? callback) {
    _manager.onRoomTokenWillExpire = callback;
  }

  void createEngine(int appID, {String serverUrl = ''}) {
    _manager.createEngine(appID, serverUrl: serverUrl);
  }

  void joinRoom(
      String roomID, ZegoUser user, String token, ZegoMediaOptions options) {
    _manager.joinRoom(roomID, user, token, options);
  }

  Widget? getLocalVideoView() {
    return _manager.getLocalVideoView();
  }

  // Get the view and call setState to set the view to render tree
  // Call this function after join room
  Widget? getRemoteVideoView(String userID) {
    return _manager.getRemoteVideoView(userID);
  }

  void enableCamera(bool enable) {
    _manager.enableCamera(enable);
  }

  void enableMic(bool enable) {
    _manager.enableMic(enable);
  }

  void switchFrontCamera(bool isFront) {
    _manager.switchFrontCamera(isFront);
  }

  void leaveRoom() {
    _manager.leaveRoom();
  }
}
