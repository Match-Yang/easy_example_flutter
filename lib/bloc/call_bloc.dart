import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'call_event.dart';

part 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  static var shared = CallBloc();

  CallInviteAccept? backgroundAcceptEventCache;

  CallBloc() : super(CallInitial()) {
    on<CallReceiveInvited>((event, emit) {
      emit(CallInviteReceiving(event.callerUserID, event.callerUserName,
          event.callerIconUrl, event.roomID, event.isGroupCall));
    });

    on<CallInviteDecline>((event, emit) {
      emit(CallInitial());
    });

    on<CallInviteAccept>((event, emit) {
      if (event.fromBackground) {
        backgroundAcceptEventCache = event;
      } else {
        emit(CallInviteAccepted(event.roomID, event.isGroupCall));
        emit(CallInitial());
      }
    });
  }

  void flushBackgroundCache() {
    if (null != backgroundAcceptEventCache) {
      add(
        CallInviteAccept(
          backgroundAcceptEventCache!.roomID,
          backgroundAcceptEventCache!.isGroupCall,
          false,
        ),
      );

      backgroundAcceptEventCache = null;
    }
  }
}
