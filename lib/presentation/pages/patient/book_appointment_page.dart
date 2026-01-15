// lib/presentation/pages/patient/book_appointment_page.dart (version adaptée)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/services/patient_appointment_service.dart';

class BookAppointmentPage extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentPage({super.key, required this.doctor});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final PatientAppointmentService _appointmentService =
      PatientAppointmentService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String _selectedType = 'Présentiel';
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<DateTime> _availableDates = [];
  List<String> _availableSlots = [];
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  final List<String> _consultationTypes = [
    'Présentiel',
    'Vidéo',
    'Audio',
  ];

  final Map<String, IconData> _typeIcons = {
    'Présentiel': Icons.person,
    'Vidéo': Icons.videocam,
    'Audio': Icons.call,
  };

  final Map<String, Color> _typeColors = {
    'Présentiel': AppTheme.primaryColor,
    'Vidéo': Colors.purple,
    'Audio': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Charger les dates disponibles
      final dates = await _appointmentService.getAvailableDays(
        doctorId: widget.doctor.id,
        startDate: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _availableDates = dates;
          if (dates.isNotEmpty) {
            _selectedDate = dates.first;
          }
        });

        // Charger les créneaux pour la première date
        if (dates.isNotEmpty) {
          await _loadAvailableSlots();
        }
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      if (mounted) {
        _showError('Impossible de charger les disponibilités');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
      _availableSlots = [];
    });

    try {
      final slots = await _appointmentService.getAvailableSlots(
        doctorId: widget.doctor.id,
        date: _selectedDate,
      );

      if (mounted) {
        setState(() {
          _availableSlots = slots;
        });
      }
    } catch (e) {
      print('Erreur chargement créneaux: $e');
      if (mounted) {
        _showError('Impossible de charger les créneaux horaires');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) {
      _showError('Veuillez sélectionner un horaire');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showError('Veuillez indiquer la raison de la consultation');
      return;
    }

    setState(() => _isBooking = true);

    try {
      final result = await _appointmentService.bookAppointment(
        doctorId: widget.doctor.id,
        date: _selectedDate,
        time: _selectedTime!,
        type: _selectedType,
        reason: _reasonController.text.trim(),
        symptoms: _symptomsController.text.trim().isNotEmpty
            ? _symptomsController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        amount: widget.doctor.consultationFee,
      );

      if (result['success'] == true) {
        _showSuccessDialog(
          'Rendez-vous pris avec succès',
          'Votre rendez-vous a été enregistré. Le médecin confirmera bientôt.',
          result['appointmentId'] ?? 'N/A',
        );
      } else {
        _showError(result['error'] ?? 'Erreur lors de la prise de rendez-vous');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, String appointmentId) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'N° RDV: ${appointmentId.substring(0, 8)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retour aux rendez-vous'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    if (_availableDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune date disponible pour ce médecin',
                style: TextStyle(
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Choisir une date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () async {
                  if (!isSelected) {
                    setState(() {
                      _selectedDate = date;
                      _selectedTime = null;
                    });
                    await _loadAvailableSlots();
                  }
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : isToday
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : AppTheme.borderColor,
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE', 'fr_FR').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.greyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM', 'fr_FR').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppTheme.greyColor,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Aujourd\'hui',
                            style: TextStyle(
                              fontSize: 8,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildTimeSlotsSelector() {
    if (_isLoadingSlots) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des horaires...',
              style: TextStyle(
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 60,
              color: AppTheme.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun créneau disponible',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez choisir une autre date',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Choisir un horaire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((timeSlot) {
              // Changement : timeSlot est maintenant un String
              final isSelected = _selectedTime == timeSlot;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = timeSlot;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    timeSlot, // Utilisation directe du String
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Type de consultation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _consultationTypes.map((type) {
              final isSelected = _selectedType == type;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _typeColors[type] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _typeColors[type]!
                          : AppTheme.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _typeColors[type]!.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _typeIcons[type],
                        size: 18,
                        color: isSelected ? Colors.white : _typeColors[type],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _typeColors[type],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo du médecin
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: AppTheme.lightGrey,
                child: widget.doctor.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.doctor.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctor.specialization,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctor.hospital,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.doctor.reviews} avis)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.doctor.consultationFee.toStringAsFixed(0)}€',
                        style: TextStyle(
                          fontSize: 18,
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
      ),
    );
  }

  Widget _buildReasonInput() {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raison de la consultation*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Décrivez brièvement la raison de votre consultation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ));
  }

  Widget _buildSymptomsInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symptômes (optionnel)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomsController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Décrivez vos symptômes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes supplémentaires (optionnel)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ajoutez des informations complémentaires...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isBooking
              ? null
              : (_selectedTime == null || _reasonController.text.trim().isEmpty)
                  ? null
                  : _bookAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedTime != null &&
                    _reasonController.text.trim().isNotEmpty
                ? AppTheme.primaryColor
                : AppTheme.greyColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
          ),
          child: _isBooking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Prendre rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre rendez-vous'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDoctorInfo(),
                        _buildDateSelector(),
                        const SizedBox(height: 24),
                        _buildTimeSlotsSelector(),
                        const SizedBox(height: 24),
                        _buildConsultationTypeSelector(),
                        const SizedBox(height: 24),
                        _buildReasonInput(),
                        const SizedBox(height: 16),
                        _buildSymptomsInput(),
                        const SizedBox(height: 16),
                        _buildNotesInput(),
                        const SizedBox(height: 24),
                        if (_selectedTime != null)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Récapitulatif',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppTheme.greyColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                          .format(_selectedDate),
                                      style: TextStyle(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppTheme.greyColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTime!,
                                      style: TextStyle(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      _typeIcons[_selectedType]!,
                                      size: 16,
                                      color: AppTheme.greyColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedType,
                                      style: TextStyle(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total à payer:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${widget.doctor.consultationFee.toStringAsFixed(0)}€',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildBookingButton(),
                ),
              ],
            ),
    );
  }
}
