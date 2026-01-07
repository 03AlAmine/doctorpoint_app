import 'package:flutter/material.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class BookingModal extends StatefulWidget {
  final Doctor doctor;

  const BookingModal({super.key, required this.doctor});

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  String? _selectedTime;
  String _selectedType = 'video';
  String _selectedReason = 'Consultation générale';



  final List<String> _reasons = [
    'Consultation générale',
    'Suivi de traitement',
    'Deuxième avis',
    'Urgence',
    'Prévention',
    'Autre',
  ];

  final List<Map<String, String>> _availableTimes = [
    {'date': 'Lun 15 Déc', 'time': '09:00'},
    {'date': 'Lun 15 Déc', 'time': '10:30'},
    {'date': 'Lun 15 Déc', 'time': '14:00'},
    {'date': 'Mar 16 Déc', 'time': '11:00'},
    {'date': 'Mar 16 Déc', 'time': '15:30'},
    {'date': 'Mer 17 Déc', 'time': '09:30'},
    {'date': 'Mer 17 Déc', 'time': '13:00'},
    {'date': 'Jeu 18 Déc', 'time': '10:00'},
    {'date': 'Jeu 18 Déc', 'time': '16:00'},
  ];

  final TextEditingController _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            const Text(
              'Prendre rendez-vous',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Avec Dr. ${widget.doctor.name.split(' ').last}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 24),

            // Type de consultation
            _buildSectionTitle('Type de consultation'),
            const SizedBox(height: 12),
            _buildConsultationTypes(),
            const SizedBox(height: 24),

            // Date et heure
            _buildSectionTitle('Date et heure'),
            const SizedBox(height: 12),
            _buildDateTimeSelector(),
            const SizedBox(height: 24),

            // Motif de consultation
            _buildSectionTitle('Motif de consultation'),
            const SizedBox(height: 12),
            _buildReasonSelector(),
            const SizedBox(height: 24),

            // Symptômes
            _buildSectionTitle('Décrivez vos symptômes (optionnel)'),
            const SizedBox(height: 12),
            _buildSymptomsInput(),
            const SizedBox(height: 32),

            // Récapitulatif
            _buildSummary(),
            const SizedBox(height: 32),

            // Boutons d'action
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildConsultationTypes() {
    return Row(
      children: [
        _buildTypeOption(
          icon: Icons.videocam,
          label: 'Vidéo',
          type: 'video',
          description: 'Appel vidéo',
        ),
        const SizedBox(width: 12),
        _buildTypeOption(
          icon: Icons.call,
          label: 'Audio',
          type: 'audio',
          description: 'Appel téléphonique',
        ),
        const SizedBox(width: 12),
        _buildTypeOption(
          icon: Icons.person,
          label: 'Présentiel',
          type: 'in_person',
          description: 'En cabinet',
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required IconData icon,
    required String label,
    required String type,
    required String description,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.lightGrey,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.greyColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dates
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDateOption('Lun', '15'),
              const SizedBox(width: 12),
              _buildDateOption('Mar', '16'),
              const SizedBox(width: 12),
              _buildDateOption('Mer', '17'),
              const SizedBox(width: 12),
              _buildDateOption('Jeu', '18'),
              const SizedBox(width: 12),
              _buildDateOption('Ven', '19'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Créneaux horaires
        const Text(
          'Sélectionnez un créneau horaire',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var timeSlot in _availableTimes)
              _buildTimeOption(timeSlot['time']!),
          ],
        ),
      ],
    );
  }

  Widget _buildDateOption(String day, String date) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.lightGrey,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason;
        return ChoiceChip(
          label: Text(reason),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedReason = reason);
          },
          selectedColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomsInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: TextField(
        controller: _symptomsController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Décrivez vos symptômes, douleurs, ou questions...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Consultation', '\$${widget.doctor.consultationFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Frais de service', '\$5.00'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '\$${(widget.doctor.consultationFee + 5).toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textColor : AppTheme.greyColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 18),
                SizedBox(width: 8),
                Text(
                  'Confirmer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmBooking() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un créneau horaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rendez-vous confirmé avec succès !'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Naviguer vers la page des rendez-vous
          },
        ),
      ),
    );
  }
}