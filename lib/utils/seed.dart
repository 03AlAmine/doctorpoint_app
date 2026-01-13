import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialtySeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedSpecialties() async {
    try {
      print('🌱 Début de la migration des spécialités...');

      final specialties = [
        {
          'name': 'Cardiologie',
          'icon': 'assets/icons/heart.svg',
          'description': 'Spécialité médicale traitant les maladies du cœur et des vaisseaux sanguins.',
          'doctorCount': 0,
          'color': '#EF5350',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Dermatologie',
          'icon': 'assets/icons/skin.svg',
          'description': 'Spécialité médicale concernant la peau, les cheveux, les ongles et les muqueuses.',
          'doctorCount': 0,
          'color': '#42A5F5',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Neurologie',
          'icon': 'assets/icons/brain.svg',
          'description': 'Spécialité médicale traitant les maladies du système nerveux.',
          'doctorCount': 0,
          'color': '#AB47BC',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Pédiatrie',
          'icon': 'assets/icons/child.svg',
          'description': 'Spécialité médicale consacrée aux enfants et à leur développement.',
          'doctorCount': 0,
          'color': '#66BB6A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Dentisterie',
          'icon': 'assets/icons/tooth.svg',
          'description': 'Spécialité médicale traitant les dents, les gencives et la cavité buccale.',
          'doctorCount': 0,
          'color': '#FFA726',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Gynécologie',
          'icon': 'assets/icons/female.svg',
          'description': 'Spécialité médicale traitant la santé reproductive des femmes.',
          'doctorCount': 0,
          'color': '#EC407A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Ophtalmologie',
          'icon': 'assets/icons/eye.svg',
          'description': 'Spécialité médicale traitant les maladies des yeux et de la vision.',
          'doctorCount': 0,
          'color': '#5C6BC0',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Orthopédie',
          'icon': 'assets/icons/bone.svg',
          'description': 'Spécialité chirurgicale traitant les affections de l\'appareil locomoteur.',
          'doctorCount': 0,
          'color': '#8D6E63',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Psychiatrie',
          'icon': 'assets/icons/psychology.svg',
          'description': 'Spécialité médicale traitant les troubles mentaux et comportementaux.',
          'doctorCount': 0,
          'color': '#26A69A',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Gastro-entérologie',
          'icon': 'assets/icons/stomach.svg',
          'description': 'Spécialité médicale traitant les maladies du système digestif.',
          'doctorCount': 0,
          'color': '#FF7043',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Endocrinologie',
          'icon': 'assets/icons/hormone.svg',
          'description': 'Spécialité médicale traitant les troubles hormonaux et métaboliques.',
          'doctorCount': 0,
          'color': '#7E57C2',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Urologie',
          'icon': 'assets/icons/kidney.svg',
          'description': 'Spécialité chirurgicale traitant les maladies de l\'appareil urinaire.',
          'doctorCount': 0,
          'color': '#29B6F6',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'ORL',
          'icon': 'assets/icons/ear.svg',
          'description': 'Spécialité médicale traitant les oreilles, le nez et la gorge.',
          'doctorCount': 0,
          'color': '#9CCC65',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Radiologie',
          'icon': 'assets/icons/xray.svg',
          'description': 'Spécialité médicale utilisant l\'imagerie pour le diagnostic.',
          'doctorCount': 0,
          'color': '#FFCA28',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Anesthésiologie',
          'icon': 'assets/icons/anesthesia.svg',
          'description': 'Spécialité médicale traitant de l\'anesthésie et de la réanimation.',
          'doctorCount': 0,
          'color': '#78909C',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Vérifier si les spécialités existent déjà
      final existingSpecialties = await _db.collection('specialties').get();
      if (existingSpecialties.docs.isNotEmpty) {
        print('✅ Les spécialités existent déjà, pas besoin de migration.');
        return;
      }

      // Ajouter les spécialités
      for (var specialty in specialties) {
        await _db.collection('specialties').add(specialty);
        print('✅ Ajouté: ${specialty['name']}');
      }

      print('✅ Migration des spécialités terminée avec succès!');
    } catch (e) {
      print('❌ Erreur lors de la migration des spécialités: $e');
    }
  }
}