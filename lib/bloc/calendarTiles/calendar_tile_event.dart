part of 'calendar_tile_bloc.dart';

abstract class CalendarTileEvent extends Equatable {
  const CalendarTileEvent();

  @override
  List<Object> get props => [];
}

class CalendarTileAsNowEvent extends CalendarTileEvent {
  final String calEventId;
  CalendarTileAsNowEvent({required this.calEventId});
}

class GetCalendarTileEvent extends CalendarTileEvent {
  final String calEventId;
  GetCalendarTileEvent({required this.calEventId});
}

class DeleteCalendarTileEvent extends CalendarTileEvent {
  final String calEventId;
  final String thirdPartyId;
  DeleteCalendarTileEvent(
      {required this.calEventId, required this.thirdPartyId});
}

class CompleteCalendarTileEvent extends CalendarTileEvent {
  final String calEventId;
  CompleteCalendarTileEvent({required this.calEventId});
}
