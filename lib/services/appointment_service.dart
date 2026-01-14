// lib/services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_availability.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Vérifier la disponibilité
  Future<bool> checkAvailability({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    try {
      // Récupérer l'agenda du médecin
      final availabilityDoc = await _db
          .collection('doctor_availability')
          .doc(doctorId)
          .get();

      if (!availabilityDoc.exists) {
        throw Exception('Agenda non configuré pour ce médecin');
      }

      // Vérifier si le créneau est disponible
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      return appointmentsSnapshot.docs.isEmpty;
    } catch (e) {
      print('Erreur vérification disponibilité: $e');
      return false;
    }
  }

  // Prendre rendez-vous
  Future<void> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime date,
    required String time,
    required String type,
    required double amount,
    String? notes,
    String? symptoms,
  }) async {
    try {
      // Vérifier la disponibilité
      final isAvailable = await checkAvailability(
        doctorId: doctorId,
        date: date,
        time: time,
      );

      if (!isAvailable) {
        throw Exception('Ce créneau n\'est plus disponible');
      }

      // Récupérer les infos du médecin
      final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw Exception('Médecin non trouvé');
      }

      final doctorData = doctorDoc.data()!;

      // Créer le rendez-vous
      await _db.collection('appointments').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'doctorName': doctorData['name'],
        'doctorSpecialization': doctorData['specialization'],
        'doctorImage': doctorData['imageUrl'],
        'date': DateFormat('yyyy-MM-dd').format(date),
        'time': time,
        'dateTime': Timestamp.fromDate(date),
        'status': 'pending',
        'type': type,
        'amount': amount,
        'notes': notes,
        'symptoms': symptoms,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envoyer une notification au médecin
      await _sendNotificationToDoctor(
        doctorId: doctorId,
        patientId: patientId,
        date: date,
        time: time,
      );

    } catch (e) {
      print('Erreur prise de rendez-vous: $e');
      rethrow;
    }
  }

  // Annuler un rendez-vous
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Envoyer une notification
      final appointmentDoc = await _db
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (appointmentDoc.exists) {
        final data = appointmentDoc.data()!;
        await _sendCancellationNotification(
          doctorId: data['doctorId'],
          patientId: data['patientId'],
          date: data['date'],
          time: data['time'],
        );
      }
    } catch (e) {
      print('Erreur annulation rendez-vous: $e');
      rethrow;
    }
  }

  // Confirmer un rendez-vous
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur confirmation rendez-vous: $e');
      rethrow;
    }
  }

  // Récupérer les rendez-vous d'un médecin
  Stream<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                  'date': doc['date'],
                  'time': doc['time'],
                })
            .toList());
  }

  // Récupérer les rendez-vous d'un patient
  Stream<List<Map<String, dynamic>>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                  'date': doc['date'],
                  'time': doc['time'],
                })
            .toList());
  }

  // Récupérer les créneaux disponibles
  Future<List<String>> getAvailableTimeSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      // Récupérer l'agenda du médecin
      final availabilityDoc = await _db
          .collection('doctor_availability')
          .doc(doctorId)
          .get();

      if (!availabilityDoc.exists) {
        return [];
      }

      final availability = DoctorAvailability.fromMap({
        ...availabilityDoc.data()!,
        'doctorId': doctorId,
      });

      // Récupérer les rendez-vous existants
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      final bookedTimes = appointmentsSnapshot.docs
          .map((doc) => doc['time'] as String)
          .toSet();

      final availableSlots = availability.getAvailableTimeSlots(date);

      return availableSlots
          .where((slot) => !bookedTimes.contains(slot))
          .toList();
    } catch (e) {
      print('Erreur récupération créneaux: $e');
      return [];
    }
  }

  // Envoyer notification au médecin
  Future<void> _sendNotificationToDoctor({
    required String doctorId,
    required String patientId,
    required DateTime date,
    required String time,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': doctorId,
        'title': 'Nouveau rendez-vous',
        'message': 'Un patient a pris rendez-vous pour le ${DateFormat('dd/MM/yyyy').format(date)} à $time',
        'type': 'appointment',
        'data': {
          'patientId': patientId,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'time': time,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification: $e');
    }
  }

  // Envoyer notification d'annulation
  Future<void> _sendCancellationNotification({
    required String doctorId,
    required String patientId,
    required String date,
    required String time,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': doctorId,
        'title': 'Rendez-vous annulé',
        'message': 'Un rendez-vous a été annulé pour le ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(date))} à $time',
        'type': 'appointment_cancelled',
        'data': {
          'patientId': patientId,
          'date': date,
          'time': time,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification annulation: $e');
    }
  }
}