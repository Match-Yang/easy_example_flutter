part of 'call_bloc.dart';

@immutable
abstract class CallEvent {}

class CallReceiveInvited extends CallEvent {
  final String callerUserID;
  final String callerUserName;
  final String callerIconUrl;
  final String roomID;
  final bool isGroupCall;

  CallReceiveInvited(this.callerUserID, this.callerUserName, this.callerIconUrl,
      this.roomID, this.isGroupCall);
}

class CallInviteDecline extends CallEvent {}

class CallInviteAccept extends CallEvent {
  final String roomID;
  final bool isGroupCall;
  final bool fromBackground;

  CallInviteAccept(this.roomID, this.isGroupCall, this.fromBackground);

  @override
  String toString() {
    return "room id:$roomID, is group call:$isGroupCall, from background:$fromBackground";
  }
}
