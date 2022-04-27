import 'dart:developer';

import 'types.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// key is user id, value is participant model
typedef UserIDParticipantMap = Map<String, ZegoParticipant>;
// key is user id, value is view id
typedef UserIDViewIDMap = Map<String, int>;
// key is stream id, value is participant model
typedef StreamIDParticipantMap = Map<String, ZegoParticipant>;

abstract class BaseManager {
  String testParam = '';
  void Function(
          ZegoUpdateType updateType, List<String> userIDList, String roomID)?
      onRoomUserUpdate;
  void Function(ZegoDeviceUpdateType updateType, String userID, String roomID)?
      onRoomUserDeviceUpdate;
  void Function(int remainTimeInSecond, String roomID)? onRoomTokenWillExpire;

  ZegoParticipant localParticipant_ = ZegoParticipant("", "");
  UserIDParticipantMap participantDic_ = {};
  StreamIDParticipantMap streamDic_ = {};
  String roomID_ = "";
  ZegoMediaOptions mediaOptions_ = [
    ZegoMediaOption.autoPlayAudio,
    ZegoMediaOption.autoPlayVideo
  ];

  void createEngine(int appID, {String serverUrl = ''});

  void joinRoom(
      String roomID, ZegoUser user, String token, ZegoMediaOptions options);

  void leaveRoom();

  Widget? getLocalVideoView();

  Widget? getRemoteVideoView(String userID);

  void enableCamera(bool enable);

  void enableMic(bool enable);

  void switchFrontCamera(bool isFront);

  String generateStreamID_(String userID, String roomID) {
    if (userID.isEmpty || roomID.isEmpty) {
      log("Error: [generateStreamID] userID or roomID is empty, please enter a right userID");
      return "";
    }

    // The streamID can use any character.
    // For the convenience of query, roomID + UserID + suffix is used here.
    String streamID = roomID + userID + "_main";
    return streamID;
  }

  void playStream_(String streamID) {
    if (mediaOptions_.contains(ZegoMediaOption.autoPlayVideo) ||
        mediaOptions_.contains(ZegoMediaOption.autoPlayAudio)) {
      ZegoParticipant? participant = streamDic_[streamID];
      if (participant == null) {
        return;
      }
      if (participant.viewID == -1) {
        log("Error [_playStream] view id is empty!");
        return;
      }
      ZegoCanvas canvas = ZegoCanvas.view(participant.viewID);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
      if (!mediaOptions_.contains(ZegoMediaOption.autoPlayVideo)) {
        ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
      }
      if (!mediaOptions_.contains(ZegoMediaOption.autoPlayAudio)) {
        ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
      }
    }
  }

  void processLog_(String methodName, int state, int errorCode) {
    String description = "";
    if (errorCode != 0) {
      description =
          "=======\nYou can view the exact cause of the error through the link below \n https://doc-zh.zego.im/article/4377?w=$errorCode\n=======";
    }
    log("[$methodName]: state:$state errorCode:$errorCode\n$description");
  }
}
