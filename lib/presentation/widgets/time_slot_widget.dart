import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class TimeSlotWidget extends StatelessWidget {
  final String date;
  final String time;
  final bool isAvailable;
  final VoidCallback? onTap;

  const TimeSlotWidget({
    super.key,
    required this.date,
    required this.time,
    this.isAvailable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAvailable ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isAvailable ? AppTheme.textColor : AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAvailable ? AppTheme.primaryColor : AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isAvailable ? 'Disponible' : 'Occupé',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isAvailable ? AppTheme.primaryColor : AppTheme.greyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}