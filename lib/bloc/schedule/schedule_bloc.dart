import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleApi scheduleApi = ScheduleApi();
  ScheduleBloc() : super(ScheduleInitialState()) {
    on<GetScheduleEvent>(_onGetSchedule);
    on<LogInScheduleEvent>(_onInitialLogInScheduleEvent);
    on<LogOutScheduleEvent>(_onLoggedOutScheduleEvent);
    on<DelayedGetSchedule>(_onDelayedGetSchedule);
    on<ReloadLocalScheduleEvent>(_onLocalScheduleEvent);
    on<DelayedReloadLocalScheduleEvent>(_onDelayedReloadLocalScheduleEvent);
    on<ReviseScheduleEvent>(_onReviseSchedule);
    on<EvaluateSchedule>(_onEvaluateSchedule);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubTiles(
      Timeline timeLine) async {
    Utility.isDebugSet = true;
    return await scheduleApi.getSubEvents(timeLine);
  }

  void _onLocalScheduleEvent(
      ReloadLocalScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        lookupTimeline: event.lookupTimeline));
  }

  void _onDelayedReloadLocalScheduleEvent(DelayedReloadLocalScheduleEvent event,
      Emitter<ScheduleState> emit) async {
    var setTimeOutResult = Utility.setTimeOut(duration: event.duration);

    emit(DelayedScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        lookupTimeline: event.lookupTimeline,
        pendingDelayedScheduleRetrieval:
            setTimeOutResult.item1.asStream().listen((futureEvent) async {})));

    await setTimeOutResult.item1.then((futureEvent) async {
      emit(ScheduleLoadedState(
          subEvents: event.subEvents,
          timelines: event.timelines,
          lookupTimeline: event.lookupTimeline));
    });
  }

  void _onLoggedOutScheduleEvent(
      LogOutScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoggedOutState());
  }

  void _onInitialLogInScheduleEvent(
      LogInScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleInitialState());
  }

  // Future<void> _onIncrementGetSchedule(
  //     IncrementGetScheduleEvent event, Emitter<ScheduleState> emit) async {}

  Future<void> _onGetSchedule(
      GetScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    Timeline updateTimeline =
        event.scheduleTimeline ?? Utility.initialScheduleTimeline;

    if (state is ScheduleLoadedState) {
      Timeline timeline = state.lookupTimeline;
      updateTimeline = event.scheduleTimeline ?? state.lookupTimeline;

      if (!timeline.isInterfering(updateTimeline)) {
        int startInMs = updateTimeline.start! < timeline.start!
            ? updateTimeline.start!
            : timeline.start!;
        int endInMs = updateTimeline.end! > timeline.end!
            ? updateTimeline.end!
            : timeline.end!;

        updateTimeline = Timeline.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(startInMs.toInt(), isUtc: true),
            DateTime.fromMillisecondsSinceEpoch(endInMs.toInt(), isUtc: true));
      }
      emit(ScheduleLoadingState(
          subEvents: List.from(state.subEvents),
          timelines: state.timelines,
          previousLookupTimeline: timeline,
          isAlreadyLoaded: event.isAlreadyLoaded ?? true,
          evaluationTime: Utility.currentTime(),
          connectionState: ConnectionState.waiting));
      await getSubTiles(updateTimeline).then((value) {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }

    if (state is ScheduleInitialState) {
      emit(ScheduleLoadingState(
          subEvents: [],
          timelines: [],
          isAlreadyLoaded: event.isAlreadyLoaded ?? false,
          evaluationTime: Utility.currentTime(),
          connectionState: ConnectionState.waiting));

      await getSubTiles(updateTimeline).then((value) {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }

    if (state is ScheduleEvaluationState) {
      emit(ScheduleLoadingState(
          subEvents: state.subEvents,
          timelines: state.timelines,
          previousLookupTimeline: state.lookupTimeline,
          isAlreadyLoaded: true,
          connectionState: ConnectionState.waiting,
          evaluationTime: Utility.currentTime()));

      await getSubTiles(updateTimeline).then((value) async {
        emit(ScheduleLoadedState(
            subEvents: value.item2,
            timelines: value.item1,
            lookupTimeline: updateTimeline));
      });
      return;
    }
  }

  Future<void> _onReviseSchedule(
      ReviseScheduleEvent event, Emitter<ScheduleState> emit) async {
    final state = this.state;
    if (state is ScheduleLoadedState) {
      emit(ScheduleEvaluationState(
          subEvents: state.subEvents,
          timelines: state.timelines,
          lookupTimeline: state.lookupTimeline,
          evaluationTime: Utility.currentTime(),
          message: event.message));
      await this.scheduleApi.reviseSchedule().then((value) async {
        await this._onGetSchedule(
            GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: state.subEvents,
              previousTimeline: state.lookupTimeline,
              scheduleTimeline: state.lookupTimeline,
            ),
            emit);
      });
    }
  }

  void _onEvaluateSchedule(
      EvaluateSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleEvaluationState(
        subEvents: event.renderedSubEvents,
        timelines: event.renderedTimelines,
        lookupTimeline: event.renderedScheduleTimeline,
        evaluationTime: Utility.currentTime(),
        message: event.message));
    if (event.callBack != null) {
      await event.callBack!.whenComplete(() async {
        await this._onGetSchedule(
            GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: event.renderedSubEvents,
              previousTimeline: event.renderedScheduleTimeline,
              scheduleTimeline: event.renderedScheduleTimeline,
            ),
            emit);
      });
    }
  }

  void _onDelayedGetSchedule(
      DelayedGetSchedule event, Emitter<ScheduleState> emit) async {
    var setTimeOutResult = Utility.setTimeOut(duration: event.delayDuration!);

    emit(DelayedScheduleLoadedState(
        subEvents: event.previousSubEvents,
        timelines: event.renderedTimelines,
        lookupTimeline: event.scheduleTimeline,
        pendingDelayedScheduleRetrieval:
            setTimeOutResult.item1.asStream().listen((futureEvent) async {})));

    await setTimeOutResult.item1.then((futureEvent) async {
      await this._onGetSchedule(
          GetScheduleEvent(
            isAlreadyLoaded: true,
            previousSubEvents: event.previousSubEvents,
            previousTimeline: event.previousTimeline,
            scheduleTimeline: event.scheduleTimeline,
          ),
          emit);
    });
  }
}
