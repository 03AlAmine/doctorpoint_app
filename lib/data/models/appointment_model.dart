class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final double amount;
  final String? prescriptionUrl;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    required this.type,
    this.notes,
    required this.amount,
    this.prescriptionUrl,
  });
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rescheduled,
}

enum AppointmentType {
  videoCall,
  voiceCall,
  inPerson,
  chat,
}