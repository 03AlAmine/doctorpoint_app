// lib/services/patient_appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/appointment_slot.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientAppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer les créneaux disponibles d'un médecin
  Future<List<AppointmentSlot>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final snapshot = await _db
          .collection('appointment_slots')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: dateStr)
          .where('isAvailable', isEqualTo: true)
          .orderBy('time')
          .get();

      return snapshot.docs.map((doc) => AppointmentSlot.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur récupération créneaux: $e');
      return [];
    }
  }

  // Récupérer les prochains jours disponibles (7 jours)
  Future<List<DateTime>> getAvailableDays({
    required String doctorId,
    DateTime? startDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = start.add(const Duration(days: 30));
      
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);

      final snapshot = await _db
          .collection('appointment_slots')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .where('isAvailable', isEqualTo: true)
          .get();

      // Extraire les dates uniques
      final dates = snapshot.docs.map((doc) {
        final data = doc.data();
        final dateStr = data['date'] as String;
        final parts = dateStr.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toSet().toList();

      dates.sort();
      return dates.take(7).toList();
    } catch (e) {
      print('Erreur récupération jours disponibles: $e');
      return [];
    }
  }

  // Prendre rendez-vous
  Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String time,
    required String type,
    required String reason,
    String? symptoms,
    String? notes,
    double? amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final patientId = user.uid;
      final appointmentId = _db.collection('appointments').doc().id;
      final slotId = '${doctorId}_${DateFormat('yyyy-MM-dd').format(date)}_$time';
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // 1. Vérifier si le créneau est toujours disponible
      final slotDoc = await _db.collection('appointment_slots').doc(slotId).get();
      
      if (slotDoc.exists) {
        final slotData = slotDoc.data()!;
        if (!slotData['isAvailable']) {
          throw Exception('Ce créneau n\'est plus disponible');
        }
      }

      // 2. Récupérer les infos du médecin
      final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw Exception('Médecin non trouvé');
      }

      final doctorData = doctorDoc.data()!;
      final consultationFee = amount ?? (doctorData['consultationFee'] as num?)?.toDouble() ?? 0.0;

      // 3. Créer le rendez-vous
      await _db.collection('appointments').doc(appointmentId).set({
        'id': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'doctorName': doctorData['name'],
        'doctorSpecialization': doctorData['specialization'],
        'doctorImage': doctorData['imageUrl'],
        'date': dateStr,
        'time': time,
        'dateTime': Timestamp.fromDate(date),
        'status': 'pending',
        'type': type,
        'reason': reason,
        'symptoms': symptoms,
        'notes': notes,
        'amount': consultationFee,
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Marquer le créneau comme occupé
      await _db.collection('appointment_slots').doc(slotId).set({
        'id': slotId,
        'doctorId': doctorId,
        'date': dateStr,
        'time': time,
        'isAvailable': false,
        'appointmentId': appointmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Ajouter à l'historique du patient
      await _db
          .collection('patients')
          .doc(patientId)
          .collection('appointments')
          .doc(appointmentId)
          .set({
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'doctorName': doctorData['name'],
        'date': dateStr,
        'time': time,
        'type': type,
        'status': 'pending',
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 6. Envoyer notification au médecin
      await _sendDoctorNotification(
        doctorId: doctorId,
        appointmentId: appointmentId,
        patientId: patientId,
        date: date,
        time: time,
      );

      return {
        'success': true,
        'appointmentId': appointmentId,
        'message': 'Rendez-vous pris avec succès',
      };
    } catch (e) {
      print('Erreur prise de rendez-vous: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Annuler un rendez-vous
  Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final appointmentDoc = await _db.collection('appointments').doc(appointmentId).get();
      if (!appointmentDoc.exists) {
        throw Exception('Rendez-vous non trouvé');
      }

      final appointmentData = appointmentDoc.data()!;
      final status = appointmentData['status'] as String;

      if (status == 'cancelled') {
        throw Exception('Ce rendez-vous est déjà annulé');
      }

      if (status == 'completed') {
        throw Exception('Impossible d\'annuler un rendez-vous terminé');
      }

      // 1. Mettre à jour le statut du rendez-vous
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Libérer le créneau
      final date = appointmentData['date'] as String;
      final time = appointmentData['time'] as String;
      final doctorId = appointmentData['doctorId'] as String;
      final slotId = '${doctorId}_${date}_$time';

      await _db.collection('appointment_slots').doc(slotId).update({
        'isAvailable': true,
        'appointmentId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Envoyer notification au médecin
      await _sendCancellationNotification(
        doctorId: doctorId,
        appointmentId: appointmentId,
        patientId: user.uid,
        reason: reason,
      );

      return {
        'success': true,
        'message': 'Rendez-vous annulé avec succès',
      };
    } catch (e) {
      print('Erreur annulation rendez-vous: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Récupérer les rendez-vous du patient
  Stream<List<Map<String, dynamic>>> getPatientAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'];
        Doctor? doctor;

        if (doctorId != null) {
          final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
          if (doctorDoc.exists) {
            doctor = Doctor.fromFirestore(doctorDoc);
          }
        }

        appointments.add({
          'id': doc.id,
          'doctor': doctor,
          'date': data['date'],
          'time': data['time'],
          'type': data['type'] ?? 'Présentiel',
          'status': data['status'] ?? 'pending',
          'reason': data['reason'] ?? 'Consultation',
          'symptoms': data['symptoms'],
          'notes': data['notes'],
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'paymentStatus': data['paymentStatus'] ?? 'pending',
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        });
      }

      return appointments;
    });
  }

  // Confirmer un rendez-vous (après paiement)
  Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

  // Envoyer notification au médecin
  Future<void> _sendDoctorNotification({
    required String doctorId,
    required String appointmentId,
    required String patientId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final patientDoc = await _db.collection('patients').doc(patientId).get();
      final patientName = patientDoc.exists 
          ? patientDoc['fullName'] ?? 'Un patient'
          : 'Un patient';

      await _db.collection('notifications').add({
        'userId': doctorId,
        'title': 'Nouveau rendez-vous',
        'message': '$patientName a pris rendez-vous pour le ${DateFormat('dd/MM/yyyy').format(date)} à $time',
        'type': 'new_appointment',
        'data': {
          'appointmentId': appointmentId,
          'patientId': patientId,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'time': time,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification médecin: $e');
    }
  }

  // Envoyer notification d'annulation
  Future<void> _sendCancellationNotification({
    required String doctorId,
    required String appointmentId,
    required String patientId,
    String? reason,
  }) async {
    try {
      final patientDoc = await _db.collection('patients').doc(patientId).get();
      final patientName = patientDoc.exists 
          ? patientDoc['fullName'] ?? 'Un patient'
          : 'Un patient';

      await _db.collection('notifications').add({
        'userId': doctorId,
        'title': 'Rendez-vous annulé',
        'message': '$patientName a annulé un rendez-vous${reason != null ? ': $reason' : ''}',
        'type': 'appointment_cancelled',
        'data': {
          'appointmentId': appointmentId,
          'patientId': patientId,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification annulation: $e');
    }
  }

  // Récupérer les rendez-vous à venir
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date')
          .orderBy('time')
          .limit(10)
          .get();

      return await _processAppointments(snapshot);
    } catch (e) {
      print('Erreur récupération rendez-vous à venir: $e');
      return [];
    }
  }

  // Récupérer les rendez-vous passés
  Future<List<Map<String, dynamic>>> getPastAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('date', isLessThan: today)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .limit(20)
          .get();

      return await _processAppointments(snapshot);
    } catch (e) {
      print('Erreur récupération rendez-vous passés: $e');
      return [];
    }
  }

  // Traiter les rendez-vous
  Future<List<Map<String, dynamic>>> _processAppointments(QuerySnapshot snapshot) async {
    final appointments = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final doctorId = data['doctorId'];
      
      if (doctorId != null) {
        final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
        if (doctorDoc.exists) {
          final doctor = Doctor.fromFirestore(doctorDoc);
          
          appointments.add({
            'id': doc.id,
            'doctor': doctor,
            'date': data['date'],
            'time': data['time'],
            'type': data['type'] ?? 'Présentiel',
            'status': data['status'] ?? 'pending',
            'reason': data['reason'] ?? 'Consultation',
            'amount': (data['amount'] ?? 0.0).toDouble(),
            'paymentStatus': data['paymentStatus'] ?? 'pending',
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          });
        }
      }
    }

    return appointments;
  }
}