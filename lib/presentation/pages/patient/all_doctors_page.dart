import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/patient/doctor_detail_page.dart';

class AllDoctorsPage extends StatefulWidget {
  const AllDoctorsPage({super.key});

  @override
  State<AllDoctorsPage> createState() => _AllDoctorsPageState();
}

class _AllDoctorsPageState extends State<AllDoctorsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late List<Map<String, dynamic>> _filters;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _filters = [
      {'label': 'All', 'isSelected': true},
      {'label': 'Cardio', 'isSelected': false},
      {'label': 'Dentist', 'isSelected': false},
      {'label': 'Dermatologie', 'isSelected': false},
      {'label': 'Pédiatrie', 'isSelected': false},
      {'label': 'Neurologie', 'isSelected': false},
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, doctorProvider);
            },
            tooltip: 'Filtrer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              doctorProvider.refreshData();
            },
            tooltip: 'Rafraîchir',
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
              
              // Filtres
              _buildFilterChips(),
              const SizedBox(height: 16),
              
              // Nombre de résultats
              Consumer<DoctorProvider>(
                builder: (context, provider, child) {
                  final activeFilter = _getActiveFilter();
                  final filteredDoctors = _getFilteredDoctors(provider);
                  return _buildResultsCount(filteredDoctors.length, activeFilter);
                },
              ),
              const SizedBox(height: 8),
              
              // Liste des médecins
              Expanded(
                child: _buildDoctorsList(doctorProvider),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Scroll to top
          PrimaryScrollController.of(context).animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
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
                hintText: 'Search doctor by name, specialty, hospital...',
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                // Désélectionner tous les filtres
                for (var f in _filters) {
                  f['isSelected'] = false;
                }
                // Sélectionner le filtre cliqué
                _filters[index]['isSelected'] = true;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: index == _filters.length - 1 ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: filter['isSelected'] 
                    ? AppTheme.primaryColor 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: filter['isSelected']
                      ? AppTheme.primaryColor
                      : AppTheme.lightGrey,
                  width: filter['isSelected'] ? 2 : 1,
                ),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: filter['isSelected'] 
                      ? Colors.white 
                      : AppTheme.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsCount(int count, String activeFilter) {
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
              text: '$count ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const TextSpan(text: 'doctor(s) found'),
            if (activeFilter.toLowerCase() != 'all')
              TextSpan(
                text: ' in $activeFilter',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(DoctorProvider doctorProvider) {
    if (doctorProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading doctors...',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ],
        ),
      );
    }

    if (doctorProvider.error != null) {
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
              'Error: ${doctorProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                doctorProvider.refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredDoctors = _getFilteredDoctors(doctorProvider);

    if (filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_doctors.png', // Créez cette image
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'No doctors found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filter',
              style: TextStyle(color: AppTheme.greyColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  for (var f in _filters) {
                    f['isSelected'] = false;
                  }
                  _filters[0]['isSelected'] = true;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        doctorProvider.refreshData();
      },
      child: ListView.separated(
        itemCount: filteredDoctors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doctor = filteredDoctors[index];
          return _buildDoctorCard(doctor, doctorProvider);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, DoctorProvider provider) {
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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du médecin avec badge
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.lightGrey,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildDoctorImage(doctor.imageUrl),
                        ),
                      ),
                      if (doctor.experience >= 10)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'EXPERT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Informations du médecin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                doctor.specialization,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
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
                                  ' (${doctor.reviews})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.work,
                                  size: 14,
                                  color: AppTheme.greyColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${doctor.experience} yrs',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
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
                      ],
                    ),
                  ),
                ],
              ),

              // Séparateur
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppTheme.lightGrey.withOpacity(0.5),
              ),
              
              // Informations supplémentaires
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.access_time, 'Available'),
                  _buildInfoItem(Icons.videocam, 'Video Consult'),
                  _buildInfoItem(Icons.language, 'Multi-lingual'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: AppTheme.lightGrey,
        child: const Center(
          child: Icon(
            Icons.person,
            size: 40,
            color: Colors.white,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.lightGrey,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.lightGrey,
        child: const Center(
          child: Icon(
            Icons.person,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  List<Doctor> _getFilteredDoctors(DoctorProvider provider) {
    final searchQuery = _searchController.text.toLowerCase();
    final activeFilter = _getActiveFilter();

    List<Doctor> filteredDoctors = provider.getDoctorsBySpecialty(activeFilter);

    if (searchQuery.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((doctor) {
        return doctor.name.toLowerCase().contains(searchQuery) ||
               doctor.specialization.toLowerCase().contains(searchQuery) ||
               doctor.hospital.toLowerCase().contains(searchQuery) ||
               doctor.department!.toLowerCase().contains(searchQuery) ;
      }).toList();
    }

    return filteredDoctors;
  }

  String _getActiveFilter() {
    final activeFilter = _filters.firstWhere(
      (filter) => filter['isSelected'] == true,
    )['label'] as String;
    
    // Mapping des filtres simplifiés vers les spécialités réelles
    if (activeFilter == 'Cardio') return 'Cardiologue';
    if (activeFilter == 'Dentist') return 'Dentiste';
    return activeFilter;
  }

  void _showFilterDialog(BuildContext context, DoctorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FilterDialogContent(
          provider: provider,
          onApplyFilters: () {
            setState(() {});
          },
        );
      },
    );
  }
}

class _FilterDialogContent extends StatefulWidget {
  final DoctorProvider provider;
  final VoidCallback onApplyFilters;

  const _FilterDialogContent({
    required this.provider,
    required this.onApplyFilters,
  });

  @override
  __FilterDialogContentState createState() => __FilterDialogContentState();
}

class __FilterDialogContentState extends State<_FilterDialogContent> {
  double _minRating = 0;
  double _maxPrice = 200;
  String? _selectedHospital;

  @override
  Widget build(BuildContext context) {
    final hospitals = widget.provider.doctors
        .map((doctor) => doctor.hospital)
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Rating filter
          const Text(
            'Minimum Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('0'),
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value;
                    });
                  },
                ),
              ),
              Text(_minRating.toStringAsFixed(1)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Price filter
          const Text(
            'Maximum Price',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('\$0'),
              Expanded(
                child: Slider(
                  value: _maxPrice,
                  min: 0,
                  max: 200,
                  divisions: 20,
                  label: '\$${_maxPrice.toInt()}',
                  onChanged: (value) {
                    setState(() {
                      _maxPrice = value;
                    });
                  },
                ),
              ),
              Text('\$${_maxPrice.toInt()}'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Hospital filter
          const Text(
            'Hospital',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedHospital,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Select hospital',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All hospitals'),
              ),
              ...hospitals.map((hospital) {
                return DropdownMenuItem(
                  value: hospital,
                  child: Text(hospital),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedHospital = value;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _minRating = 0;
                      _maxPrice = 200;
                      _selectedHospital = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Appliquer les filtres
                    // Note: Pour une implémentation complète, vous devriez
                    // stocker ces filtres dans le Provider
                    Navigator.pop(context);
                    widget.onApplyFilters();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filters applied'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}