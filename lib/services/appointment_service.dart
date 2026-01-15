// lib/services/appointment_service.dart - VERSION COMPLÈTE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_availability.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
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
      // 1. Récupérer l'agenda du médecin
      final availability = await _getDoctorAvailability(doctorId);
      if (availability == null) return false;

      // 2. Vérifier si le jour est disponible
      final dayOfWeek = _getDayName(date.weekday);
      final daySchedule = availability.weeklySchedule.firstWhere(
        (schedule) => schedule.day.toLowerCase() == dayOfWeek.toLowerCase(),
        orElse: () => DaySchedule(day: dayOfWeek, isAvailable: false),
      );

      if (!daySchedule.isAvailable) return false;

      // 3. Vérifier si c'est un jour férié
      if (_isHoliday(date, availability.holidays)) return false;

      // 4. Vérifier si l'heure est dans les plages horaires
      final timeInMinutes = _timeToMinutes(time);
      bool isInTimeSlot = false;

      for (final slot in daySchedule.timeSlots) {
        if (slot.isAvailable) {
          final slotStart = _timeToMinutes(slot.start);
          final slotEnd = _timeToMinutes(slot.end);

          if (timeInMinutes >= slotStart && timeInMinutes < slotEnd) {
            // Vérifier que ce n'est pas pendant une pause
            if (!_isDuringBreak(timeInMinutes, daySchedule.breakTimes)) {
              isInTimeSlot = true;
              break;
            }
          }
        }
      }

      if (!isInTimeSlot) return false;

      // 5. Vérifier si le créneau n'est pas déjà pris
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final existingAppointments = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: time)
          .where('status',
              whereIn: ['pending', 'confirmed', 'scheduled']).get();

      return existingAppointments.docs.isEmpty;
    } catch (e) {
      print('Erreur vérification disponibilité: $e');
      return false;
    }
  }

  // Prendre rendez-vous
  Future<String> bookAppointment({
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
      final appointmentDoc = await _db.collection('appointments').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'doctorName': doctorData['name'],
        'doctorSpecialization': doctorData['specialization'],
        'doctorImage': doctorData['imageUrl'] ?? '',
        'date': DateFormat('yyyy-MM-dd').format(date),
        'time': time,
        'dateTime': Timestamp.fromDate(date),
        'status': 'pending',
        'type': type,
        'amount': amount,
        'notes': notes,
        'symptoms': symptoms,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return appointmentDoc.id;
    } catch (e) {
      print('Erreur prise de rendez-vous: $e');
      rethrow;
    }
  }

  // Récupérer les créneaux disponibles pour un jour
  Future<List<String>> getAvailableTimeSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      // 1. Récupérer l'agenda du médecin
      final availability = await _getDoctorAvailability(doctorId);
      if (availability == null) return [];

      // 2. Vérifier si le jour est disponible
      final dayOfWeek = _getDayName(date.weekday);
      final daySchedule = availability.weeklySchedule.firstWhere(
        (schedule) => schedule.day.toLowerCase() == dayOfWeek.toLowerCase(),
        orElse: () => DaySchedule(day: dayOfWeek, isAvailable: false),
      );

      if (!daySchedule.isAvailable) return [];
      if (_isHoliday(date, availability.holidays)) return [];

      // 3. Générer tous les créneaux possibles
      final duration =
          availability.appointmentDuration + availability.bufferTime;
      final allSlots = daySchedule.generateTimeSlots(duration);

      if (allSlots.isEmpty) return [];

      // 4. Récupérer les rendez-vous déjà pris
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final bookedSlotsSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: dateStr)
          .where('status',
              whereIn: ['pending', 'confirmed', 'scheduled']).get();

      final bookedSlots =
          bookedSlotsSnapshot.docs.map((doc) => doc['time'] as String).toSet();

      // 5. Filtrer les créneaux disponibles
      return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      print('Erreur récupération créneaux: $e');
      return [];
    }
  }

  // Récupérer les jours disponibles
  Future<List<DateTime>> getAvailableDays({
    required String doctorId,
    DateTime? startDate,
    int daysAhead = 30,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final availability = await _getDoctorAvailability(doctorId);
      if (availability == null) return [];

      final availableDays = <DateTime>[];

      for (int i = 0; i < daysAhead; i++) {
        final date = start.add(Duration(days: i));
        final slots = await getAvailableTimeSlots(
          doctorId: doctorId,
          date: date,
        );

        if (slots.isNotEmpty) {
          availableDays.add(date);
        }
      }

      return availableDays;
    } catch (e) {
      print('Erreur récupération jours disponibles: $e');
      return [];
    }
  }

  // Récupérer l'agenda du médecin
  Future<DoctorAvailability?> _getDoctorAvailability(String doctorId) async {
    try {
      final doc =
          await _db.collection('doctor_availability').doc(doctorId).get();

      if (!doc.exists) {
        // Créer un agenda par défaut si non existant
        await _createDefaultAvailability(doctorId);
        return _getDoctorAvailability(doctorId);
      }

      return DoctorAvailability.fromMap({
        ...doc.data()!,
        'doctorId': doctorId,
      });
    } catch (e) {
      print('Erreur récupération agenda: $e');
      return null;
    }
  }

  // Créer un agenda par défaut
  Future<void> _createDefaultAvailability(String doctorId) async {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    final defaultSchedule = days.map((day) {
      final isWeekend = day == 'Samedi' || day == 'Dimanche';
      return DaySchedule(
        day: day,
        isAvailable: !isWeekend,
        timeSlots: !isWeekend
            ? [
                TimeSlot(start: '09:00', end: '12:00'),
                TimeSlot(start: '14:00', end: '18:00'),
              ]
            : [],
        breakTimes: !isWeekend
            ? [TimeSlot(start: '12:00', end: '14:00', isBreak: true)]
            : [],
      );
    }).toList();

    final availability = DoctorAvailability(
      doctorId: doctorId,
      weeklySchedule: defaultSchedule,
      appointmentDuration: 30,
      bufferTime: 5,
      holidays: [],
    );

    await _db
        .collection('doctor_availability')
        .doc(doctorId)
        .set(availability.toMap());
  }

  // Méthodes utilitaires
  bool _isDuringBreak(int timeInMinutes, List<TimeSlot> breakTimes) {
    for (final breakSlot in breakTimes) {
      final breakStart = _timeToMinutes(breakSlot.start);
      final breakEnd = _timeToMinutes(breakSlot.end);

      if (timeInMinutes >= breakStart && timeInMinutes < breakEnd) {
        return true;
      }
    }
    return false;
  }

  bool _isHoliday(DateTime date, List<DateTime> holidays) {
    return holidays.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day);
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return '';
    }
  }

  // ================ MÉTHODES POUR MÉDECIN ================

  // Récupérer les rendez-vous d'un médecin

  Stream<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date')
        .orderBy('time')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      // 1. Collecter tous les patientIds
      final patientIds = snapshot.docs
          .map((doc) => doc.data()['patientId'] as String?)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // 2. Récupérer tous les noms depuis USERS uniquement
      final patientNames = <String, String>{};
      if (patientIds.isNotEmpty) {
        try {
          const batchSize = 10; // Firestore limite whereIn à 10
          for (var i = 0; i < patientIds.length; i += batchSize) {
            final batchIds = patientIds.sublist(
              i,
              i + batchSize > patientIds.length
                  ? patientIds.length
                  : i + batchSize,
            );

            // CORRECTION: Utiliser 'users' au lieu de 'patients'
            final usersSnapshot = await _db
                .collection('users')
                .where(FieldPath.documentId, whereIn: batchIds)
                .get();

            for (var userDoc in usersSnapshot.docs) {
              final data = userDoc.data();
              patientNames[userDoc.id] =
                  data['fullName'] as String? ?? 'Patient';
            }
          }
        } catch (e) {
          print('Erreur batch récupération noms: $e');
        }
      }

      // 3. Construire la réponse
      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'];

        String patientName = data['patientName'] as String? ?? 'Patient';

        // CORRECTION: Utiliser le cache de noms depuis 'users'
        if ((patientName == 'Patient' || patientName.isEmpty) &&
            patientId != null &&
            patientNames.containsKey(patientId)) {
          patientName = patientNames[patientId]!;
        }

        appointments.add({
          'id': doc.id,
          'patient': patientName,
          'patientId': patientId,
          'date': data['date'],
          'time': data['time'],
          'type': data['type'] ?? 'Présentiel',
          'status': data['status'] ?? 'Pending',
          'reason': data['symptoms'] ?? 'Consultation',
          'notes': data['notes'],
          'amount': (data['amount'] ?? 0.0).toDouble(),
        });
      }

      return appointments;
    });
  }

  // Récupérer les rendez-vous à venir d'un médecin
  Future<List<Map<String, dynamic>>> getUpcomingDoctorAppointments(
      String doctorId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final snapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date')
          .orderBy('time')
          .get();

      return await _processAppointments(snapshot);
    } catch (e) {
      print('Erreur récupération rendez-vous à venir médecin: $e');
      return [];
    }
  }

  // ================ MÉTHODES POUR PATIENT ================

  // Récupérer les rendez-vous d'un patient
  Stream<List<Map<String, dynamic>>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .orderBy('time', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final appointments = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'];
        Doctor? doctor;

        // Récupérer les infos du médecin
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
          'reason': data['reason'] ?? data['symptoms'] ?? 'Consultation',
          'symptoms': data['symptoms'],
          'notes': data['notes'],
          'amount': (data['amount'] ?? 0.0).toDouble(),
          'paymentStatus': data['paymentStatus'] ?? 'pending',
          'patientName': data['patientName'] as String? ??
              await _getPatientNameFromUsers(data['patientId'] as String?) ??
              'Patient',
          'cancellationReason': data['cancellationReason'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'confirmedAt': (data['confirmedAt'] as Timestamp?)?.toDate(),
          'cancelledAt': (data['cancelledAt'] as Timestamp?)?.toDate(),
        });
      }

      return appointments;
    });
  }

  // Récupérer les rendez-vous à venir d'un patient
  Future<List<Map<String, dynamic>>> getUpcomingPatientAppointments(
      String patientId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('date', isGreaterThanOrEqualTo: today)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('date')
          .orderBy('time')
          .get();

      return await _processAppointments(snapshot);
    } catch (e) {
      print('Erreur récupération rendez-vous à venir patient: $e');
      return [];
    }
  }
  // ================ MÉTHODES GÉNÉRALES ================

  // Annuler un rendez-vous
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  // Marquer un rendez-vous comme terminé
  Future<void> completeAppointment(String appointmentId,
      {String? notes}) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'doctorNotes': notes?.toString() ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur complétion rendez-vous: $e');
      rethrow;
    }
  }

  // Récupérer un rendez-vous par ID
  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _db.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final doctorId = data['doctorId'];
      final patientId = data['patientId'];

      Doctor? doctor;
      Map<String, dynamic>? patientInfo;

      // Récupérer les infos du médecin
      if (doctorId != null) {
        final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
        if (doctorDoc.exists) {
          doctor = Doctor.fromFirestore(doctorDoc);
        }
      }

      // Récupérer les infos du patient
      if (patientId != null) {
        final patientDoc =
            await _db.collection('patients').doc(patientId).get();
        final userDoc = await _db.collection('users').doc(patientId).get();

        final patientData = patientDoc.exists ? patientDoc.data()! : {};
        final userData = userDoc.exists ? userDoc.data()! : {};

        patientInfo = {
          'id': patientId,
          'name': userData['fullName'] ?? 'Patient', // Chercher dans users
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'gender': patientData['gender'] ?? userData['gender'],
          'bloodGroup': patientData['bloodGroup'] ?? userData['bloodGroup'],
        };
      }

      return {
        'id': doc.id,
        'doctor': doctor,
        'patient': patientInfo,
        'date': data['date'],
        'time': data['time'],
        'type': data['type'] ?? 'Présentiel',
        'status': data['status'] ?? 'pending',
        'reason': data['reason'] ?? data['symptoms'] ?? 'Consultation',
        'symptoms': data['symptoms'],
        'notes': data['notes'],
        'amount': (data['amount'] ?? 0.0).toDouble(),
        'paymentStatus': data['paymentStatus'] ?? 'pending',
        'cancellationReason': data['cancellationReason'],
        'doctorNotes': data['doctorNotes'],
        'prescriptionUrl': data['prescriptionUrl'],
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'confirmedAt': (data['confirmedAt'] as Timestamp?)?.toDate(),
        'cancelledAt': (data['cancelledAt'] as Timestamp?)?.toDate(),
        'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
      };
    } catch (e) {
      print('Erreur récupération rendez-vous par ID: $e');
      return null;
    }
  }

  // Mettre à jour un rendez-vous
  Future<void> updateAppointment({
    required String appointmentId,
    String? reason,
    String? symptoms,
    String? notes,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) updates['reason'] = reason;
      if (symptoms != null) updates['symptoms'] = symptoms;
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status;

      await _db.collection('appointments').doc(appointmentId).update(updates);
    } catch (e) {
      print('Erreur mise à jour rendez-vous: $e');
      rethrow;
    }
  }

  // Traiter les rendez-vous (méthode utilitaire)
  Future<List<Map<String, dynamic>>> _processAppointments(
      QuerySnapshot snapshot) async {
    final appointments = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final doctorId = data['doctorId'];
      final patientId = data['patientId'];

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
        'patientId': patientId,
        'patientName': data['patientName'] as String? ??
            await _getPatientNameFromUsers(data['patientId'] as String?) ??
            'Patient',
        'date': data['date'],
        'time': data['time'],
        'type': data['type'] ?? 'Présentiel',
        'status': data['status'] ?? 'pending',
        'reason': data['reason'] ?? data['symptoms'] ?? 'Consultation',
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
  }

  // Obtenir les statistiques d'un médecin
  Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final monthStart =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

      // Rendez-vous du jour
      final todaySnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: todayStr)
          .get();

      // Rendez-vous du mois
      final monthSnapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: monthStart)
          .where('date', isLessThanOrEqualTo: todayStr)
          .get();

      int todayCount = todaySnapshot.docs.length;
      int monthCount = monthSnapshot.docs.length;

      // Compter par statut pour le mois
      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;
      double revenue = 0.0;

      for (var doc in monthSnapshot.docs) {
        final status = doc['status'] as String;
        final amount = (doc['amount'] ?? 0.0).toDouble();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            revenue += amount;
            break;
          case 'completed':
            completed++;
            revenue += amount;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'today': todayCount,
        'monthTotal': monthCount,
        'monthPending': pending,
        'monthConfirmed': confirmed,
        'monthCompleted': completed,
        'monthCancelled': cancelled,
        'monthRevenue': revenue,
      };
    } catch (e) {
      print('Erreur récupération statistiques médecin: $e');
      return {};
    }
  }

  // Vérifier si un médecin a des créneaux disponibles dans les prochains jours
  Future<bool> hasUpcomingAvailability(String doctorId,
      {int daysToCheck = 7}) async {
    try {
      final now = DateTime.now();
      for (int i = 0; i < daysToCheck; i++) {
        final date = now.add(Duration(days: i));
        final slots = await getAvailableTimeSlots(
          doctorId: doctorId,
          date: date,
        );
        if (slots.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur vérification disponibilité prochaine: $e');
      return false;
    }
  }

  Future<String?> _getPatientNameFromUsers(String? patientId) async {
    if (patientId == null || patientId.isEmpty) return null;
    try {
      final userDoc = await _db.collection('users').doc(patientId).get();
      if (userDoc.exists) {
        return userDoc.data()!['fullName'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
