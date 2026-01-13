import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/specialty_model.dart';
import 'package:doctorpoint/presentation/pages/patient/all_doctors_page.dart';

class AllSpecialtiesPage extends StatefulWidget {
  const AllSpecialtiesPage({super.key});

  @override
  State<AllSpecialtiesPage> createState() => _AllSpecialtiesPageState();
}

class _AllSpecialtiesPageState extends State<AllSpecialtiesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialtyProvider = Provider.of<SpecialtyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Specialties',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              specialtyProvider.refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              _buildSearchBar(),
              const SizedBox(height: 20),
              
              // Nombre de spécialités
              _buildSpecialtiesCount(specialtyProvider),
              const SizedBox(height: 16),
              
              // Liste des spécialités
              Expanded(
                child: _buildSpecialtiesList(specialtyProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.greyColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: 'Search specialty by name...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.greyColor),
              ),
              style: const TextStyle(color: AppTheme.textColor),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesCount(SpecialtyProvider provider) {
    final searchQuery = _searchController.text.toLowerCase();
    final filteredCount = searchQuery.isEmpty 
        ? provider.specialties.length 
        : provider.searchSpecialties(searchQuery).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.greyColor,
          ),
          children: [
            TextSpan(
              text: '$filteredCount ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const TextSpan(text: 'specialties available'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtiesList(SpecialtyProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading specialties...',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final searchQuery = _searchController.text.toLowerCase();
    final specialties = searchQuery.isEmpty 
        ? provider.specialties 
        : provider.searchSpecialties(searchQuery);

    if (specialties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_services_outlined,
              size: 80,
              color: AppTheme.greyColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'No specialties found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search',
              style: TextStyle(color: AppTheme.greyColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() {});
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
         provider.refresh();
      },
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: specialties.length,
        itemBuilder: (context, index) {
          final specialty = specialties[index];
          return _buildSpecialtyCard(specialty, provider);
        },
      ),
    );
  }

  Widget _buildSpecialtyCard(Specialty specialty, SpecialtyProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          provider.selectSpecialty(specialty);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllDoctorsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône et nom
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: specialty.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildSpecialtyIcon(specialty),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialty.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${specialty.doctorCount} doctors',
                          style: TextStyle(
                            fontSize: 12,
                            color: specialty.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Expanded(
                child: Text(
                  specialty.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Bouton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: specialty.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'View Doctors',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: specialty.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyIcon(Specialty specialty) {
    // Pour l'instant, on utilise des icônes Material
    // Vous pouvez remplacer par des SVG ou des images personnalisées
    IconData iconData;
    switch (specialty.name) {
      case 'Cardiologie':
        iconData = Icons.favorite;
        break;
      case 'Dermatologie':
        iconData = Icons.face;
        break;
      case 'Neurologie':
        iconData = Icons.psychology;
        break;
      case 'Pédiatrie':
        iconData = Icons.child_care;
        break;
      case 'Dentisterie':
        iconData = Icons.medical_services;
        break;
      case 'Gynécologie':
        iconData = Icons.female;
        break;
      case 'Ophtalmologie':
        iconData = Icons.remove_red_eye;
        break;
      case 'Orthopédie':
        iconData = Icons.accessible;
        break;
      case 'Psychiatrie':
        iconData = Icons.psychology_outlined;
        break;
      case 'Gastro-entérologie':
        iconData = Icons.restaurant_menu;
        break;
      case 'Endocrinologie':
        iconData = Icons.bloodtype;
        break;
      case 'Urologie':
        iconData = Icons.water_drop;
        break;
      case 'ORL':
        iconData = Icons.hearing;
        break;
      case 'Radiologie':
        iconData = Icons.scanner;
        break;
      case 'Anesthésiologie':
        iconData = Icons.medication;
        break;
      default:
        iconData = Icons.medical_services;
    }

    return Icon(
      iconData,
      color: specialty.color,
      size: 24,
    );
  }
}