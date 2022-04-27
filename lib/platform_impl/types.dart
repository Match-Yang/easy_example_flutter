
import 'package:flutter/cupertino.dart';
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

enum ZegoDeviceUpdateType { cameraOpen, cameraClose, micUnMute, micMute }

enum ZegoMediaOption {
  autoPlayAudio,
  autoPlayVideo,
  publishLocalAudio,
  publishLocalVideo
}

typedef ZegoMediaOptions = List<ZegoMediaOption>;