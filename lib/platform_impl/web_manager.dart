import 'dart:js';

import 'package:easy_example_flutter/platform_impl/types.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'dart:ui' as ui;

import 'base_manager.dart';
import 'web_js_bridge.dart' as js_bridge;

class ManagerImpl extends BaseManager {
  @override
  void createEngine(int appID, {String serverUrl = ''}) {
    js_bridge.ZegoExpressManager.shared.createEngine(appID, serverUrl);
  }

  @override
  void joinRoom(String roomID, ZegoUser user, String token,
      ZegoMediaOptions options) {
    js_bridge.ZegoMediaOptions jsOptions = [];
    final Map<ZegoMediaOption, js_bridge.ZegoMediaOption> optionMap = {
      ZegoMediaOption.autoPlayAudio: js_bridge.ZegoMediaOption.autoPlayAudio,
      ZegoMediaOption.autoPlayVideo: js_bridge.ZegoMediaOption.autoPlayVideo,
      ZegoMediaOption.publishLocalAudio:
      js_bridge.ZegoMediaOption.publishLocalAudio,
      ZegoMediaOption.publishLocalVideo:
      js_bridge.ZegoMediaOption.publishLocalVideo,
    };
    for (var v in options) {
      jsOptions.add(optionMap[v] ?? js_bridge.ZegoMediaOption.noUse0);
    }
    js_bridge.ZegoExpressManager.shared
        .joinRoom(roomID, token, user, jsOptions);
  }

  @override
  void leaveRoom() {
    js_bridge.ZegoExpressManager.shared.leaveRoom();
  }

  @override
  Widget? getLocalVideoView() {
    String webcamPushElement = 'webcamPushElement';
    // ignore:undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(webcamPushElement,
            (int id) =>
            js_bridge.ZegoExpressManager.shared.getLocalVideoView());

    return HtmlElementView(viewType: webcamPushElement);
  }

  @override
  Widget? getRemoteVideoView(String userID) {
    String webcamPlayElement = 'webcamPlayElement';
    // ignore:undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        webcamPlayElement,
            (int id) =>
            js_bridge.ZegoExpressManager.shared.getRemoteVideoView(userID));

    return HtmlElementView(viewType: webcamPlayElement);
  }

  @override
  void enableCamera(bool enable) {
    js_bridge.ZegoExpressManager.shared.enableCamera(enable);
  }

  @override
  void enableMic(bool enable) {
    js_bridge.ZegoExpressManager.shared.enableMic(enable);
  }

  @override
  void switchFrontCamera(bool isFront) {
    // Do nothing
  }

  @override
  set onRoomUserUpdate(js_bridge.onRoomUserUpdateCallback? callback) {
    void _onRoomUserUpdateCallback(String updateType, List<dynamic> userIDList,
        String roomID) {
      List<String> _userIDList = [];
      userIDList.forEach((e) => {_userIDList.add(e.toString())});
      // ignore: unrelated_type_equality_checks
      if (updateType == 'ADD') {
        if (callback != null) {
          callback(ZegoUpdateType.Add, _userIDList, roomID);
        }
        // ignore: unrelated_type_equality_checks
      } else if (updateType == 'DELETE') {
        if (callback != null) {
          callback(ZegoUpdateType.Delete, _userIDList, roomID);
        }
      }
    }

    js_bridge.ZegoExpressManager.shared
        .onRoomUserUpdate(allowInterop(_onRoomUserUpdateCallback));
  }

  @override
  set onRoomUserDeviceUpdate(
      Function(ZegoDeviceUpdateType updateType, String userID, String roomID)? callback) {
    if (callback == null) {
      return;
    }
    void _onRoomUserDeviceUpdateCallback(int updateType, String userID,
        String roomID) {
      callback(ZegoDeviceUpdateType.values[updateType], userID, roomID);
    }

    js_bridge.ZegoExpressManager.shared.onRoomUserDeviceUpdate(
        allowInterop(_onRoomUserDeviceUpdateCallback));
  }

  @override
  set onRoomTokenWillExpire(
      Function(int remainTimeInSecond, String roomID)? callback) {
    if (callback == null) {
      return;
    }
    void _onRoomTokenWillExpire(String roomID) {
      callback(0, roomID);
    }
    js_bridge.ZegoExpressManager.shared
        .onRoomTokenWillExpire(allowInterop(_onRoomTokenWillExpire));
  }
}
