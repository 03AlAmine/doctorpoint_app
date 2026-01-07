import 'package:doctorpoint/data/models/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';


class DoctorDetailPage extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                doctor.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  doctor.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: doctor.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.specialization,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note et expérience
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.star,
                        '${doctor.rating}',
                        'Note',
                        Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.medical_services,
                        '${doctor.experience} ans',
                        'Expérience',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.people,
                        '${doctor.reviews}',
                        'Avis',
                        Colors.blue,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // À propos
                  const Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le Dr. Sarah Johnson est un cardiologue certifié avec plus de 10 ans d\'expérience dans le traitement des maladies cardiovasculaires.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Disponibilité
                  _buildAvailabilitySection(),
                  
                  const SizedBox(height: 24),
                  
                  // Langues parlées
                  _buildLanguagesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Localisation
                  _buildLocationSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prix de consultation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${doctor.consultationFee}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showBookingModal(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Prendre rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilité',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTimeSlot('09:00 AM'),
            _buildTimeSlot('10:30 AM'),
            _buildTimeSlot('02:00 PM'),
            _buildTimeSlot('04:30 PM'),
            _buildTimeSlot('06:00 PM'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlot(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showBookingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BookingModal(doctor: doctor);
      },
    );
  }
  
  _buildLanguagesSection() {}
  
  _buildLocationSection() {}
}

class BookingModal extends StatefulWidget {
  final Doctor doctor;

  const BookingModal({super.key, required this.doctor});

  @override
  // ignore: library_private_types_in_public_api
  _BookingModalState createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  DateTime? _selectedDate;
  String? _selectedTime;
  AppointmentType _selectedType = AppointmentType.videoCall;

  @override
  Widget build(BuildContext context) {
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
            'Prendre rendez-vous',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Type de consultation
          const Text(
            'Type de consultation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAppointmentTypeCard(
                AppointmentType.videoCall,
                Icons.videocam,
                'Vidéo',
                'Appel vidéo en direct',
              ),
              const SizedBox(width: 12),
              _buildAppointmentTypeCard(
                AppointmentType.voiceCall,
                Icons.call,
                'Audio',
                'Appel téléphonique',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Date
          const Text(
            'Sélectionner une date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildDateSelector(),
          
          const SizedBox(height: 24),
          
          // Heure
          const Text(
            'Sélectionner une heure',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimeSelector(),
          
          const SizedBox(height: 32),
          
          // Bouton de confirmation
          ElevatedButton(
            onPressed: () {
              _confirmBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Confirmer le rendez-vous',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeCard(
    AppointmentType type,
    IconData icon,
    String title,
    String description,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedType == type 
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedType == type 
                  ? Colors.blue
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedType == type ? Colors.blue : Colors.black,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDate?.day == date.day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getMonthName(date.month),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    final times = ['09:00', '10:30', '14:00', '16:30', '18:00'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((time) {
        final isSelected = _selectedTime == time;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mer';
      case 4: return 'Jeu';
      case 5: return 'Ven';
      case 6: return 'Sam';
      case 7: return 'Dim';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Fév';
      case 3: return 'Mar';
      case 4: return 'Avr';
      case 5: return 'Mai';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aoû';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Déc';
      default: return '';
    }
  }

  void _confirmBooking() {
    // Logique de confirmation du rendez-vous
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rendez-vous confirmé avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }
}