import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'appointment_event.dart';
part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository _repository;

  AppointmentBloc(this._repository) : super(AppointmentInitial()) {
    on<LoadAppointments>(_onLoadAppointments);
    on<BookAppointment>(_onBookAppointment);
    on<CancelAppointment>(_onCancelAppointment);
    on<UpdateAppointmentStatus>(_onUpdateAppointmentStatus);
  }

  Future<void> _onLoadAppointments(
    LoadAppointments event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final appointments = await _repository.getAppointments();
      emit(AppointmentLoaded(appointments));
    } catch (e) {
      emit(AppointmentError(e.toString()));
    }
  }

  Future<void> _onBookAppointment(
    BookAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      final appointment = await _repository.bookAppointment(event.appointment);
      final currentState = state as AppointmentLoaded;
      emit(AppointmentLoaded([
        appointment,
        ...currentState.appointments,
      ]));
    } catch (e) {
      emit(AppointmentError(e.toString()));
    }
  }
}