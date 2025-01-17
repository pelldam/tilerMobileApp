import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/util.dart';

part 'ui_date_manager_event.dart';
part 'ui_date_manager_state.dart';

class UiDateManagerBloc extends Bloc<UiDateManagerEvent, UiDateManagerState> {
  UiDateManagerBloc() : super(UiDateManagerInitial()) {
    on<DateChange>(_onDayDateChange);
  }

  _onDayDateChange(DateChange event, Emitter emit) {
    DateTime previousDate =
        event.previousSelectedDate ?? Utility.currentTime().dayDate;
    DateTime updatedDate = event.selectedDate;

    if (state is UiDateManagerUpdated) {
      previousDate = (state as UiDateManagerUpdated).currentDate;
    }
    emit(UiDateManagerUpdated(
        currentDate: updatedDate, previousDate: previousDate));
  }
}
