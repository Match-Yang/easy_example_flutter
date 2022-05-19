part of 'call_bloc.dart';

@immutable
abstract class CallEvent {}

class CallReceiveInvited extends CallEvent {
  final String callerUserID;
  final String callerUserName;
  final String callerIconUrl;
  final String roomID;
  CallReceiveInvited(
      this.callerUserID, this.callerUserName, this.callerIconUrl, this.roomID);
}

class CallInviteDecline extends CallEvent {}

class CallInviteAccept extends CallEvent {
  final String roomID;
  CallInviteAccept(this.roomID);
}
