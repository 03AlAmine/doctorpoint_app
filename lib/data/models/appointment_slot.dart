// lib/data/models/appointment_slot.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentSlot {
  final String id;
  final String doctorId;
  final DateTime date;
  final String time;
  final bool isAvailable;
  final String? appointmentId;
  final DateTime createdAt;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    this.isAvailable = true,
    this.appointmentId,
    required this.createdAt,
  });

  factory AppointmentSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppointmentSlot(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      appointmentId: data['appointmentId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'isAvailable': isAvailable,
      'appointmentId': appointmentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentSlot copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    String? time,
    bool? isAvailable,
    String? appointmentId,
    DateTime? createdAt,
  }) {
    return AppointmentSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      time: time ?? this.time,
      isAvailable: isAvailable ?? this.isAvailable,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}