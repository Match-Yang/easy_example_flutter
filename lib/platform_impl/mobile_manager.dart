import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'base_manager.dart';
import 'types.dart';

class ManagerImpl extends BaseManager {
  @override
  void createEngine(int appID, {String serverUrl = ''}) {
    // if your scenario is live,you can change to ZegoScenario.Live.
    // if your scenario is communication , you can change to ZegoScenario.Communication
    ZegoEngineProfile profile = ZegoEngineProfile(appID, ZegoScenario.General,
        enablePlatformView: true);

    ZegoExpressEngine.createEngineWithProfile(profile);

    // Setup event handler
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID,
        ZegoUpdateType updateType,
        List<ZegoStream> streamList,
        Map<String, dynamic> extendedData) {
      for (final stream in streamList) {
        if (updateType == ZegoUpdateType.Add) {
          playStream_(stream.streamID);
        } else {
          ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        }
      }
    };
    ZegoExpressEngine.onRoomUserUpdate =
        (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      List<String> userIDList = [];
      if (updateType == ZegoUpdateType.Add) {
        for (final user in userList) {
          userIDList.add(user.userID);
          ZegoParticipant participant =
              ZegoParticipant(user.userID, user.userName);
          participant.streamID = generateStreamID_(user.userID, roomID);
          participantDic_[participant.userID] = participant;
          streamDic_[participant.streamID] = participant;
        }
      } else {
        for (final user in userList) {
          userIDList.add(user.userID);
          if (participantDic_.containsKey(user.userID)) {
            var participant = participantDic_[user.userID];
            ZegoExpressEngine.instance.destroyPlatformView(participant!.viewID);

            streamDic_.remove(participantDic_[user.userID]!.streamID);
            participantDic_.remove(user.userID);
          }
        }
      }
      if (onRoomUserUpdate != null) {
        onRoomUserUpdate!(updateType, userIDList, roomID);
      }
    };
    ZegoExpressEngine.onRemoteCameraStateUpdate =
        (String streamID, ZegoRemoteDeviceState state) {
      if (streamDic_.containsKey(streamID)) {
        var participant = streamDic_[streamID];
        participant!.camera = ZegoRemoteDeviceState.Open == state;
        var type = state == ZegoRemoteDeviceState.Open
            ? ZegoDeviceUpdateType.cameraOpen
            : ZegoDeviceUpdateType.cameraClose;
        if (onRoomUserDeviceUpdate != null) {
          onRoomUserDeviceUpdate!(type, participant.userID, roomID_);
        }
      }
    };
    ZegoExpressEngine.onRemoteMicStateUpdate =
        (String streamID, ZegoRemoteDeviceState state) {
      if (streamDic_.containsKey(streamID)) {
        var participant = streamDic_[streamID];
        participant!.mic = ZegoRemoteDeviceState.Open == state;
        var type = state == ZegoRemoteDeviceState.Open
            ? ZegoDeviceUpdateType.micUnMute
            : ZegoDeviceUpdateType.micMute;
        if (onRoomUserDeviceUpdate != null) {
          onRoomUserDeviceUpdate!(type, participant.userID, roomID_);
        }
      }
    };
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state,
        int errorCode, Map<String, dynamic> extendedData) {
      processLog_("onRoomStateUpdate", state.index, errorCode);
    };
    ZegoExpressEngine.onPublisherStateUpdate = (String streamID,
        ZegoPublisherState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      processLog_("onPublisherStateUpdate", state.index, errorCode);
    };
    ZegoExpressEngine.onPlayerStateUpdate = (String streamID,
        ZegoPlayerState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      processLog_("onPlayerStateUpdate", state.index, errorCode);
    };
    ZegoExpressEngine.onNetworkQuality = (String userID,
        ZegoStreamQualityLevel upstreamQuality,
        ZegoStreamQualityLevel downstreamQuality) {
      if (!participantDic_.containsKey(userID)) {
        return;
      }
      var participant = participantDic_[userID];
      if (userID == localParticipant_.userID) {
        participant!.network = downstreamQuality;
      } else {
        participant!.network = upstreamQuality;
      }
    };
    ZegoExpressEngine.onRoomTokenWillExpire =
        (String roomID, int remainTimeInSecond) {
      if (onRoomTokenWillExpire != null) {
        onRoomTokenWillExpire!(remainTimeInSecond, roomID);
      }
    };
  }

  @override
  void joinRoom(
      String roomID, ZegoUser user, String token, ZegoMediaOptions options) {
    participantDic_.clear();
    streamDic_.clear();
    if (token.isEmpty) {
      log("Error: [joinRoom] token is empty, please enter a right token");
      return;
    }
    roomID_ = roomID;
    mediaOptions_ = options;
    var participant = ZegoParticipant(user.userID, user.userName);
    participant.streamID = generateStreamID_(participant.userID, roomID);
    participantDic_[participant.userID] = participant;
    streamDic_[participant.streamID] = participant;
    localParticipant_ = participant;

    // if you need limit participant count, you can change the max member count
    var roomConfig = ZegoRoomConfig(0, true, token);
    ZegoExpressEngine.instance.loginRoom(roomID, user, config: roomConfig);
    if (mediaOptions_.contains(ZegoMediaOption.publishLocalAudio) ||
        mediaOptions_.contains(ZegoMediaOption.publishLocalVideo)) {
      participant.camera = options.contains(ZegoMediaOption.publishLocalVideo);
      participant.mic = options.contains(ZegoMediaOption.publishLocalAudio);
      ZegoExpressEngine.instance.startPublishingStream(participant.streamID);
      ZegoExpressEngine.instance.enableCamera(participant.camera);
      ZegoExpressEngine.instance.muteMicrophone(!participant.mic);
    }
  }

  @override
  void leaveRoom() {
    ZegoExpressEngine.instance.stopPublishingStream();
    ZegoExpressEngine.instance.stopPreview();
    participantDic_.forEach((_, participant) {
      if (participant.viewID != -1) {
        ZegoExpressEngine.instance.destroyPlatformView(participant.viewID);
      }
    });
    participantDic_.clear();
    streamDic_.clear();
    roomID_ = '';
    ZegoExpressEngine.instance.logoutRoom();
  }

  @override
  Widget? getLocalVideoView() {
    if (localParticipant_.userID.isEmpty) {
      log("Error: [getLocalVideoView] You need to login room before you call getLocalVideoView");
      return null;
    }
    Widget? previewViewWidget =
        ZegoExpressEngine.instance.createPlatformView((viewID) {
      localParticipant_.viewID = viewID;

      // Start preview using platform view
      // Set the preview canvas
      ZegoCanvas previewCanvas = ZegoCanvas.view(viewID);
      // Start preview
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    });
    return previewViewWidget;
  }

  @override
  Widget? getRemoteVideoView(String userID) {
    if (roomID_.isEmpty) {
      log("Error: [getRemoteVideoView] You need to join the room first and then get the videoView");
      return null;
    }
    if (userID.isEmpty) {
      log("Error: [getRemoteVideoView] userID is empty, please enter a right userID");
      return null;
    }
    if (!participantDic_.containsKey(userID)) {
      log("Error: [getRemoteVideoView] there is no user with id ($userID) in the room");
      return null;
    } else {
      if (participantDic_[userID]?.viewID != -1) {
        return participantDic_[userID]?.view;
      } else {
        Widget? playViewWidget =
            ZegoExpressEngine.instance.createPlatformView((viewID) {
          var participant = participantDic_[userID];
          participant!.viewID = viewID;

          playStream_(participant.streamID);
        });
        return playViewWidget;
      }
    }
  }

  @override
  void enableCamera(bool enable) {
    ZegoExpressEngine.instance.enableCamera(enable);
    localParticipant_.camera = enable;
  }

  @override
  void enableMic(bool enable) {
    ZegoExpressEngine.instance.muteMicrophone(!enable);
    localParticipant_.mic = enable;
  }

  @override
  void switchFrontCamera(bool isFront) {
    ZegoExpressEngine.instance.useFrontCamera(isFront);
  }
}
