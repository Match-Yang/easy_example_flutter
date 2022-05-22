import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'call_event.dart';
part 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  static var shared = CallBloc();

  CallBloc() : super(CallInitial()) {
    on<CallReceiveInvited>((event, emit) {
      emit(CallInviteReceiving(event.callerUserID, event.callerUserName,
          event.callerIconUrl, event.roomID, event.isGroupCall));
    });

    on<CallInviteDecline>((event, emit) {
      emit(CallInitial());
    });

    on<CallInviteAccept>((event, emit) {
      emit(CallInviteAccepted(event.roomID, event.isGroupCall));
      emit(CallInitial());
    });
  }
}
