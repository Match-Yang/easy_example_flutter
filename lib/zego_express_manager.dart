import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoParticipant {
  String userID = '';
  String name = '';
  String streamID = '';
  int viewID = -1;
  Widget view = Container();
  bool camera = false;
  bool mic = false;
  ZegoStreamQualityLevel network = ZegoStreamQualityLevel.Excellent;

  ZegoParticipant(this.userID, this.name);
}

enum ZegoMediaOption {
  autoPlayAudio,
  autoPlayVideo,
  publishLocalAudio,
  publishLocalVideo
}

enum ZegoDeviceUpdateType { cameraOpen, cameraClose, micUnMute, micMute }

// key is user id, value is participant model
typedef UserIDParticipantMap = Map<String, ZegoParticipant>;
// key is user id, value is view id
typedef UserIDViewIDMap = Map<String, int>;
// key is stream id, value is participant model
typedef StreamIDParticipantMap = Map<String, ZegoParticipant>;
typedef ZegoMediaOptions = List<ZegoMediaOption>;

/// A wrapper for using ZegoExpressEngine's methods
///
/// We do some basic logic inside this class, if you use it somewhere then we will recommend you use it anywhere.
/// If you don't understand ZegoExpressEngine very well, do not mix two of the class on your code.
/// Instead you should use every methods call of ZegoExpressEngine inside this class
/// and do everything you want via ZegoExpressManager
/// Read more about ZegoExpressEngine: https://docs.zegocloud.com/article/3559
class ZegoExpressManager {
  factory ZegoExpressManager() {
    return _singleton;
  }

  ZegoExpressManager._internal();

  /// Instance of ZegoExpressManager
  ///
  /// You should call all of the method via this instance
  static final shared = ZegoExpressManager();
  static final ZegoExpressManager _singleton = ZegoExpressManager._internal();

  /// When you join in the room it will let you know who is in the room right now with [userIDList] and will let you know who is joining the room or who is leaving after you have joined
  void Function(
          ZegoUpdateType updateType, List<String> userIDList, String roomID)?
      onRoomUserUpdate;

  /// Trigger when device's status of user with [userID] has been update
  void Function(ZegoDeviceUpdateType updateType, String userID, String roomID)?
      onRoomUserDeviceUpdate;

  /// Trigger when the access token will expire which mean you should call renewToken to set new token
  void Function(int remainTimeInSecond, String roomID)? onRoomTokenWillExpire;

  /// Trigger when room extra info has been updated by you or others
  void Function(List<ZegoRoomExtraInfo> roomExtraInfoList)?
      onRoomExtraInfoUpdate;

  /// Trigger when room's state changed
  void Function(ZegoRoomState state)? onRoomStateUpdate;

  bool _isPlayingStream = false;
  ZegoParticipant _localParticipant = ZegoParticipant("", "");
  UserIDParticipantMap _participantDic = {};
  StreamIDParticipantMap _streamDic = {};
  String _roomID = "";
  ZegoMediaOptions _mediaOptions = [
    ZegoMediaOption.autoPlayAudio,
    ZegoMediaOption.autoPlayVideo
  ];

  /// Create SDK instance and setup some callbacks
  ///
  /// You need to call createEngine before call any of other methods of the SDK
  /// Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/createEngine.html
  void createEngine(int appID, String appSign) {
    // if your scenario is live,you can change to ZegoScenario.Live.
    // if your scenario is communication , you can change to ZegoScenario.Communication
    ZegoEngineProfile profile = ZegoEngineProfile(appID, ZegoScenario.General,
        appSign: appSign, enablePlatformView: true);

    ZegoExpressEngine.createEngineWithProfile(profile);

    // Setup event handler
    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRoomStreamUpdate.html
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID,
        ZegoUpdateType updateType,
        List<ZegoStream> streamList,
        Map<String, dynamic> extendedData) {
      for (final stream in streamList) {
        if (updateType == ZegoUpdateType.Add) {
          _playStream(stream.streamID);
        } else {
          ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        }
      }
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRoomUserUpdate.html
    ZegoExpressEngine.onRoomUserUpdate =
        (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      List<String> userIDList = [];
      if (updateType == ZegoUpdateType.Add) {
        for (final user in userList) {
          userIDList.add(user.userID);
          ZegoParticipant participant =
              ZegoParticipant(user.userID, user.userName);
          participant.streamID = _generateStreamID(user.userID, roomID);
          _participantDic[participant.userID] = participant;
          _streamDic[participant.streamID] = participant;
        }
      } else {
        //  Delete
        for (final user in userList) {
          userIDList.add(user.userID);
          if (_participantDic.containsKey(user.userID)) {
            var participant = _participantDic[user.userID];
            if (participant!.viewID != -1) {
              ZegoExpressEngine.instance
                  .destroyPlatformView(participant.viewID);
            }

            _streamDic.remove(_participantDic[user.userID]!.streamID);
            _participantDic.remove(user.userID);
          }
        }
      }
      if (onRoomUserUpdate != null) {
        onRoomUserUpdate!(updateType, userIDList, roomID);
      }
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRemoteCameraStateUpdate.html
    ZegoExpressEngine.onRemoteCameraStateUpdate =
        (String streamID, ZegoRemoteDeviceState state) {
      if (_streamDic.containsKey(streamID)) {
        var participant = _streamDic[streamID];
        participant!.camera = ZegoRemoteDeviceState.Open == state;
        var type = state == ZegoRemoteDeviceState.Open
            ? ZegoDeviceUpdateType.cameraOpen
            : ZegoDeviceUpdateType.cameraClose;
        if (onRoomUserDeviceUpdate != null) {
          onRoomUserDeviceUpdate!(type, participant.userID, _roomID);
        }
      }
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRemoteMicStateUpdate.html
    ZegoExpressEngine.onRemoteMicStateUpdate =
        (String streamID, ZegoRemoteDeviceState state) {
      if (_streamDic.containsKey(streamID)) {
        var participant = _streamDic[streamID];
        participant!.mic = ZegoRemoteDeviceState.Open == state;
        var type = state == ZegoRemoteDeviceState.Open
            ? ZegoDeviceUpdateType.micUnMute
            : ZegoDeviceUpdateType.micMute;
        if (onRoomUserDeviceUpdate != null) {
          onRoomUserDeviceUpdate!(type, participant.userID, _roomID);
        }
      }
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRoomStateUpdate.html
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state,
        int errorCode, Map<String, dynamic> extendedData) {
      _processLog("onRoomStateUpdate", state.index, errorCode);
      if (onRoomStateUpdate != null) {
        onRoomStateUpdate!(state);
      }
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onPublisherStateUpdate.html
    ZegoExpressEngine.onPublisherStateUpdate = (String streamID,
        ZegoPublisherState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      _processLog("onPublisherStateUpdate", state.index, errorCode);
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onPlayerStateUpdate.html
    ZegoExpressEngine.onPlayerStateUpdate = (String streamID,
        ZegoPlayerState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      _processLog("onPlayerStateUpdate", state.index, errorCode);
    };

    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onNetworkQuality.html
    ZegoExpressEngine.onNetworkQuality = (String userID,
        ZegoStreamQualityLevel upstreamQuality,
        ZegoStreamQualityLevel downstreamQuality) {
      if (!_participantDic.containsKey(userID)) {
        return;
      }
      var participant = _participantDic[userID];
      if (userID == _localParticipant.userID) {
        participant!.network = downstreamQuality;
      } else {
        participant!.network = upstreamQuality;
      }
    };

    // Read more about it:https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRoomTokenWillExpire.html
    ZegoExpressEngine.onRoomTokenWillExpire =
        (String roomID, int remainTimeInSecond) {
      if (onRoomTokenWillExpire != null) {
        onRoomTokenWillExpire!(remainTimeInSecond, roomID);
      }
    };
    // Read more about it: https://pub.dev/documentation/zego_express_engine/latest/zego_express_engine/ZegoExpressEngine/onRoomExtraInfoUpdate.html
    ZegoExpressEngine.onRoomExtraInfoUpdate =
        (String roomID, List<ZegoRoomExtraInfo> roomExtraInfoList) {
      if (_roomID == roomID) {
        if (onRoomExtraInfoUpdate != null) {
          onRoomExtraInfoUpdate!(roomExtraInfoList);
        }
      }
    };
  }

  /// User [user] joins into the room with id [roomID] with [options] and then can talk to others who are in the room
  ///
  /// Options are different from scenario to scenario, here are some example
  /// Video Call: [ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio, ZegoMediaOption.publishLocalVideo]
  /// Live Streaming: - host: [ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio, ZegoMediaOption.publishLocalVideo]
  /// Live Streaming: - audience:[ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio]
  /// Chat Room: - host:[ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio]
  /// Chat Room: - audience:[ZegoMediaOption.autoPlayAudio]
  Future<void> joinRoom(
      String roomID, ZegoUser user, ZegoMediaOptions options) async {
    _participantDic.clear();
    _streamDic.clear();

    _roomID = roomID;
    _mediaOptions = options;
    var participant = ZegoParticipant(user.userID, user.userName);
    participant.streamID = _generateStreamID(participant.userID, roomID);
    _participantDic[participant.userID] = participant;
    _streamDic[participant.streamID] = participant;
    _localParticipant = participant;

    // if you need limit participant count, you can change the max member count
    var roomConfig = ZegoRoomConfig(0, true, '');
    await ZegoExpressEngine.instance
        .loginRoom(roomID, user, config: roomConfig);
    if (_mediaOptions.contains(ZegoMediaOption.publishLocalAudio) ||
        _mediaOptions.contains(ZegoMediaOption.publishLocalVideo)) {
      participant.camera = options.contains(ZegoMediaOption.publishLocalVideo);
      participant.mic = options.contains(ZegoMediaOption.publishLocalAudio);
      ZegoExpressEngine.instance.startPublishingStream(participant.streamID);
      ZegoExpressEngine.instance.enableCamera(participant.camera);
      ZegoExpressEngine.instance.muteMicrophone(!participant.mic);

      _isPlayingStream = true;
    }
  }

  /// Return a widget with your own video
  Widget? getLocalVideoView() {
    if (_localParticipant.userID.isEmpty) {
      log("Error: [getLocalVideoView] You need to login room before you call getLocalVideoView");
      return null;
    }

    Widget? previewViewWidget =
        ZegoExpressEngine.instance.createPlatformView((viewID) {
      _localParticipant.viewID = viewID;

      // Start preview using platform view
      // Set the preview canvas
      ZegoCanvas previewCanvas = ZegoCanvas.view(viewID);
      // Start preview
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    });

    return previewViewWidget;
  }

  /// Return a widget that will render the video of a specific user
  ///
  /// Call this function after joining room
  Widget? getRemoteVideoView(String userID) {
    if (_roomID.isEmpty) {
      log("Error: [getRemoteVideoView] You need to join the room first and then get the videoView");
      return null;
    }

    if (userID.isEmpty) {
      log("Error: [getRemoteVideoView] userID is empty, please enter a right userID");
      return null;
    }

    if (!_participantDic.containsKey(userID)) {
      log("Error: [getRemoteVideoView] there is no user with id ($userID) in the room");
      return null;
    }

    if (_participantDic[userID]?.viewID != -1) {
      ZegoExpressEngine.instance
          .destroyPlatformView(_participantDic[userID]!.viewID);
    }

    Widget? playViewWidget =
        ZegoExpressEngine.instance.createPlatformView((viewID) {
      var participant = _participantDic[userID];
      participant!.viewID = viewID;

      _playStream(participant.streamID);
    });

    return playViewWidget;
  }

  /// Turn on your camera if [enable] is true
  void enableCamera(bool enable) {
    if (enable && !_isPlayingStream) {
      ZegoExpressEngine.instance
          .startPublishingStream(_localParticipant.streamID);
    } else if (!_mediaOptions.contains(ZegoMediaOption.publishLocalAudio) &&
        !_mediaOptions.contains(ZegoMediaOption.publishLocalVideo) &&
        !enable &&
        !_localParticipant.mic &&
        _isPlayingStream) {
      ZegoExpressEngine.instance.stopPublishingStream();
      ZegoExpressEngine.instance.stopPreview();

      _isPlayingStream = false;
    }

    ZegoExpressEngine.instance.enableCamera(enable);
    _localParticipant.camera = enable;
  }

  /// Turn on your microphone if [enable] is true
  void enableMic(bool enable) {
    if (enable && !_isPlayingStream) {
      ZegoExpressEngine.instance
          .startPublishingStream(_localParticipant.streamID);
    } else if (!_mediaOptions.contains(ZegoMediaOption.publishLocalAudio) &&
        !_mediaOptions.contains(ZegoMediaOption.publishLocalVideo) &&
        !enable &&
        !_localParticipant.camera &&
        _isPlayingStream) {
      ZegoExpressEngine.instance.stopPublishingStream();
      ZegoExpressEngine.instance.stopPreview();

      _isPlayingStream = false;
    }
    ZegoExpressEngine.instance.muteMicrophone(!enable);
    _localParticipant.mic = enable;
  }

  /// Turn on your speaker if [enable] is true
  void enableSpeaker(bool enable) {
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(enable);
    // ZegoExpressEngine.instance.muteSpeaker(!enable);
  }

  /// Switch to the front camera if [isFront] is true
  void switchFrontCamera(bool isFront) {
    ZegoExpressEngine.instance.useFrontCamera(isFront);
  }

  /// Leave the room when you are done the talk or if you want to join another room
  void leaveRoom() {
    ZegoExpressEngine.instance.stopPublishingStream();
    ZegoExpressEngine.instance.stopPreview();
    _participantDic.forEach((_, participant) {
      if (participant.viewID != -1) {
        ZegoExpressEngine.instance.destroyPlatformView(participant.viewID);
      }
    });
    _participantDic.clear();
    _streamDic.clear();
    _roomID = '';
    ZegoExpressEngine.instance.logoutRoom();

    _isPlayingStream = false;
  }

  /// Set a new token to keep access ZEGOCLOUD's SDK while onRoomTokenWillExpire has been triggered
  void renewToken(String roomID, String token) {
    ZegoExpressEngine.instance.renewToken(roomID, token);
  }

  /// Set room extra information
  ///
  /// You can set some room-related business attributes, such as whether someone is Co-hosting.
  /// You should call it after joining the room.
  /// Restrictions: https://docs.zegocloud.com/article/7611
  Future<int> setRoomExtraInfo(String key, String value) async {
    if (_roomID.isEmpty) {
      log('Please login the room first');
      return -1;
    }
    var result =
        await ZegoExpressEngine.instance.setRoomExtraInfo(_roomID, key, value);
    return result.errorCode;
  }

  String _generateStreamID(String userID, String roomID) {
    if (userID.isEmpty || roomID.isEmpty) {
      log("Error: [generateStreamID] userID or roomID is empty, please enter a right userID");
      return "";
    }

    // The streamID can use any character.
    // For the convenience of query, roomID + UserID + suffix is used here.
    String streamID = roomID + userID + "_main";
    return streamID;
  }

  void _playStream(String streamID) {
    if (!_mediaOptions.contains(ZegoMediaOption.autoPlayVideo) &&
        !_mediaOptions.contains(ZegoMediaOption.autoPlayAudio)) {
      log("[playStream] media options not contain play video or play audio");
      return;
    }

    if (_mediaOptions.contains(ZegoMediaOption.autoPlayVideo)) {
      ZegoParticipant? participant = _streamDic[streamID];
      if (participant == null) {
        return;
      }
      if (participant.viewID == -1) {
        log("Error [_playStream] view id is empty!");
        return;
      }
      ZegoCanvas canvas = ZegoCanvas.view(participant.viewID);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    } else {
      ZegoExpressEngine.instance.startPlayingStream(streamID);
    }

    if (!_mediaOptions.contains(ZegoMediaOption.autoPlayVideo)) {
      ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
    }
    if (!_mediaOptions.contains(ZegoMediaOption.autoPlayAudio)) {
      ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
    }
  }

  void _processLog(String methodName, int state, int errorCode) {
    String description = "";
    if (errorCode != 0) {
      description =
          "=======\nYou can view the exact cause of the error through the link below \n https://doc-zh.zego.im/article/4377?w=$errorCode\n=======";
    }
    log("[$methodName]: state:$state errorCode:$errorCode\n$description");
  }
}
