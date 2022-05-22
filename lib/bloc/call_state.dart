part of 'call_bloc.dart';

@immutable
abstract class CallState {}

class CallInitial extends CallState {}

class CallInviteReceiving extends CallState {
  final String callerUserID;
  final String callerUserName;
  final String callerIconUrl;
  final String roomID;
  final bool isGroupCall;
  CallInviteReceiving(this.callerUserID, this.callerUserName,
      this.callerIconUrl, this.roomID, this.isGroupCall);
}

class CallInviteAccepted extends CallState {
  final String roomID;
  final bool isGroupCall;
  CallInviteAccepted(this.roomID, this.isGroupCall);
}
