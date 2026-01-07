import 'package:flutter/material.dart';
import 'package:doctorpoint/data/models/specialty_model.dart';

class SpecialtyProvider with ChangeNotifier {
  List<Specialty> _specialties = [];
  bool _isLoading = false;
  String? _error;
  Specialty? _selectedSpecialty;

  List<Specialty> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Specialty? get selectedSpecialty => _selectedSpecialty;

  SpecialtyProvider() {
    _loadSpecialties();
  }

  void _loadSpecialties() {
    _isLoading = true;
    notifyListeners();

    // Données mockées - à remplacer par Firebase plus tard
    _specialties = _getMockSpecialties();

    _isLoading = false;
    notifyListeners();
  }

  List<Specialty> _getMockSpecialties() {
    return [
      Specialty(
        id: '1',
        name: 'Cardiologie',
        icon: 'assets/icons/heart.svg',
        description: 'Spécialité médicale traitant les maladies du cœur et des vaisseaux sanguins.',
        doctorCount: 12,
        color: const Color(0xFFEF5350),
      ),
      Specialty(
        id: '2',
        name: 'Dermatologie',
        icon: 'assets/icons/skin.svg',
        description: 'Spécialité médicale concernant la peau, les cheveux, les ongles et les muqueuses.',
        doctorCount: 8,
        color: const Color(0xFF42A5F5),
      ),
      Specialty(
        id: '3',
        name: 'Neurologie',
        icon: 'assets/icons/brain.svg',
        description: 'Spécialité médicale traitant les maladies du système nerveux.',
        doctorCount: 6,
        color: const Color(0xFFAB47BC),
      ),
      Specialty(
        id: '4',
        name: 'Pédiatrie',
        icon: 'assets/icons/child.svg',
        description: 'Spécialité médicale consacrée aux enfants et à leur développement.',
        doctorCount: 15,
        color: const Color(0xFF66BB6A),
      ),
      Specialty(
        id: '5',
        name: 'Dentisterie',
        icon: 'assets/icons/tooth.svg',
        description: 'Spécialité médicale traitant les dents, les gencives et la cavité buccale.',
        doctorCount: 10,
        color: const Color(0xFFFFA726),
      ),
      Specialty(
        id: '6',
        name: 'Gynécologie',
        icon: 'assets/icons/female.svg',
        description: 'Spécialité médicale traitant la santé reproductive des femmes.',
        doctorCount: 9,
        color: const Color(0xFFEC407A),
      ),
      Specialty(
        id: '7',
        name: 'Ophtalmologie',
        icon: 'assets/icons/eye.svg',
        description: 'Spécialité médicale traitant les maladies des yeux et de la vision.',
        doctorCount: 7,
        color: const Color(0xFF5C6BC0),
      ),
      Specialty(
        id: '8',
        name: 'Orthopédie',
        icon: 'assets/icons/bone.svg',
        description: 'Spécialité chirurgicale traitant les affections de l\'appareil locomoteur.',
        doctorCount: 5,
        color: const Color(0xFF8D6E63),
      ),
      Specialty(
        id: '9',
        name: 'Psychiatrie',
        icon: 'assets/icons/psychology.svg',
        description: 'Spécialité médicale traitant les troubles mentaux et comportementaux.',
        doctorCount: 8,
        color: const Color(0xFF26A69A),
      ),
      Specialty(
        id: '10',
        name: 'Gastro-entérologie',
        icon: 'assets/icons/stomach.svg',
        description: 'Spécialité médicale traitant les maladies du système digestif.',
        doctorCount: 6,
        color: const Color(0xFFFF7043),
      ),
      Specialty(
        id: '11',
        name: 'Endocrinologie',
        icon: 'assets/icons/hormone.svg',
        description: 'Spécialité médicale traitant les troubles hormonaux et métaboliques.',
        doctorCount: 4,
        color: const Color(0xFF7E57C2),
      ),
      Specialty(
        id: '12',
        name: 'Urologie',
        icon: 'assets/icons/kidney.svg',
        description: 'Spécialité chirurgicale traitant les maladies de l\'appareil urinaire.',
        doctorCount: 5,
        color: const Color(0xFF29B6F6),
      ),
      Specialty(
        id: '13',
        name: 'ORL',
        icon: 'assets/icons/ear.svg',
        description: 'Spécialité médicale traitant les oreilles, le nez et la gorge.',
        doctorCount: 7,
        color: const Color(0xFF9CCC65),
      ),
      Specialty(
        id: '14',
        name: 'Radiologie',
        icon: 'assets/icons/xray.svg',
        description: 'Spécialité médicale utilisant l\'imagerie pour le diagnostic.',
        doctorCount: 4,
        color: const Color(0xFFFFCA28),
      ),
      Specialty(
        id: '15',
        name: 'Anesthésiologie',
        icon: 'assets/icons/anesthesia.svg',
        description: 'Spécialité médicale traitant de l\'anesthésie et de la réanimation.',
        doctorCount: 3,
        color: const Color(0xFF78909C),
      ),
    ];
  }

  void selectSpecialty(Specialty? specialty) {
    _selectedSpecialty = specialty;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSpecialty = null;
    notifyListeners();
  }

  List<Specialty> searchSpecialties(String query) {
    if (query.isEmpty) return _specialties;
    
    return _specialties.where((specialty) {
      return specialty.name.toLowerCase().contains(query.toLowerCase()) ||
             specialty.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void updateDoctorCount(String specialtyId, int newCount) {
    final index = _specialties.indexWhere((s) => s.id == specialtyId);
    if (index != -1) {
      _specialties[index] = Specialty(
        id: _specialties[index].id,
        name: _specialties[index].name,
        icon: _specialties[index].icon,
        description: _specialties[index].description,
        doctorCount: newCount,
        color: _specialties[index].color,
      );
      notifyListeners();
    }
  }

  void refresh() {
    _isLoading = true;
    notifyListeners();
    
    // Simuler un chargement
    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
    });
  }
}