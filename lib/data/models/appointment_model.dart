import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String doctorSpecialization;
  final String doctorImage;
  final DateTime dateTime;
  final String status; // pending, confirmed, completed, cancelled
  final String type; // video, audio, in_person
  final String? notes;
  final double amount;
  final String? symptoms;
  final String? prescriptionUrl;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.doctorImage,
    required this.dateTime,
    required this.status,
    required this.type,
    this.notes,
    required this.amount,
    this.symptoms,
    this.prescriptionUrl,
    required this.createdAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialization: data['doctorSpecialization'] ?? '',
      doctorImage: data['doctorImage'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'video',
      notes: data['notes'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      symptoms: data['symptoms'],
      prescriptionUrl: data['prescriptionUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'doctorImage': doctorImage,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'type': type,
      'notes': notes,
      'amount': amount,
      'symptoms': symptoms,
      'prescriptionUrl': prescriptionUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedDate {
    return '${_getWeekday(dateTime.weekday)} ${dateTime.day} ${_getMonth(dateTime.month)}';
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mer';
      case 4: return 'Jeu';
      case 5: return 'Ven';
      case 6: return 'Sam';
      case 7: return 'Dim';
      default: return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Fév';
      case 3: return 'Mar';
      case 4: return 'Avr';
      case 5: return 'Mai';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aoû';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Déc';
      default: return '';
    }
  }
}