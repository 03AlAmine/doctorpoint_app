import 'package:doctorpoint/core/providers/auth_provider.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/profile/patient_profile_page.dart';
import 'package:doctorpoint/presentation/pages/patient/search_page.dart';
import 'package:doctorpoint/presentation/widgets/doctor_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/presentation/pages/patient/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/patient/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/patient/all_specialties_page.dart';
import 'package:doctorpoint/presentation/pages/patient/appointments_page.dart'; // AJOUTÉ

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName}); // MODIFIÉ

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // AJOUTÉ
  final List<Map<String, dynamic>> _promotions = [
    {
      'title': 'Consultation gratuite\npour la première visite',
      'subtitle': 'Pour les nouveaux patients',
      'color': const Color(0xFF6A11CB),
      'gradient': const [Color(0xFF6A11CB), Color(0xFF2575FC)],
    },
    {
      'title': 'Réduction de 20%\nsur les consultations',
      'subtitle': 'Valable jusqu\'au 31 décembre',
      'color': const Color(0xFF11998E),
      'gradient': const [Color(0xFF11998E), Color(0xFF38EF7D)],
    },
  ];

  int _currentPromotion = 0;

  // Liste des pages pour la navigation AJOUTÉ
// Dans la liste des pages du bottom navigation
  final List<Widget> _pages = [
    Container(), // Placeholder pour Home
    const AppointmentsPage(),
    Container(
      color: Colors.white,
      child: const Center(child: Text('Messages - Page à créer')),
    ),
    const PatientProfilePage(), // ← Ici le profil patient
  ];

  // Fonction pour changer d'onglet AJOUTÉ
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si l'index sélectionné n'est pas 0 (Accueil), on affiche la page correspondante
    if (_selectedIndex != 0) {
      return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    // Si c'est l'index 0 (Accueil), on affiche le contenu original
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final specialtyProvider = Provider.of<SpecialtyProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await doctorProvider.loadDoctors();
            await doctorProvider.loadPopularDoctors();
            specialtyProvider.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec recherche et notifications
                    _buildHeader(context, screenWidth),
                    SizedBox(height: screenHeight * 0.02),

                    // Carousel des promotions
                    _buildPromotionCarousel(screenWidth),
                    SizedBox(height: screenHeight * 0.03),

                    // Catégories de spécialités
                    _buildSpecialtyCategories(specialtyProvider, screenWidth),
                    SizedBox(height: screenHeight * 0.03),

                    // Médecins populaires
                    _buildPopularDoctors(doctorProvider, screenWidth),
                    SizedBox(height: screenHeight * 0.03),

                    // Recommandés pour vous
                    _buildAllDoctors(doctorProvider, screenWidth),
                    SizedBox(height: screenHeight * 0.03),

                    // Section de bien-être
                    _buildWellnessSection(screenWidth),
                    SizedBox(height: screenHeight * 0.02), // Espace final
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(), // AJOUTÉ
    );
  }

  // Fonction pour construire la navigation en bas AJOUTÉ
  Widget _buildBottomNavigationBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.greyColor,
      selectedLabelStyle: TextStyle(
        fontSize: isSmallScreen ? 10 : 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: isSmallScreen ? 10 : 12,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      iconSize: isSmallScreen ? 20 : 24,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_outlined,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.home,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.calendar_today_outlined,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.calendar_today,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Rendez-vous',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: const Text('3'),
            backgroundColor: Colors.red,
            child: Icon(
              Icons.chat_bubble_outline,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          activeIcon: Badge(
            label: const Text('3'),
            backgroundColor: Colors.red,
            child: Icon(
              Icons.chat_bubble,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
            size: isSmallScreen ? 20 : 24,
          ),
          activeIcon: Icon(
            Icons.person,
            size: isSmallScreen ? 20 : 24,
          ),
          label: 'Profil',
        ),
      ],
      onTap: _onItemTapped,
    );
  }

  // TON CODE EXISTANT POUR LES AUTRES FONCTIONS...
  // NE CHANGE PAS LES FONCTIONS SUIVANTES :

  Widget _buildHeader(BuildContext context, double screenWidth) {
    final isSmallScreen = screenWidth < 360;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        final userName = userProfile?.fullName.isNotEmpty == true
            ? userProfile!.fullName.split(' ').first
            : widget.userName; // MODIFIÉ

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Photo de profil utilisateur
                Container(
                  width: isSmallScreen ? 42 : 48,
                  height: isSmallScreen ? 42 : 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, $userName',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Comment allez-vous aujourd\'hui ?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: AppTheme.greyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -5, end: -5),
                  badgeContent: Text(
                    '3',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 5,
                      vertical: isSmallScreen ? 1 : 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      size: isSmallScreen ? 22 : 24,
                    ),
                    color: AppTheme.textColor,
                    onPressed: () {
                      // Naviguer vers les notifications
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isSmallScreen ? 36 : 40,
                      minHeight: isSmallScreen ? 36 : 40,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            // Barre de recherche
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  border: Border.all(color: AppTheme.lightGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppTheme.greyColor,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Rechercher un médecin, une spécialité...',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: AppTheme.greyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      color: AppTheme.greyColor,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromotionCarousel(double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    final carouselHeight = isSmallScreen ? 140.0 : 160.0;

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                _currentPromotion = index;
              });
            },
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promotion = _promotions[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  gradient: LinearGradient(
                    colors: promotion['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              promotion['title'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              promotion['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: promotion['color'] as Color,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 20,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Découvrir',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promotions.length,
            (index) => Container(
              width: isSmallScreen ? 6 : 8,
              height: isSmallScreen ? 6 : 8,
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPromotion == index
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCategories(
      SpecialtyProvider specialtyProvider, double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    final categoryHeight = isSmallScreen ? 110.0 : 120.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spécialités',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllSpecialtiesPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tout voir',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        SizedBox(
          height: categoryHeight,
          child: specialtyProvider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: specialtyProvider.specialties.take(8).length,
                  itemBuilder: (context, index) {
                    final specialty = specialtyProvider.specialties[index];
                    final itemWidth = isSmallScreen ? 80.0 : 90.0;
                    final iconContainerSize = isSmallScreen ? 60.0 : 70.0;

                    return GestureDetector(
                      onTap: () {
                        specialtyProvider.selectSpecialty(specialty);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllDoctorsPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: itemWidth,
                        margin: EdgeInsets.only(
                          right: index ==
                                  specialtyProvider.specialties.take(8).length -
                                      1
                              ? 0
                              : isSmallScreen
                                  ? 8
                                  : 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: iconContainerSize,
                              height: iconContainerSize,
                              decoration: BoxDecoration(
                                color: specialty.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16),
                              ),
                              child: Center(
                                child:
                                    _getSpecialtyIcon(specialty.name, iconSize),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Flexible(
                              child: Text(
                                specialty.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              '${specialty.doctorCount}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 10,
                                color: specialty.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _getSpecialtyIcon(String name, double size) {
    IconData iconData;
    Color color;

    switch (name) {
      case 'Cardiologie':
        iconData = Icons.favorite;
        color = Colors.red;
        break;
      case 'Dermatologie':
        iconData = Icons.face;
        color = Colors.blue;
        break;
      case 'Neurologie':
        iconData = Icons.psychology;
        color = Colors.purple;
        break;
      case 'Pédiatrie':
        iconData = Icons.child_care;
        color = Colors.green;
        break;
      case 'Dentisterie':
        iconData = Icons.medical_services;
        color = Colors.orange;
        break;
      case 'Gynécologie':
        iconData = Icons.female;
        color = Colors.pink;
        break;
      case 'Ophtalmologie':
        iconData = Icons.remove_red_eye;
        color = Colors.indigo;
        break;
      case 'Orthopédie':
        iconData = Icons.accessible;
        color = Colors.brown;
        break;
      default:
        iconData = Icons.medical_services;
        color = AppTheme.primaryColor;
    }

    return Icon(iconData, color: color, size: size);
  }

  Widget _buildPopularDoctors(
      DoctorProvider doctorProvider, double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    final cardWidth = isSmallScreen ? 180.0 : 220.0;
    final cardHeight = isSmallScreen ? 200.0 : 240.0; // Augmenté légèrement

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Médecins populaires',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllDoctorsPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tout voir',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        if (doctorProvider.isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          )
        else if (doctorProvider.error != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Erreur: ${doctorProvider.error}',
              style: TextStyle(
                color: Colors.red,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else if (doctorProvider.popularDoctors.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aucun médecin populaire pour le moment',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            // AJOUT: Utiliser Container au lieu de SizedBox
            height: cardHeight,
            padding: EdgeInsets.only(
                bottom: 4), // AJOUT: Espace supplémentaire en bas
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: doctorProvider.popularDoctors.length,
              itemBuilder: (context, index) {
                final doctor = doctorProvider.popularDoctors[index];
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(
                    right: index == doctorProvider.popularDoctors.length - 1
                        ? 0
                        : isSmallScreen
                            ? 12
                            : 16,
                  ),
                  child: DoctorCard(
                    doctor: doctor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DoctorDetailPage(doctor: doctor),
                        ),
                      );
                    },
                    onFavoriteTap: () {
                      doctorProvider.toggleFavorite(doctor.id);
                    },
                    isCompact: isSmallScreen,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAllDoctors(DoctorProvider doctorProvider, double screenWidth) {
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommandés pour vous',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllDoctorsPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tout voir',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        if (doctorProvider.isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          )
        else if (doctorProvider.error != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Erreur: ${doctorProvider.error}',
              style: TextStyle(
                color: Colors.red,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else if (doctorProvider.doctors.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aucun médecin disponible',
              style: TextStyle(
                color: AppTheme.greyColor,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Column(
            children: doctorProvider.doctors.take(3).map((doctor) {
              return Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                child:
                    _buildDoctorListItem(doctor, doctorProvider, screenWidth),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDoctorListItem(
      Doctor doctor, DoctorProvider provider, double screenWidth) {
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailPage(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du médecin
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                  bottomLeft: Radius.circular(isSmallScreen ? 12 : 16),
                ),
                child: Container(
                  width: isSmallScreen ? 80 : (isMediumScreen ? 90 : 100),
                  height: isSmallScreen ? 120 : (isMediumScreen ? 130 : 140),
                  color: AppTheme.lightGrey,
                  child: doctor.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doctor.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.lightGrey,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.lightGrey,
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 30 : 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  doctor.specialization,
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              doctor.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: doctor.isFavorite
                                  ? Colors.red
                                  : AppTheme.greyColor,
                              size: isSmallScreen ? 16 : 20,
                            ),
                            onPressed: () {
                              provider.toggleFavorite(doctor.id);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: isSmallScreen ? 14 : 16,
                            color: AppTheme.greyColor,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Expanded(
                            child: Text(
                              doctor.hospital,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: AppTheme.greyColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.amber,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Flexible(
                            child: Text(
                              '(${doctor.reviews} avis)',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppTheme.greyColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${doctor.consultationFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            size: isSmallScreen ? 14 : 16,
                            color: AppTheme.greyColor,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Text(
                            '${doctor.experience} ans exp.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 6 : 8),
                            ),
                            child: Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWellnessSection(double screenWidth) {
    final isSmallScreen = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bien-être & Santé',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.health_and_safety,
                size: isSmallScreen ? 32 : 40,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseils de santé',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      'Découvrez nos articles sur la prévention et le bien-être',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () {},
                color: AppTheme.primaryColor,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? 36 : 40,
                  minHeight: isSmallScreen ? 36 : 40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
