// lib/presentation/pages/doctor/doctor_agenda_page.dart
// ignore_for_file: unused_field

import 'package:doctorpoint/presentation/pages/doctor/doctor_availability_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/doctor_availability.dart';
import 'package:doctorpoint/services/appointment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAgendaPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorAgendaPage({super.key, required this.doctor});

  @override
  State<DoctorAgendaPage> createState() => _DoctorAgendaPageState();
}

class _DoctorAgendaPageState extends State<DoctorAgendaPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppointmentService _appointmentService = AppointmentService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _selectedTime;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;
  List<String> _availableTimeSlots = [];
  DoctorAvailability? _doctorAvailability;
  List<DaySchedule> _weeklySchedule = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAvailability(),
      _loadAppointments(),
      _loadWeeklySchedule(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAvailability() async {
    try {
      final doc = await _db
          .collection('doctor_availability')
          .doc(widget.doctor.id)
          .get();

      if (doc.exists) {
        setState(() {
          _doctorAvailability = DoctorAvailability.fromMap({
            ...doc.data()!,
            'doctorId': widget.doctor.id,
          });
        });
      } else {
        _createDefaultAvailability();
      }
    } catch (e) {
      print('Erreur chargement disponibilité: $e');
    }
  }

  void _createDefaultAvailability() {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    final defaultSchedule = days.map((day) {
      final isWeekend = day == 'Samedi' || day == 'Dimanche';
      return DaySchedule(
        day: day,
        isAvailable: !isWeekend,
        timeSlots: !isWeekend
            ? [
                TimeSlot(start: '09:00', end: '12:00'),
                TimeSlot(start: '14:00', end: '18:00'),
              ]
            : [],
        breakTimes: !isWeekend
            ? [TimeSlot(start: '12:00', end: '14:00', isBreak: true)]
            : [],
      );
    }).toList();

    setState(() {
      _doctorAvailability = DoctorAvailability(
        doctorId: widget.doctor.id,
        weeklySchedule: defaultSchedule,
        appointmentDuration: 30,
        bufferTime: 5,
      );
    });
  }

  Future<void> _loadWeeklySchedule() async {
    if (_doctorAvailability != null) {
      setState(() {
        _weeklySchedule = _doctorAvailability!.weeklySchedule;
      });
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .orderBy('date')
          .orderBy('time')
          .get();

      final events = <DateTime, List<Map<String, dynamic>>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'];

        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          final appointmentDate = DateTime(year, month, day);

          final patientId = data['patientId'];
          String patientName = 'Patient';
          if (patientId != null) {
            final patientDoc =
                await _db.collection('patients').doc(patientId).get();
            if (patientDoc.exists) {
              patientName = patientDoc['fullName'] ?? 'Patient';
            }
          }

          final event = {
            'id': doc.id,
            'patient': patientName,
            'patientId': patientId,
            'time': data['time'],
            'type': data['type'] ?? 'Présentiel',
            'status': data['status'] ?? 'Pending',
            'duration': data['duration'] ?? 30,
            'reason': data['reason'] ?? 'Consultation',
            'notes': data['notes'],
            'amount': data['amount'] ?? 0.0,
          };

          if (events.containsKey(appointmentDate)) {
            events[appointmentDate]!.add(event);
          } else {
            events[appointmentDate] = [event];
          }
        }
      }

      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Erreur chargement rendez-vous: $e');
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    if (_doctorAvailability == null) return;

    setState(() {
      _isLoading = true;
      _selectedTime = null;
    });

    try {
      final slots = await _appointmentService.getAvailableTimeSlots(
        doctorId: widget.doctor.id,
        date: date,
      );

      setState(() {
        _availableTimeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement créneaux: $e');
      setState(() {
        _isLoading = false;
        _availableTimeSlots = [];
      });
    }
  }

  Widget _buildCalendar() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.borderColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            selectedTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            weekendTextStyle: const TextStyle(color: Colors.red),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            formatButtonTextStyle: const TextStyle(color: Colors.white),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppTheme.primaryColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppTheme.primaryColor,
            ),
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) async {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedTime = null;
            });
            await _loadAvailableTimeSlots(selectedDay);
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },
        ),
      ),
    );
  }

  Widget _buildTimeSlotsGrid() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (_availableTimeSlots.isEmpty) {
      return SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configurez votre disponibilité ou revenez un autre jour',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 3
            : isTablet
                ? 4
                : 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 2.5 : 3,
      ),
      itemCount: _availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _availableTimeSlots[index];
        final isSelected = _selectedTime != null &&
            DateFormat('HH:mm').format(_selectedTime!) == timeSlot;

        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTime = DateFormat('HH:mm').parse(timeSlot);
            });
            _showAddAppointmentDialog(timeSlot);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
            foregroundColor: isSelected ? Colors.white : AppTheme.primaryColor,
            side: BorderSide(
              color: AppTheme.primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isSelected ? 4 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            timeSlot,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsList() {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          'Sélectionnez une date',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 60,
                color: AppTheme.greyColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun rendez-vous ce jour',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Profitez-en pour planifier de nouveaux rendez-vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(events[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final statusColor = _getStatusColor(appointment['status']);
    final typeColor = _getTypeColor(appointment['type']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.borderColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTypeIcon(appointment['type']),
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          appointment['patient'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${appointment['time']} • ${appointment['duration']} min',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (appointment['reason'] != null &&
                appointment['reason'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                appointment['reason'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(appointment['status']),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        onTap: () => _showAppointmentDetails(appointment),
      ),
    );
  }

  void _showAddAppointmentDialog(String timeSlot) {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(
        doctor: widget.doctor,
        date: _selectedDay!,
        time: timeSlot,
        onAppointmentAdded: () {
          _loadAppointments();
          _loadAvailableTimeSlots(_selectedDay!);
        },
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentDetailsDialog(
        appointment: appointment,
        onStatusChanged: _loadAppointments,
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Vidéo':
        return Icons.videocam;
      case 'Audio':
        return Icons.call;
      default:
        return Icons.person;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Vidéo':
        return Colors.purple;
      case 'Audio':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return AppTheme.greyColor;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }

  void _showAvailabilitySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorAvailabilityPage(
          doctor: widget.doctor,
          availability: _doctorAvailability,
          onAvailabilityUpdated: () {
            _loadAvailability();
            _loadWeeklySchedule();
            if (_selectedDay != null) {
              _loadAvailableTimeSlots(_selectedDay!);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              // WRAP THE ENTIRE CONTENT WITH SINGLE CHILD SCROLL VIEW
              child: Column(
                children: [
                  // Header avec boutons d'action
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mon Agenda',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.settings,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                              ),
                              onPressed: _showAvailabilitySettings,
                              tooltip: 'Configurer la disponibilité',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                              ),
                              onPressed: () {
                                _loadAppointments();
                                if (_selectedDay != null) {
                                  _loadAvailableTimeSlots(_selectedDay!);
                                }
                              },
                              tooltip: 'Actualiser',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calendrier
                  _buildCalendar(),

                  // Onglets Rendez-vous et Créneaux disponibles (inversés)
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.5, // FIXED HEIGHT FOR TAB VIEW
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGrey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: AppTheme.textSecondary,
                              indicator: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(4),
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.event, size: 20),
                                  text: 'Rendez-vous',
                                ),
                                Tab(
                                  icon: Icon(Icons.schedule, size: 20),
                                  text: 'Créneaux disponibles',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            // EXPANDED WIDGET FOR TAB VIEW
                            child: TabBarView(
                              children: [
                                // Onglet Rendez-vous (en premier)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          DateFormat('EEEE d MMMM y', 'fr_FR')
                                              .format(_selectedDay!),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        // ANOTHER EXPANDED FOR THE LIST
                                        child: SingleChildScrollView(
                                          child: _buildAppointmentsList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Onglet Créneaux disponibles
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          DateFormat('EEEE d MMMM y', 'fr_FR')
                                              .format(_selectedDay!),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        // ANOTHER EXPANDED FOR THE GRID
                                        child: SingleChildScrollView(
                                          child: _buildTimeSlotsGrid(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


class AppointmentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onStatusChanged;

  const AppointmentDetailsDialog({
    super.key,
    required this.appointment,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment['status']);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails du rendez-vous',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                icon: Icons.person,
                label: 'Patient',
                value: appointment['patient'],
              ),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Heure',
                value: appointment['time'],
              ),
              _buildInfoRow(
                icon: Icons.medical_services,
                label: 'Type',
                value: appointment['type'],
              ),
              _buildInfoRow(
                icon: Icons.timer,
                label: 'Durée',
                value: '${appointment['duration']} minutes',
              ),
              if (appointment['reason'] != null &&
                  appointment['reason'].isNotEmpty)
                _buildInfoRow(
                  icon: Icons.description,
                  label: 'Raison',
                  value: appointment['reason'],
                ),
              if (appointment['notes'] != null &&
                  appointment['notes'].isNotEmpty)
                _buildInfoRow(
                  icon: Icons.note,
                  label: 'Notes',
                  value: appointment['notes'],
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return AppTheme.greyColor;
    }
  }
}

class AddAppointmentDialog extends StatefulWidget {
  final Doctor doctor;
  final DateTime date;
  final String time;
  final VoidCallback onAppointmentAdded;

  const AddAppointmentDialog({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.onAppointmentAdded,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Présentiel';
  final List<String> _appointmentTypes = ['Présentiel', 'Vidéo', 'Audio'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un rendez-vous',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Informations de base
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE d MMMM y', 'fr_FR')
                                      .format(widget.date),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Heure',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.time,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Champ patient
                TextFormField(
                  controller: _patientNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du patient',
                    prefixIcon: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom du patient';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Type de consultation
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type de consultation',
                    prefixIcon: Icon(
                      Icons.medical_services,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _appointmentTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Raison
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Raison de la consultation',
                    prefixIcon: Icon(
                      Icons.description,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes supplémentaires',
                    prefixIcon: Icon(
                      Icons.note,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addAppointment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final appointmentService = AppointmentService();

        await appointmentService.bookAppointment(
          doctorId: widget.doctor.id,
          patientId: '', // À remplacer par l'ID du patient
          date: widget.date,
          time: widget.time,
          type: _selectedType,
          amount: widget.doctor.consultationFee,
          notes: _notesController.text,
          symptoms: _reasonController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous ajouté avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onAppointmentAdded();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
