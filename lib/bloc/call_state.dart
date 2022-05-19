part of 'call_bloc.dart';

@immutable
abstract class CallState {}

class CallInitial extends CallState {}

class CallInviteReceiving extends CallState {
  final String callerUserID;
  final String callerUserName;
  final String callerIconUrl;
  final String roomID;
  CallInviteReceiving(
      this.callerUserID, this.callerUserName, this.callerIconUrl, this.roomID);
}

class CallInviteAccepted extends CallState {
  final String roomID;
  CallInviteAccepted(this.roomID);
}
