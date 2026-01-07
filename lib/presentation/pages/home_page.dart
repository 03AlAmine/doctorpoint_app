import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/search_page.dart';
import 'package:doctorpoint/presentation/widgets/doctor_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/presentation/pages/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/pages/all_doctors_page.dart';
import 'package:doctorpoint/presentation/pages/all_specialties_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final specialtyProvider = Provider.of<SpecialtyProvider>(context);

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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec recherche et notifications
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Carousel des promotions
                  _buildPromotionCarousel(),
                  const SizedBox(height: 24),

                  // Catégories de spécialités
                  _buildSpecialtyCategories(specialtyProvider),
                  const SizedBox(height: 24),

                  // Médecins populaires
                  _buildPopularDoctors(doctorProvider),
                  const SizedBox(height: 24),

                  // Recommandés pour vous
                  _buildAllDoctors(doctorProvider),
                  const SizedBox(height: 24),

                  // Section de bien-être
                  _buildWellnessSection(),
                  const SizedBox(height: 16), // Espace final
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Photo de profil utilisateur
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.lightGrey,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, John',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                  ),
                  Text(
                    'Comment allez-vous aujourd\'hui ?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.greyColor,
                        ),
                  ),
                ],
              ),
            ),
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -5, end: -5),
              badgeContent: const Text(
                '3',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textColor,
                onPressed: () {
                  // Naviguer vers les notifications
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppTheme.greyColor),
                SizedBox(width: 12),
                Text(
                  'Rechercher un médecin, une spécialité...',
                  style: TextStyle(color: AppTheme.greyColor),
                ),
                Spacer(),
                Icon(Icons.tune, color: AppTheme.greyColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 160,
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: promotion['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promotion['subtitle'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: promotion['color'] as Color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Découvrir'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promotions.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildSpecialtyCategories(SpecialtyProvider specialtyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spécialités',
              style: TextStyle(
                fontSize: 18,
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
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120, // Augmenté pour éviter le débordement
          child: specialtyProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: specialtyProvider.specialties.take(8).length,
                  itemBuilder: (context, index) {
                    final specialty = specialtyProvider.specialties[index];
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
                        width: 90, // Légèrement plus large
                        margin: EdgeInsets.only(
                          right: index ==
                                  specialtyProvider.specialties.take(8).length -
                                      1
                              ? 0
                              : 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: specialty.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _getSpecialtyIcon(specialty.name),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              specialty.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${specialty.doctorCount}',
                              style: TextStyle(
                                fontSize: 10,
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

  Widget _getSpecialtyIcon(String name) {
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

    return Icon(iconData, color: color, size: 28);
  }

  Widget _buildPopularDoctors(DoctorProvider doctorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Médecins populaires',
              style: TextStyle(
                fontSize: 18,
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
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (doctorProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (doctorProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Erreur: ${doctorProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          )
        else if (doctorProvider.popularDoctors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aucun médecin populaire pour le moment',
              style: TextStyle(color: AppTheme.greyColor),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 240, // Augmenté pour éviter le débordement
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: doctorProvider.popularDoctors.length,
              itemBuilder: (context, index) {
                final doctor = doctorProvider.popularDoctors[index];
                return Container(
                  width: 220, // Légèrement plus large
                  margin: EdgeInsets.only(
                    right: index == doctorProvider.popularDoctors.length - 1
                        ? 0
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
                    imageUrl: '',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAllDoctors(DoctorProvider doctorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommandés pour vous',
              style: TextStyle(
                fontSize: 18,
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
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (doctorProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (doctorProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Erreur: ${doctorProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          )
        else if (doctorProvider.doctors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aucun médecin disponible',
              style: TextStyle(color: AppTheme.greyColor),
              textAlign: TextAlign.center,
            ),
          )
        else
          Column(
            children: doctorProvider.doctors.take(3).map((doctor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDoctorListItem(doctor, doctorProvider),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDoctorListItem(Doctor doctor, DoctorProvider provider) {
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 100,
                  height: 140,
                  color: AppTheme.lightGrey,
                  child: doctor.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doctor.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.lightGrey,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.lightGrey,
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialization,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                              size: 20,
                            ),
                            onPressed: () {
                              provider.toggleFavorite(doctor.id);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            size: 16,
                            color: AppTheme.greyColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.hospital,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.greyColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' (${doctor.reviews} avis)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${doctor.consultationFee.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.work,
                            size: 16,
                            color: AppTheme.greyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.experience} ans exp.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 12,
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

  Widget _buildWellnessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bien-être & Santé',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 40,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conseils de santé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Découvrez nos articles sur la prévention et le bien-être',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {},
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.greyColor,
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Rendez-vous',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('3'),
            child: Icon(Icons.chat_bubble_outline),
          ),
          activeIcon: Badge(
            label: Text('3'),
            child: Icon(Icons.chat_bubble),
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
      onTap: (index) {
        // Gérer la navigation
      },
    );
  }
}
