import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import 'package:tapem/domain/usecases/report/fetch_report_data.dart' show FetchReportDataUseCase;

/// Bloc für das Report-Feature.
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final FetchReportDataUseCase _fetchData;

  ReportBloc({ required FetchReportDataUseCase fetchData }) 
    : _fetchData = fetchData,
      super(ReportInitial()) {
    on<ReportLoadAll>(_onLoadAll);
  }

  Future<void> _onLoadAll(
    ReportLoadAll event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final entries = await _fetchData(
        gymId: event.gymId,
        deviceId: event.deviceId,
        start: event.start,
        end: event.end,
      );
      emit(ReportLoadSuccess(entries));
    } catch (e) {
      emit(ReportFailure(e.toString()));
    }
  }
}
