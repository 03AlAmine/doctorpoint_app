// lib/services/patient_appointment_service.dart - CORRECTION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientAppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppointmentService _appointmentService = AppointmentService();

  // Récupérer les créneaux disponibles
  Future<List<String>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      return await _appointmentService.getAvailableTimeSlots(
        doctorId: doctorId,
        date: date,
      );
    } catch (e) {
      print('Erreur récupération créneaux: $e');
      return [];
    }
  }

  // Récupérer les jours disponibles
  Future<List<DateTime>> getAvailableDays({
    required String doctorId,
    DateTime? startDate,
  }) async {
    try {
      return await _appointmentService.getAvailableDays(
        doctorId: doctorId,
        startDate: startDate ?? DateTime.now(),
        daysAhead: 60,
      );
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
        return {
          'success': false,
          'error': 'Utilisateur non connecté',
        };
      }

      final patientId = user.uid;

      // 1. Vérifier la disponibilité
      final isAvailable = await _appointmentService.checkAvailability(
        doctorId: doctorId,
        date: date,
        time: time,
      );

      if (!isAvailable) {
        return {
          'success': false,
          'error': 'Ce créneau n\'est plus disponible',
        };
      }

      // 2. Récupérer les infos du médecin
      final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
      if (!doctorDoc.exists) {
        return {
          'success': false,
          'error': 'Médecin non trouvé',
        };
      }

      final doctor = Doctor.fromFirestore(doctorDoc);
      final consultationFee = amount ?? doctor.consultationFee;

      // 3. Récupérer le nom du patient (avec fallback sécurisé)
      final patientName = await _getPatientName(user.uid);

      // 4. Créer le rendez-vous
      final appointmentId = await _appointmentService.bookAppointment(
        doctorId: doctorId,
        patientId: patientId,
        date: date,
        time: time,
        type: type,
        amount: consultationFee,
        notes: notes,
        symptoms: symptoms ?? reason,
      );

      // 5. Ajouter les informations supplémentaires
      await _db.collection('appointments').doc(appointmentId).update({
        'patientName': patientName,
        'reason': reason,
        'symptoms': symptoms,
        'paymentStatus': 'pending',
      });

      return {
        'success': true,
        'appointmentId': appointmentId,
        'message': 'Rendez-vous pris avec succès',
      };
    } catch (e) {
      print('Erreur prise de rendez-vous: $e');
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Obtenir le nom du patient (avec fallback)
  Future<String> _getPatientName(String patientId) async {
    try {
      final patientDoc = await _db.collection('patients').doc(patientId).get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        
        // Essayer plusieurs champs possibles pour le nom
        if (data['fullName'] != null && (data['fullName'] as String).isNotEmpty) {
          return data['fullName'] as String;
        }
        if (data['name'] != null && (data['name'] as String).isNotEmpty) {
          return data['name'] as String;
        }
        if (data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
          return data['displayName'] as String;
        }
        
        // Si aucun nom n'est trouvé, utiliser l'email ou "Patient"
        final user = _auth.currentUser;
        if (user != null && user.email != null) {
          return user.email!.split('@')[0]; // Première partie de l'email
        }
      }
    } catch (e) {
      print('Erreur récupération nom patient: $e');
    }
    
    // Fallback final
    return 'Patient';
  }

  // Annuler un rendez-vous
  Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'Utilisateur non connecté',
        };
      }

      final appointmentDoc = await _db.collection('appointments').doc(appointmentId).get();
      
      if (!appointmentDoc.exists) {
        return {
          'success': false,
          'error': 'Rendez-vous non trouvé',
        };
      }

      final appointmentData = appointmentDoc.data()!;
      final patientId = appointmentData['patientId'] as String;

      // Vérifier que c'est bien le patient qui annule
      if (patientId != user.uid) {
        return {
          'success': false,
          'error': 'Vous n\'êtes pas autorisé à annuler ce rendez-vous',
        };
      }

      await _appointmentService.cancelAppointment(
        appointmentId, 
        reason ?? 'Annulé par le patient'
      );

      return {
        'success': true,
        'message': 'Rendez-vous annulé avec succès',
      };
    } catch (e) {
      print('Erreur annulation rendez-vous: $e');
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  // Récupérer les rendez-vous du patient (Stream)
  Stream<List<Map<String, dynamic>>> getPatientAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _appointmentService.getPatientAppointments(user.uid);
  }

  // Récupérer les rendez-vous à venir
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final appointments = await _appointmentService.getUpcomingPatientAppointments(user.uid);
      return appointments;
    } catch (e) {
      print('Erreur récupération rendez-vous à venir: $e');
      return [];
    }
  }

  // Récupérer les rendez-vous passés
  Future<List<Map<String, dynamic>>> getPastAppointments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Récupérer tous les rendez-vous
      final allAppointments = await _getAllPatientAppointments();
      
      // Filtrer pour les rendez-vous passés
      final today = DateTime.now();

      return allAppointments.where((appointment) {
        final dateStr = appointment['date'] as String;
        final status = appointment['status'] as String;
        
        // Comparer les dates
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final appointmentDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          
          // Soit la date est passée, soit le statut est terminé/annulé
          return appointmentDate.isBefore(today) || 
                 status == 'completed' || 
                 status == 'cancelled';
        }
        return false;
      }).toList();
    } catch (e) {
      print('Erreur récupération rendez-vous passés: $e');
      return [];
    }
  }

  // Récupérer tous les rendez-vous du patient
  Future<List<Map<String, dynamic>>> _getAllPatientAppointments() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .orderBy('time', descending: true)
          .get();

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

        // Utiliser patientName du rendez-vous s'il existe, sinon fallback
        final patientName = data['patientName'] as String? ?? 'Patient';

        appointments.add({
          'id': doc.id,
          'doctor': doctor,
          'patientName': patientName,
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
        });
      }

      return appointments;
    } catch (e) {
      print('Erreur récupération tous les rendez-vous: $e');
      return [];
    }
  }
}