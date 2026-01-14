// lib/data/models/doctor_availability.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String start;
  final String end;
  final bool isAvailable;
  final bool isBreak;

  TimeSlot({
    required this.start,
    required this.end,
    this.isAvailable = true,
    this.isBreak = false,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] ?? '',
      end: map['end'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isBreak: map['isBreak'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
      'isAvailable': isAvailable,
      'isBreak': isBreak,
    };
  }

  // Ajouter la méthode copyWith
  TimeSlot copyWith({
    String? start,
    String? end,
    bool? isAvailable,
    bool? isBreak,
  }) {
    return TimeSlot(
      start: start ?? this.start,
      end: end ?? this.end,
      isAvailable: isAvailable ?? this.isAvailable,
      isBreak: isBreak ?? this.isBreak,
    );
  }

  bool overlapsWith(TimeSlot other) {
    final thisStart = _timeToMinutes(start);
    final thisEnd = _timeToMinutes(end);
    final otherStart = _timeToMinutes(other.start);
    final otherEnd = _timeToMinutes(other.end);

    return thisStart < otherEnd && thisEnd > otherStart;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class DaySchedule {
  final String day;
  final bool isAvailable;
  final List<TimeSlot> timeSlots;
  final List<TimeSlot> breakTimes;

  DaySchedule({
    required this.day,
    this.isAvailable = true,
    this.timeSlots = const [],
    this.breakTimes = const [],
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      day: map['day'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      timeSlots: (map['timeSlots'] as List? ?? [])
          .map((slot) => TimeSlot.fromMap(slot))
          .toList(),
      breakTimes: (map['breakTimes'] as List? ?? [])
          .map((slot) => TimeSlot.fromMap(slot))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'isAvailable': isAvailable,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'breakTimes': breakTimes.map((slot) => slot.toMap()).toList(),
    };
  }

  // Ajouter la méthode copyWith
  DaySchedule copyWith({
    String? day,
    bool? isAvailable,
    List<TimeSlot>? timeSlots,
    List<TimeSlot>? breakTimes,
  }) {
    return DaySchedule(
      day: day ?? this.day,
      isAvailable: isAvailable ?? this.isAvailable,
      timeSlots: timeSlots ?? this.timeSlots,
      breakTimes: breakTimes ?? this.breakTimes,
    );
  }

  List<String> generateTimeSlots(int duration) {
    final slots = <String>[];

    for (final slot in timeSlots) {
      if (slot.isAvailable) {
        var current = _timeToMinutes(slot.start);
        final end = _timeToMinutes(slot.end);

        while (current + duration <= end) {
          if (!_isDuringBreak(current, duration)) {
            final hour = (current ~/ 60).toString().padLeft(2, '0');
            final minute = (current % 60).toString().padLeft(2, '0');
            slots.add('$hour:$minute');
          }
          current += duration;
        }
      }
    }

    return slots;
  }

  bool _isDuringBreak(int startMinute, int duration) {
    final endMinute = startMinute + duration;

    for (final breakSlot in breakTimes) {
      final breakStart = _timeToMinutes(breakSlot.start);
      final breakEnd = _timeToMinutes(breakSlot.end);

      if (startMinute < breakEnd && endMinute > breakStart) {
        return true;
      }
    }

    return false;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class DoctorAvailability {
  final String doctorId;
  final List<DaySchedule> weeklySchedule;
  final List<DateTime> holidays;
  final int appointmentDuration; // en minutes
  final int bufferTime; // temps entre deux rendez-vous

  DoctorAvailability({
    required this.doctorId,
    this.weeklySchedule = const [],
    this.holidays = const [],
    this.appointmentDuration = 30,
    this.bufferTime = 5,
  });

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    return DoctorAvailability(
      doctorId: map['doctorId'] ?? '',
      weeklySchedule: (map['weeklySchedule'] as List? ?? [])
          .map((day) => DaySchedule.fromMap(day))
          .toList(),
      holidays: (map['holidays'] as List? ?? [])
          .map((date) => (date as Timestamp).toDate())
          .toList(),
      appointmentDuration: map['appointmentDuration'] ?? 30,
      bufferTime: map['bufferTime'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'weeklySchedule': weeklySchedule.map((day) => day.toMap()).toList(),
      'holidays': holidays.map((date) => Timestamp.fromDate(date)).toList(),
      'appointmentDuration': appointmentDuration,
      'bufferTime': bufferTime,
    };
  }

  DoctorAvailability copyWith({
    String? doctorId,
    List<DaySchedule>? weeklySchedule,
    List<DateTime>? holidays,
    int? appointmentDuration,
    int? bufferTime,
  }) {
    return DoctorAvailability(
      doctorId: doctorId ?? this.doctorId,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      holidays: holidays ?? this.holidays,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      bufferTime: bufferTime ?? this.bufferTime,
    );
  }

  List<String> getAvailableTimeSlots(DateTime date) {
    final dayOfWeek = _getDayName(date.weekday);
    final schedule = weeklySchedule.firstWhere(
      (day) => day.day.toLowerCase() == dayOfWeek.toLowerCase(),
      orElse: () => DaySchedule(day: dayOfWeek, isAvailable: false),
    );

    if (!schedule.isAvailable || _isHoliday(date)) {
      return [];
    }

    return schedule.generateTimeSlots(appointmentDuration + bufferTime);
  }

  bool _isHoliday(DateTime date) {
    return holidays.any((holiday) =>
        holiday.year == date.year &&
        holiday.month == date.month &&
        holiday.day == date.day);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return '';
    }
  }
}
