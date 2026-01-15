// lib/services/patient_service.dart - VERSION COMPLÈTE CORRIGÉE
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== GESTION PROFIL COMPLET ====================

  /// Récupère le profil patient COMPLET en fusionnant users + patients
  Future<Patient?> getPatientProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Récupérer en parallèle pour meilleure performance
      final results = await Future.wait([
        _db.collection('users').doc(user.uid).get(),
        _db.collection('patients').doc(user.uid).get(),
      ]);

      final userDoc = results[0];
      final patientDoc = results[1];

      // Créer le patient fusionné
      return _mergePatientData(user, userDoc, patientDoc);
    } catch (e) {
      print('❌ Erreur récupération profil patient: $e');
      return _createFallbackPatient(user);
    }
  }

  /// Fusionne les données des collections users et patients
  Patient _mergePatientData(
    User user,
    DocumentSnapshot userDoc,
    DocumentSnapshot patientDoc,
  ) {
    final userData =
        userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
    final patientData =
        patientDoc.exists ? patientDoc.data() as Map<String, dynamic> : {};

    // Parsing sécurisé des timestamps
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      return null;
    }

    // Parsing sécurisé des listes
    List<String>? parseStringList(dynamic list) {
      if (list == null) return null;
      if (list is List) return List<String>.from(list);
      return null;
    }

    // Parsing sécurisé des surgeries
    List<Surgery>? parseSurgeries(dynamic surgeries) {
      if (surgeries == null || surgeries is! List) return null;
      return surgeries.map<Surgery>((s) {
        if (s is Map<String, dynamic>) {
          return Surgery.fromMap(s);
        }
        return Surgery(
          name: 'Opération',
          date: DateTime.now(),
        );
      }).toList();
    }

    // Parsing sécurisé des vaccines
    List<Vaccine>? parseVaccines(dynamic vaccines) {
      if (vaccines == null || vaccines is! List) return null;
      return vaccines.map<Vaccine>((v) {
        if (v is Map<String, dynamic>) {
          return Vaccine.fromMap(v);
        }
        return Vaccine(
          name: 'Vaccin',
          date: DateTime.now(),
        );
      }).toList();
    }

    return Patient(
      id: user.uid,
      uid: user.uid,
      email: userData['email'] ?? user.email ?? '',
      fullName: userData['fullName'] ?? user.displayName ?? 'Utilisateur',
      phone: userData['phone'] ?? user.phoneNumber ?? '',
      // Données fusionnées (patients prioritaire, sinon users)
      gender: patientData['gender'] ?? userData['gender'],
      birthDate:
          parseTimestamp(patientData['birthDate'] ?? userData['birthDate']),
      address: patientData['address'] ?? userData['address'],
      city: patientData['city'] ?? userData['city'],
      postalCode: patientData['postalCode'],
      country: patientData['country'] ?? userData['country'] ?? 'Sénégal',
      bloodGroup: patientData['bloodGroup'] ?? userData['bloodGroup'],
      allergies:
          parseStringList(patientData['allergies'] ?? userData['allergies']),
      chronicDiseases: parseStringList(
          patientData['chronicDiseases'] ?? userData['chronicDiseases']),
      currentMedications: parseStringList(
          patientData['currentMedications'] ?? userData['currentMedications']),
      surgeries: parseSurgeries(patientData['surgeries']),
      vaccines: parseVaccines(patientData['vaccines']),
      emergencyContactName: patientData['emergencyContactName'],
      emergencyContactPhone: patientData['emergencyContactPhone'],
      emergencyContactRelation: patientData['emergencyContactRelation'],
      photoUrl: userData['photoUrl'] ?? patientData['photoUrl'],
      height: patientData['height'] != null
          ? (patientData['height'] as num).toDouble()
          : null,
      weight: patientData['weight'] != null
          ? (patientData['weight'] as num).toDouble()
          : null,
      smoker: patientData['smoker'] as bool?,
      alcoholConsumer: patientData['alcoholConsumer'] as bool?,
      occupation: patientData['occupation'],
      maritalStatus: patientData['maritalStatus'],
      numberOfChildren: patientData['numberOfChildren'] as int?,
      familyMedicalHistory: patientData['familyMedicalHistory'],
      profileCompleted: patientData['profileCompleted'] ?? false,
      emailVerified: user.emailVerified,
      createdAt: patientDoc.exists
          ? (parseTimestamp(patientData['createdAt']) ?? DateTime.now())
          : DateTime.now(),
      updatedAt:
          parseTimestamp(patientData['updatedAt'] ?? userData['updatedAt']),
    );
  }

  /// Crée un patient de secours en cas d'erreur
  Patient _createFallbackPatient(User user) {
    return Patient(
      id: user.uid,
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? 'Utilisateur',
      phone: user.phoneNumber ?? '',
      profileCompleted: false,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
  }

  // ==================== SAUVEGARDE ====================

  /// Sauvegarde le profil dans users ET patients
  Future<void> savePatientProfile(Patient patient) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      if (patient.id.isEmpty) throw Exception('ID patient vide');

      // Préparer les données pour users (informations de base)
      final userData = <String, dynamic>{
        'fullName': patient.fullName,
        'email': patient.email,
        'phone': patient.phone,
        'gender': patient.gender,
        'birthDate': patient.birthDate != null
            ? Timestamp.fromDate(patient.birthDate!)
            : null,
        'address': patient.address,
        'city': patient.city,
        'country': patient.country ?? 'Sénégal',
        'bloodGroup': patient.bloodGroup,
        'role': 'patient',
        'profileCompleted': patient.profileCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Nettoyer les valeurs nulles
      userData.removeWhere((key, value) => value == null);

      // Préparer les données pour patients (médicales)
      final patientData = patient.toMap();

      // Supprimer les doublons déjà dans users
      patientData.remove('fullName');
      patientData.remove('email');
      patientData.remove('phone');
      patientData.remove('gender');
      patientData.remove('birthDate');
      patientData.remove('address');
      patientData.remove('city');
      patientData.remove('country');
      patientData.remove('bloodGroup');

      // Ajouter le lien et timestamp
      patientData['userId'] = patient.id;
      patientData['updatedAt'] = FieldValue.serverTimestamp();

      // Batch write pour atomicité
      final batch = _db.batch();

      batch.set(
        _db.collection('users').doc(patient.id),
        userData,
        SetOptions(merge: true),
      );

      batch.set(
        _db.collection('patients').doc(patient.id),
        patientData,
        SetOptions(merge: true),
      );

      await batch.commit();

      print('✅ Profil sauvegardé pour: ${patient.fullName}');
    } catch (e) {
      print('❌ Erreur sauvegarde profil patient: $e');
      rethrow;
    }
  }

  /// Mise à jour partielle du profil
  Future<void> updatePatientProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Séparer les updates pour users et patients
      final userUpdates = <String, dynamic>{};
      final patientUpdates = <String, dynamic>{};

      final userFields = {
        'fullName',
        'email',
        'phone',
        'gender',
        'birthDate',
        'address',
        'city',
        'country',
        'bloodGroup'
      };

      updates.forEach((key, value) {
        if (userFields.contains(key)) {
          if (key == 'birthDate' && value is DateTime) {
            userUpdates[key] = Timestamp.fromDate(value);
          } else {
            userUpdates[key] = value;
          }
        } else {
          patientUpdates[key] = value;
        }
      });

      // Ajouter timestamps
      userUpdates['updatedAt'] = FieldValue.serverTimestamp();
      patientUpdates['updatedAt'] = FieldValue.serverTimestamp();

      // Batch update
      final batch = _db.batch();

      if (userUpdates.isNotEmpty) {
        batch.update(_db.collection('users').doc(user.uid), userUpdates);
      }

      if (patientUpdates.isNotEmpty) {
        batch.update(_db.collection('patients').doc(user.uid), patientUpdates);
      }

      await batch.commit();

      print('✅ Profil mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      rethrow;
    }
  }

  // ==================== SERVICES POUR RENDEZ-VOUS ====================

  /// Récupère le nom d'un patient par son ID (pour appointments)
  static Future<String> getPatientNameById(String patientId) async {
    if (patientId.isEmpty) return 'Patient';

    try {
      // Rechercher UNIQUEMENT dans 'users'
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Directement utiliser fullName depuis users
        final name = data['fullName'] as String?;
        if (name != null && name.isNotEmpty) return name;

        // Fallback sur l'email si pas de nom
        final email = data['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return email.split('@')[0];
        }
      }

      return 'Patient';
    } catch (e) {
      print('⚠️ Erreur récupération nom patient ($patientId): $e');
      return 'Patient';
    }
  }

  /// Récupère les noms de plusieurs patients en batch (optimisation)
  static Future<Map<String, String>> getPatientsNamesBatch(
      List<String> patientIds) async {
    if (patientIds.isEmpty) return {};

    try {
      // Limite Firestore: max 10 IDs dans whereIn
      const batchSize = 10;
      final results = <String, String>{};

      for (var i = 0; i < patientIds.length; i += batchSize) {
        final batchIds = patientIds.sublist(
            i,
            i + batchSize > patientIds.length
                ? patientIds.length
                : i + batchSize);

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          results[doc.id] = data['fullName'] as String? ?? 'Patient';
        }
      }

      // Remplir les manquants
      for (var id in patientIds) {
        if (!results.containsKey(id)) {
          results[id] = 'Patient';
        }
      }

      return results;
    } catch (e) {
      print('⚠️ Erreur batch récupération noms: $e');

      // Fallback: récupérer un par un
      final results = <String, String>{};
      for (var id in patientIds) {
        final name = await getPatientNameById(id);
        results[id] = name;
      }
      return results;
    }
  }

  /// Récupère les infos complètes d'un patient pour un médecin
  static Future<Map<String, dynamic>> getPatientInfoForDoctor(
      String patientId) async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      ]);

      final userDoc = results[0];
      final patientDoc = results[1];

      final userData = userDoc.exists ? userDoc.data()! : {};
      final patientData = patientDoc.exists ? patientDoc.data()! : {};

      return {
        'id': patientId,
        'fullName': userData['fullName'] ?? 'Patient',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'gender': patientData['gender'] ?? userData['gender'],
        'birthDate': patientData['birthDate'] ?? userData['birthDate'],
        'age': _calculateAge(patientData['birthDate'] ?? userData['birthDate']),
        'bloodGroup': patientData['bloodGroup'] ?? userData['bloodGroup'],
        'allergies': patientData['allergies'] ?? [],
        'chronicDiseases': patientData['chronicDiseases'] ?? [],
        'lastUpdated': patientData['updatedAt'] ?? userData['updatedAt'],
      };
    } catch (e) {
      print('❌ Erreur récupération info patient pour médecin: $e');
      return {
        'id': patientId,
        'fullName': 'Patient',
        'email': '',
        'phone': '',
      };
    }
  }

  static int? _calculateAge(dynamic birthTimestamp) {
    if (birthTimestamp == null) return null;
    try {
      final birthDate = (birthTimestamp as Timestamp).toDate();
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // ==================== GESTION DES ALLERGIES ====================

  Future<void> addAllergy(String allergy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('patients').doc(user.uid).update({
        'allergies': FieldValue.arrayUnion([allergy.trim()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Allergie ajoutée: $allergy');
    } catch (e) {
      print('❌ Erreur ajout allergie: $e');
      rethrow;
    }
  }

  Future<void> removeAllergy(String allergy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('patients').doc(user.uid).update({
        'allergies': FieldValue.arrayRemove([allergy.trim()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Allergie supprimée: $allergy');
    } catch (e) {
      print('❌ Erreur suppression allergie: $e');
      rethrow;
    }
  }

  // ==================== PHOTO DE PROFIL ====================

  Future<String?> uploadProfilePhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('patients/${user.uid}/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': user.uid},
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Mettre à jour dans users ET patients
      await _db.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('patients').doc(user.uid).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Photo uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload photo: $e');
      return null;
    }
  }

  Future<void> deleteProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Supprimer toutes les photos du dossier
      final listResult =
          await _storage.ref().child('patients/${user.uid}').listAll();

      final deleteFutures = <Future>[];
      for (var item in listResult.items) {
        deleteFutures.add(item.delete());
      }

      await Future.wait(deleteFutures);

      // Mettre à jour les documents
      await _db.collection('users').doc(user.uid).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('patients').doc(user.uid).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Photos de profil supprimées');
    } catch (e) {
      print('❌ Erreur suppression photos: $e');
      rethrow;
    }
  }

  // ==================== VÉRIFICATIONS ====================

  Future<bool> isProfileComplete() async {
    final patient = await getPatientProfile();
    if (patient == null) return false;

    return patient.profileCompleted &&
        patient.gender != null &&
        patient.birthDate != null &&
        patient.address != null &&
        patient.city != null &&
        patient.bloodGroup != null;
  }

  Future<bool> hasMedicalInfo() async {
    final patient = await getPatientProfile();
    if (patient == null) return false;

    return (patient.allergies?.isNotEmpty ?? false) ||
        (patient.chronicDiseases?.isNotEmpty ?? false) ||
        (patient.currentMedications?.isNotEmpty ?? false) ||
        (patient.surgeries?.isNotEmpty ?? false) ||
        (patient.vaccines?.isNotEmpty ?? false);
  }

  // ==================== STREAMS ====================

  Stream<Patient?> streamPatientProfile() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userSnapshot) async {
      if (!userSnapshot.exists) return null;

      final patientSnapshot =
          await _db.collection('patients').doc(user.uid).get();
      return _mergePatientData(user, userSnapshot, patientSnapshot);
    });
  }

  Stream<List<Map<String, dynamic>>> getMedicalHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('patients')
        .doc(user.uid)
        .collection('medical_history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
                'date': (data['date'] as Timestamp).toDate(),
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              };
            }).toList());
  }

  // ==================== SÉCURITÉ ====================

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    if (user.email == null) throw Exception('Email non disponible');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      print('✅ Mot de passe changé avec succès');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Mot de passe actuel incorrect');
      }
      rethrow;
    } catch (e) {
      print('❌ Erreur changement mot de passe: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      // Supprimer les données Firestore
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(user.uid));
      batch.delete(_db.collection('patients').doc(user.uid));
      await batch.commit();

      // Supprimer le storage
      await _storage
          .ref()
          .child('patients/${user.uid}')
          .delete()
          .catchError((_) {});

      // Supprimer le compte auth
      await user.delete();

      print('✅ Compte supprimé avec succès');
    } catch (e) {
      print('❌ Erreur suppression compte: $e');
      rethrow;
    }
  }

  // ==================== STATISTIQUES ====================

  Future<Map<String, dynamic>> getPatientStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final patient = await getPatientProfile();
      if (patient == null) return {};

      // Récupérer les rendez-vous
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .get();

      final appointments = appointmentsSnapshot.docs;

      return {
        'totalAppointments': appointments.length,
        'upcomingAppointments': appointments.where((a) {
          final data = a.data();
          final status = data['status'] as String? ?? '';
          final dateStr = data['date'] as String? ?? '';
          final today = DateTime.now();

          if (dateStr.isEmpty) return false;

          try {
            final dateParts = dateStr.split('-');
            if (dateParts.length != 3) return false;

            final appointmentDate = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );

            return (status == 'pending' || status == 'confirmed') &&
                appointmentDate.isAfter(today);
          } catch (e) {
            return false;
          }
        }).length,
        'completedAppointments': appointments.where((a) {
          return (a.data()['status'] as String? ?? '') == 'completed';
        }).length,
        'profileCompletion': patient.profileCompleted ? 100 : 50,
        'hasMedicalInfo': await hasMedicalInfo(),
        'lastAppointment': _getLastAppointmentDate(appointments),
      };
    } catch (e) {
      print('❌ Erreur récupération statistiques: $e');
      return {};
    }
  }

// CORRECTION dans la méthode _getLastAppointmentDate
  DateTime? _getLastAppointmentDate(List<QueryDocumentSnapshot> appointments) {
    if (appointments.isEmpty) return null;

    DateTime? latestDate;

    for (var appointment in appointments) {
      final data = appointment.data();

      // Vérifier si data n'est pas null ET si c'est une Map
      if (data != null && data is Map<String, dynamic>) {
        final dateStr = data['date'] as String?;

        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            final dateParts = dateStr.split('-');
            if (dateParts.length == 3) {
              final date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );

              if (latestDate == null || date.isAfter(latestDate)) {
                latestDate = date;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    return latestDate;
  }
}
