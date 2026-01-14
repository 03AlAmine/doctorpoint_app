// lib/presentation/pages/doctor/doctor_availability_page.dart
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/doctor_availability.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  final Doctor doctor;
  final DoctorAvailability? availability;
  final VoidCallback onAvailabilityUpdated;

  const DoctorAvailabilityPage({
    super.key,
    required this.doctor,
    this.availability,
    required this.onAvailabilityUpdated,
  });

  @override
  State<DoctorAvailabilityPage> createState() => _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState extends State<DoctorAvailabilityPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<DaySchedule> _weeklySchedule = [];
  List<DateTime> _holidays = [];
  int _appointmentDuration = 30;
  int _bufferTime = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAvailability();
  }

  void _loadCurrentAvailability() {
    if (widget.availability != null) {
      setState(() {
        _weeklySchedule = widget.availability!.weeklySchedule;
        _holidays = widget.availability!.holidays;
        _appointmentDuration = widget.availability!.appointmentDuration;
        _bufferTime = widget.availability!.bufferTime;
      });
    } else {
      _initializeDefaultSchedule();
    }
  }

  void _initializeDefaultSchedule() {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    
    setState(() {
      _weeklySchedule = days.map((day) {
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
    });
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);

    try {
      final availability = DoctorAvailability(
        doctorId: widget.doctor.id,
        weeklySchedule: _weeklySchedule,
        holidays: _holidays,
        appointmentDuration: _appointmentDuration,
        bufferTime: _bufferTime,
      );

      await _db
          .collection('doctor_availability')
          .doc(widget.doctor.id)
          .set(availability.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disponibilité sauvegardée avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onAvailabilityUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDayScheduleCard(DaySchedule schedule, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.borderColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: schedule.isAvailable,
                onChanged: (value) {
                  setState(() {
                    _weeklySchedule[index] = schedule.copyWith(
                      isAvailable: value ?? false,
                    );
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                schedule.day,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: schedule.isAvailable
                      ? AppTheme.textColor
                      : AppTheme.greyColor,
                ),
              ),
            ),
            if (!schedule.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Fermé',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        initiallyExpanded: schedule.isAvailable,
        children: [
          if (schedule.isAvailable) ...[
            _buildTimeSlotsSection(schedule, index),
            _buildBreakTimesSection(schedule, index),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection(DaySchedule schedule, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Plages horaires',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...schedule.timeSlots.asMap().entries.map((entry) {
            final slotIndex = entry.key;
            final slot = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: slot.start),
                            decoration: InputDecoration(
                              labelText: 'Début',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              final newSlots = List<TimeSlot>.from(schedule.timeSlots);
                              newSlots[slotIndex] = slot.copyWith(start: value);
                              setState(() {
                                _weeklySchedule[dayIndex] = schedule.copyWith(
                                  timeSlots: newSlots,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: slot.end),
                            decoration: InputDecoration(
                              labelText: 'Fin',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              final newSlots = List<TimeSlot>.from(schedule.timeSlots);
                              newSlots[slotIndex] = slot.copyWith(end: value);
                              setState(() {
                                _weeklySchedule[dayIndex] = schedule.copyWith(
                                  timeSlots: newSlots,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (schedule.timeSlots.length > 1)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        final newSlots = List<TimeSlot>.from(schedule.timeSlots);
                        newSlots.removeAt(slotIndex);
                        setState(() {
                          _weeklySchedule[dayIndex] = schedule.copyWith(
                            timeSlots: newSlots,
                          );
                        });
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final newSlots = List<TimeSlot>.from(schedule.timeSlots);
                newSlots.add(TimeSlot(start: '09:00', end: '10:00'));
                setState(() {
                  _weeklySchedule[dayIndex] = schedule.copyWith(
                    timeSlots: newSlots,
                  );
                });
              },
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white,
              ),
              label: Text(
                'Ajouter une plage horaire',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakTimesSection(DaySchedule schedule, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.coffee,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pauses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...schedule.breakTimes.asMap().entries.map((entry) {
            final breakIndex = entry.key;
            final breakSlot = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: breakSlot.start),
                            decoration: InputDecoration(
                              labelText: 'Début pause',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              final newBreaks = List<TimeSlot>.from(schedule.breakTimes);
                              newBreaks[breakIndex] = breakSlot.copyWith(start: value);
                              setState(() {
                                _weeklySchedule[dayIndex] = schedule.copyWith(
                                  breakTimes: newBreaks,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: breakSlot.end),
                            decoration: InputDecoration(
                              labelText: 'Fin pause',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              final newBreaks = List<TimeSlot>.from(schedule.breakTimes);
                              newBreaks[breakIndex] = breakSlot.copyWith(end: value);
                              setState(() {
                                _weeklySchedule[dayIndex] = schedule.copyWith(
                                  breakTimes: newBreaks,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      final newBreaks = List<TimeSlot>.from(schedule.breakTimes);
                      newBreaks.removeAt(breakIndex);
                      setState(() {
                        _weeklySchedule[dayIndex] = schedule.copyWith(
                          breakTimes: newBreaks,
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final newBreaks = List<TimeSlot>.from(schedule.breakTimes);
                newBreaks.add(TimeSlot(start: '12:00', end: '13:00', isBreak: true));
                setState(() {
                  _weeklySchedule[dayIndex] = schedule.copyWith(
                    breakTimes: newBreaks,
                  );
                });
              },
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.white,
              ),
              label: Text(
                'Ajouter une pause',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    // En-tête
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  'Configuration de la disponibilité',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Définissez vos horaires de consultation et vos préférences',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Paramètres généraux
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.borderColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Paramètres généraux',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (isMobile)
                              Column(
                                children: [
                                  _buildDurationField(),
                                  const SizedBox(height: 16),
                                  _buildBufferTimeField(),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(child: _buildDurationField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildBufferTimeField()),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Planning hebdomadaire
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.borderColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Planning hebdomadaire',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configurez vos horaires de consultation pour chaque jour',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._weeklySchedule.asMap().entries.map((entry) {
                              final index = entry.key;
                              final schedule = entry.value;
                              return _buildDayScheduleCard(schedule, index);
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton de sauvegarde
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton(
                        onPressed: _saveAvailability,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'Sauvegarder la disponibilité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée RDV (minutes)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: TextEditingController(
            text: _appointmentDuration.toString(),
          ),
          decoration: InputDecoration(
            hintText: '30',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixText: 'min',
            suffixStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final duration = int.tryParse(value) ?? 30;
            if (duration > 0) {
              setState(() => _appointmentDuration = duration);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBufferTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temps entre RDV',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: TextEditingController(
            text: _bufferTime.toString(),
          ),
          decoration: InputDecoration(
            hintText: '5',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixText: 'min',
            suffixStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final buffer = int.tryParse(value) ?? 5;
            if (buffer >= 0) {
              setState(() => _bufferTime = buffer);
            }
          },
        ),
      ],
    );
  }
}