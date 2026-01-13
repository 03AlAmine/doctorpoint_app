import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/presentation/pages/patient/doctor_detail_page.dart';
import 'package:doctorpoint/presentation/widgets/doctor_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Cardiologue',
    'Dentiste Paris',
    'Pédiatre',
    'Dr. Sarah',
  ];
  final List<String> _filters = [
    'Tous',
    'Cardiologie',
    'Dermatologie',
    'Pédiatrie',
    'Dentiste',
    'Neurologie',
  ];

  String _selectedFilter = 'Tous';
  List<Doctor> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      setState(() {
        _searchResults = doctorProvider.searchDoctors(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher un médecin, une spécialité...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Activation de la recherche vocale
            },
          ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? _buildInitialState()
          : _buildSearchResults(),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres
          Text(
            'Filtrer par spécialité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _filters.length - 1 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Recherches récentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recherches récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return InputChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _recentSearches.remove(search);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Suggestions populaires
          Text(
            'Suggestions populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildSuggestionChip('Cardiologue près de moi', Icons.location_on),
              _buildSuggestionChip('Dentiste disponible', Icons.event_available),
              _buildSuggestionChip('Pédiatre urgences', Icons.medical_services),
              _buildSuggestionChip('Consultation vidéo', Icons.videocam),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final doctor = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DoctorCard(
            doctor: doctor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailPage(doctor: doctor),
                ),
              );
            },
            onFavoriteTap: () {
              Provider.of<DoctorProvider>(context, listen: false)
                  .toggleFavorite(doctor.id);
            },
            isCompact: false,
          ),
        );
      },
    );
  }
}