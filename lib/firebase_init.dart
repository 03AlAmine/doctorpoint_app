import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseInitializer {
  static Future<void> initializeDatabase() async {
    
  //  print('Initialisation Firebase terminée');
  }

  static Future<void> addSampleDoctors() async {
    final db = FirebaseFirestore.instance;
    
    // Données d'exemple
    final sampleDoctors = [
      {
        'name': 'Dr. Sarah Johnson',
        'specialization': 'Cardiologue',
        'rating': 4.8,
        'reviews': 120,
        'experience': 10,
        'hospital': 'Hôpital Saint-Louis',
        'department': 'Cardiologie',
        'imageUrl': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
        'isFavorite': true,
        'consultationFee': 80.0,
        'languages': ['Français', 'Anglais', 'Espagnol'],
        'description': 'Spécialiste en cardiologie avec plus de 10 ans d\'expérience.',
        'availability': {
          'Lundi': ['09:00', '14:00'],
          'Mardi': ['10:00', '16:00'],
          'Mercredi': ['08:00', '13:00'],
        },
        'phoneNumber': '+33123456789',
        'email': 'sarah.johnson@hospital.com',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var doctor in sampleDoctors) {
      await db.collection('doctors').add(doctor);
    }
    
   // print('Doctors d\'exemple ajoutés');
  }
}