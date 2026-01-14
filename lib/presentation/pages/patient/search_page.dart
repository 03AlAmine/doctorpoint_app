// lib/presentation/pages/patient/search_page.dart
// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/core/providers/specialty_provider.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/specialty_model.dart';
import 'package:doctorpoint/presentation/pages/patient/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/widgets/doctor_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedFilter = 'tous';
  String _searchQuery = '';
  bool _isSearching = false;
  List<Doctor> _searchResults = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // Simuler le chargement des recherches récentes depuis le stockage local
    // À remplacer par SharedPreferences ou Hive
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _recentSearches = [
        'Cardiologue',
        'Dentiste',
        'Pédiatre',
        'Gynécologue',
        'Dermatologue',
        'Consultation vidéo',
      ];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final specialtyProvider =
        Provider.of<SpecialtyProvider>(context, listen: false);

    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulation délai réseau

    try {
      List<Doctor> results = [];

      // Rechercher dans les médecins
      results.addAll(doctorProvider.searchDoctors(query));

      // Rechercher par spécialité
      final specialtyResults = specialtyProvider.searchSpecialties(query);
      for (final specialty in specialtyResults) {
        final doctors = doctorProvider.getDoctorsBySpecialty(specialty.name);
        results.addAll(doctors);
      }

      // Éliminer les doublons
      results = results.toSet().toList();

      // Appliquer le filtre
      if (_selectedFilter != 'tous') {
        results = results.where((doctor) {
          return doctor.specialization
              .toLowerCase()
              .contains(_selectedFilter.toLowerCase());
        }).toList();
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      // Sauvegarder la recherche si c'est nouveau
      _saveRecentSearch(query);
    } catch (e) {
      print('Erreur recherche: $e');
      setState(() => _isSearching = false);
    }
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.sublist(0, 10);
        }
      });

      // Sauvegarder dans le stockage local
      // SharedPreferences.getInstance().then((prefs) {
      //   prefs.setStringList('recent_searches', _recentSearches);
      // });
    }
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });

    // Effacer du stockage local
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.remove('recent_searches');
    // });
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Bouton retour
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.textColor,
              size: isSmallScreen ? 22 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 40 : 48,
              minHeight: isSmallScreen ? 40 : 48,
            ),
          ),

          // Champ de recherche
          Expanded(
            child: Container(
              height: isSmallScreen ? 48 : 52,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: isSmallScreen ? 12 : 16,
                      right: 8,
                    ),
                    child: Icon(
                      Icons.search,
                      color: AppTheme.greyColor,
                      size: isSmallScreen ? 20 : 22,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Rechercher un médecin, une spécialité, une clinique...',
                        hintStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: AppTheme.greyColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppTheme.textColor,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _performSearch(value.trim());
                        }
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppTheme.greyColor,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.requestFocus();
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 36 : 40,
                        minHeight: isSmallScreen ? 36 : 40,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bouton microphone
          IconButton(
            icon: Icon(
              Icons.mic_none,
              color: AppTheme.primaryColor,
              size: isSmallScreen ? 20 : 22,
            ),
            onPressed: _startVoiceSearch,
            padding: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 40 : 48,
              minHeight: isSmallScreen ? 40 : 48,
            ),
          ),
        ],
      ),
    );
  }

  void _startVoiceSearch() {
    // Implémenter la recherche vocale
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche vocale'),
        content: const Text('Cette fonctionnalité sera bientôt disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final doctorProvider = Provider.of<DoctorProvider>(context);

    // Récupérer les spécialités uniques des médecins
    final specialties = doctorProvider.doctors
        .map((doctor) => doctor.specialization)
        .toSet()
        .toList();

    specialties.insert(0, 'Tous');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer par spécialité',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isSmallScreen ? 36 : 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: specialties.length,
              itemBuilder: (context, index) {
                final specialty = specialties[index];
                final isSelected = _selectedFilter == specialty.toLowerCase();

                return Container(
                  margin: EdgeInsets.only(
                    right: index == specialties.length - 1 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      specialty,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: isSelected ? Colors.white : AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter =
                            selected ? specialty.toLowerCase() : 'tous';
                      });
                      if (_searchQuery.isNotEmpty) {
                        _performSearch(_searchQuery);
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryColor,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 20 : 24),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState();
    }

    if (_searchQuery.isNotEmpty) {
      return _buildResultsList();
    }

    return _buildInitialState();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: isSmallScreen ? 80 : 100,
              color: AppTheme.lightGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Nous n\'avons trouvé aucun médecin correspondant à "$_searchQuery"',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.requestFocus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 32 : 40,
                  vertical: isSmallScreen ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Text(
                'Nouvelle recherche',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      children: [
        // En-tête résultats
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} ${_searchResults.length > 1 ? 'médecins trouvés' : 'médecin trouvé'}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Text(
                  'Pour "$_searchQuery"',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),

        // Liste des résultats
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_searchQuery.isNotEmpty) {
                await _performSearch(_searchQuery);
              }
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 16,
                horizontal: isSmallScreen ? 12 : 16,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final doctor = _searchResults[index];
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
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
                      Provider.of<DoctorProvider>(context, listen: false)
                          .toggleFavorite(doctor.id);
                    },
                    isCompact: isSmallScreen,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final specialtyProvider = Provider.of<SpecialtyProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherches récentes
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 17 : 19,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Tout effacer',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 12 : 16),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: isSmallScreen ? 16 : 18,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          search,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Médecins populaires
          if (doctorProvider.popularDoctors.isNotEmpty) ...[
            Text(
              'Médecins populaires',
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 19,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 220 : 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: doctorProvider.popularDoctors.take(5).length,
                itemBuilder: (context, index) {
                  final doctor = doctorProvider.popularDoctors[index];
                  final cardWidth = isSmallScreen ? 180 : 220;

                  return Container(
                    width: cardWidth.toDouble(),
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
                      isCompact: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Spécialités
          if (specialtyProvider.specialties.isNotEmpty) ...[
            Text(
              'Parcourir par spécialité',
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 19,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 3 : 4,
                crossAxisSpacing: isSmallScreen ? 12 : 16,
                mainAxisSpacing: isSmallScreen ? 12 : 16,
                childAspectRatio: isSmallScreen ? 0.9 : 1.0,
              ),
              itemCount: specialtyProvider.specialties.take(9).length,
              itemBuilder: (context, index) {
                final specialty = specialtyProvider.specialties[index];
                return _buildSpecialtyCard(specialty, isSmallScreen);
              },
            ),
            const SizedBox(height: 32),
          ],

          // Suggestions
          Text(
            'Suggestions de recherche',
            style: TextStyle(
              fontSize: isSmallScreen ? 17 : 19,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isSmallScreen ? 2 : 3,
              crossAxisSpacing: isSmallScreen ? 12 : 16,
              mainAxisSpacing: isSmallScreen ? 12 : 16,
              childAspectRatio: isSmallScreen ? 2.5 : 3.0,
            ),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return _buildSuggestionCard(suggestion, isSmallScreen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(Specialty specialty, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      child: InkWell(
        onTap: () {
          _searchController.text = specialty.name;
          _performSearch(specialty.name);
        },
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: specialty.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(
              color: specialty.color.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 40 : 48,
                height: isSmallScreen ? 40 : 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _getSpecialtyIcon(
                      specialty.name, isSmallScreen ? 22 : 24),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                specialty.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${specialty.doctorCount} médecins',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSpecialtyIcon(String name, double size) {
    IconData iconData;
    Color color;

    switch (name.toLowerCase()) {
      case 'cardiologie':
        iconData = Icons.favorite;
        color = Colors.red;
        break;
      case 'dermatologie':
        iconData = Icons.face;
        color = Colors.blue;
        break;
      case 'neurologie':
        iconData = Icons.psychology;
        color = Colors.purple;
        break;
      case 'pédiatrie':
        iconData = Icons.child_care;
        color = Colors.green;
        break;
      case 'dentisterie':
        iconData = Icons.medical_services;
        color = Colors.orange;
        break;
      case 'gynécologie':
        iconData = Icons.female;
        color = Colors.pink;
        break;
      case 'ophtalmologie':
        iconData = Icons.remove_red_eye;
        color = Colors.indigo;
        break;
      case 'orthopédie':
        iconData = Icons.accessible;
        color = Colors.brown;
        break;
      default:
        iconData = Icons.medical_services;
        color = AppTheme.primaryColor;
    }

    return Icon(iconData, color: color, size: size);
  }

  final List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Consultation vidéo',
      'icon': Icons.videocam,
      'color': Colors.purple,
      'search': 'consultation vidéo',
    },
    {
      'title': 'Urgence 24/7',
      'icon': Icons.medical_services,
      'color': Colors.red,
      'search': 'urgence',
    },
    {
      'title': 'Proche de moi',
      'icon': Icons.location_on,
      'color': Colors.green,
      'search': 'proche',
    },
    {
      'title': 'Disponible aujourd\'hui',
      'icon': Icons.event_available,
      'color': Colors.blue,
      'search': 'disponible',
    },
    {
      'title': 'Français/Anglais',
      'icon': Icons.language,
      'color': Colors.orange,
      'search': 'français anglais',
    },
    {
      'title': 'Tarif réduit',
      'icon': Icons.attach_money,
      'color': Colors.amber,
      'search': 'tarif réduit',
    },
  ];

  Widget _buildSuggestionCard(
      Map<String, dynamic> suggestion, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      child: InkWell(
        onTap: () {
          _searchController.text = suggestion['search'];
          _performSearch(suggestion['search']);
        },
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: suggestion['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(
              color: suggestion['color'].withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 42,
                height: isSmallScreen ? 36 : 42,
                decoration: BoxDecoration(
                  color: suggestion['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    suggestion['icon'],
                    color: suggestion['color'],
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion['title'],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: isSmallScreen ? 14 : 16,
                color: suggestion['color'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // Filtres (seulement quand on recherche)
          if (_searchQuery.isNotEmpty) _buildFilters(),

          // Contenu principal
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),

      // Bouton pour créer un nouveau rendez-vous direct
      floatingActionButton: _searchQuery.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Option: Naviguer vers un formulaire rapide
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Prise de rendez-vous rapide'),
                    content: const Text(
                        'Cette fonctionnalité vous permettra de prendre un rendez-vous sans chercher un médecin spécifique.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Naviguer vers le formulaire rapide
                        },
                        child: const Text('Continuer'),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: Text(
                'Nouveau RDV',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}
