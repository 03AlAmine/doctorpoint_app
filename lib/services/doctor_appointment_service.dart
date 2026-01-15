// lib/services/doctor_appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupérer les rendez-vous d'un médecin
  Stream<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'];
        Map<String, dynamic>? patientInfo;

        // Récupérer les infos du patient
        final userDoc = await _db.collection('users').doc(patientId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          patientInfo = {
            'id': patientId,
            'name': userData['fullName'] ?? 'Patient',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
          };
        }
        appointments.add({
          'id': doc.id,
          'patient': patientInfo,
          'doctor': data['doctor'],
          'date': data['date'],
          'time': data['time'],
          'type': data['type'] ?? 'Présentiel',
          'status': data['status'] ?? 'pending',
          'reason': data['reason'] ?? 'Consultation',
          'symptoms': data['symptoms'],
          'notes': data['notes'],
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'paymentStatus': data['paymentStatus'] ?? 'pending',
          'cancellationReason': data['cancellationReason'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'confirmedAt': (data['confirmedAt'] as Timestamp?)?.toDate(),
          'cancelledAt': (data['cancelledAt'] as Timestamp?)?.toDate(),
        });
      }

      return appointments;
    });
  }

  // Confirmer un rendez-vous
  Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Envoyer notification au patient
      await _sendConfirmationNotification(appointmentId);

      return {
        'success': true,
        'message': 'Rendez-vous confirmé avec succès',
      };
    } catch (e) {
      print('Erreur confirmation rendez-vous: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Rejeter un rendez-vous
  Future<Map<String, dynamic>> rejectAppointment(
    String appointmentId,
    String reason,
  ) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Libérer le créneau
      final appointmentDoc =
          await _db.collection('appointments').doc(appointmentId).get();
      if (appointmentDoc.exists) {
        final data = appointmentDoc.data()!;
        final doctorId = data['doctorId'];
        final date = data['date'];
        final time = data['time'];

        if (doctorId != null && date != null && time != null) {
          final slotId = '${doctorId}_${date}_$time';
          await _db.collection('appointment_slots').doc(slotId).update({
            'isAvailable': true,
            'appointmentId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Envoyer notification au patient
      await _sendRejectionNotification(appointmentId, reason);

      return {
        'success': true,
        'message': 'Rendez-vous rejeté avec succès',
      };
    } catch (e) {
      print('Erreur rejet rendez-vous: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Marquer comme terminé
  Future<Map<String, dynamic>> completeAppointment(
    String appointmentId, {
    String? notes,
    String? prescription,
  }) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'doctorNotes': notes,
        'prescription': prescription,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Envoyer notification au patient
      await _sendCompletionNotification(appointmentId);

      return {
        'success': true,
        'message': 'Rendez-vous marqué comme terminé',
      };
    } catch (e) {
      print('Erreur complétion rendez-vous: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Récupérer les statistiques des rendez-vous
  Future<Map<String, dynamic>> getAppointmentStats(String doctorId) async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final monthStart = DateFormat('yyyy-MM-dd').format(
        DateTime(now.year, now.month, 1),
      );

      // Rendez-vous du jour
      final todaySnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: today)
          .get();

      // Rendez-vous du mois
      final monthSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: monthStart)
          .where('date', isLessThanOrEqualTo: today)
          .get();

      // Compter par statut
      final todayAppointments = todaySnapshot.docs;
      final monthAppointments = monthSnapshot.docs;

      int todayPending = 0;
      int todayConfirmed = 0;
      int todayCompleted = 0;

      for (var app in todayAppointments) {
        final status = app['status'] as String;
        switch (status) {
          case 'pending':
            todayPending++;
            break;
          case 'confirmed':
            todayConfirmed++;
            break;
          case 'completed':
            todayCompleted++;
            break;
        }
      }

      int monthPending = 0;
      int monthConfirmed = 0;
      int monthCompleted = 0;
      int monthCancelled = 0;
      double monthRevenue = 0.0;

      for (var app in monthAppointments) {
        final status = app['status'] as String;
        final amount = (app['amount'] ?? 0.0).toDouble();

        switch (status) {
          case 'pending':
            monthPending++;
            break;
          case 'confirmed':
            monthConfirmed++;
            monthRevenue += amount;
            break;
          case 'completed':
            monthCompleted++;
            monthRevenue += amount;
            break;
          case 'cancelled':
            monthCancelled++;
            break;
        }
      }

      return {
        'success': true,
        'stats': {
          'today': {
            'total': todayAppointments.length,
            'pending': todayPending,
            'confirmed': todayConfirmed,
            'completed': todayCompleted,
          },
          'month': {
            'total': monthAppointments.length,
            'pending': monthPending,
            'confirmed': monthConfirmed,
            'completed': monthCompleted,
            'cancelled': monthCancelled,
            'revenue': monthRevenue,
          },
        },
      };
    } catch (e) {
      print('Erreur récupération statistiques: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Méthodes de notification
  Future<void> _sendConfirmationNotification(String appointmentId) async {
    try {
      final appointmentDoc =
          await _db.collection('appointments').doc(appointmentId).get();
      if (!appointmentDoc.exists) return;

      final data = appointmentDoc.data()!;
      final patientId = data['patientId'];
      final date = data['date'];
      final time = data['time'];

      await _db.collection('notifications').add({
        'userId': patientId,
        'title': 'Rendez-vous confirmé',
        'message':
            'Votre rendez-vous du $date à $time a été confirmé par le médecin',
        'type': 'appointment_confirmed',
        'data': {'appointmentId': appointmentId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur notification confirmation: $e');
    }
  }

  Future<void> _sendRejectionNotification(
      String appointmentId, String reason) async {
    try {
      final appointmentDoc =
          await _db.collection('appointments').doc(appointmentId).get();
      if (!appointmentDoc.exists) return;

      final data = appointmentDoc.data()!;
      final patientId = data['patientId'];
      final date = data['date'];
      final time = data['time'];

      await _db.collection('notifications').add({
        'userId': patientId,
        'title': 'Rendez-vous rejeté',
        'message':
            'Votre rendez-vous du $date à $time a été rejeté. Raison: $reason',
        'type': 'appointment_rejected',
        'data': {'appointmentId': appointmentId, 'reason': reason},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur notification rejet: $e');
    }
  }

  Future<void> _sendCompletionNotification(String appointmentId) async {
    try {
      final appointmentDoc =
          await _db.collection('appointments').doc(appointmentId).get();
      if (!appointmentDoc.exists) return;

      final data = appointmentDoc.data()!;
      final patientId = data['patientId'];

      await _db.collection('notifications').add({
        'userId': patientId,
        'title': 'Rendez-vous terminé',
        'message':
            'Votre consultation est terminée. Vous pouvez consulter les notes du médecin.',
        'type': 'appointment_completed',
        'data': {'appointmentId': appointmentId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur notification complétion: $e');
    }
  }
}
