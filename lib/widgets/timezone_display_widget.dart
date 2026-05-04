import 'package:flutter/material.dart';
import '../services/timezone_service.dart';
import '../theme/app_theme.dart';

/// Widget untuk menampilkan waktu dalam multiple timezone
class TimezoneDisplayWidget extends StatelessWidget {
  final List<DateTime>? wibDateTimes; // Multiple booking times
  final bool showDate;
  final bool compact; // Mode compact untuk space terbatas
  
  // Legacy support for single datetime
  final DateTime? wibDateTime;
  final DateTime? wibEndDateTime;
  
  const TimezoneDisplayWidget({
    super.key,
    this.wibDateTime,
    this.wibEndDateTime,
    this.wibDateTimes,
    this.showDate = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use wibDateTimes if provided, otherwise fallback to single datetime
    final dateTimes = wibDateTimes ?? (wibDateTime != null ? [wibDateTime!] : []);
    
    if (dateTimes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Check if any time has day difference
    final hasDayDiff = dateTimes.any((dt) => TimezoneService.hasDayDifference(dt));
    
    if (compact) {
      return _buildCompactView(dateTimes, hasDayDiff);
    } else {
      return _buildFullView(dateTimes, hasDayDiff);
    }
  }
  
  Widget _buildFullView(List<DateTime> dateTimes, bool hasDayDiff) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E2DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Zona Waktu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Lexend',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // WIB (Primary)
          _buildTimezoneRow(
            dateTimes,
            'WIB',
            isPrimary: true,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 8),
          
          // WITA
          _buildTimezoneRow(
            dateTimes,
            'WITA',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 8),
          
          // WIT
          _buildTimezoneRow(
            dateTimes,
            'WIT',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 8),
          
          // London
          _buildTimezoneRow(
            dateTimes,
            'London',
            icon: Icons.flight_rounded,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactView(List<DateTime> dateTimes, bool hasDayDiff) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Zona Waktu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Lexend',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // WIB
          Text(
            'WIB:\n${_formatMultipleTimes(dateTimes, 'WIB')}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontFamily: 'Lexend',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          // Other timezones
          Text(
            'WITA:\n${_formatMultipleTimes(dateTimes, 'WITA')}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Lexend',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'WIT:\n${_formatMultipleTimes(dateTimes, 'WIT')}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Lexend',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'London:\n${_formatMultipleTimes(dateTimes, 'London')}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Lexend',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimezoneRow(
    List<DateTime> dateTimes,
    String timezone, {
    bool isPrimary = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary 
            ? AppColors.primary.withOpacity(0.08)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary 
              ? AppColors.primary.withOpacity(0.2)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timezone,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                    fontFamily: 'Lexend',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMultipleTimes(dateTimes, timezone),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Format multiple times for a specific timezone
  String _formatMultipleTimes(List<DateTime> wibDateTimes, String targetTimezone) {
    List<String> formattedTimes = [];
    
    for (DateTime wibTime in wibDateTimes) {
      // Convert to target timezone
      final timezones = TimezoneService.convertFromWIB(wibTime);
      final targetTime = timezones[targetTimezone];
      
      if (targetTime != null) {
        // Format with date and time
        final timeStr = TimezoneService.formatTime(targetTime, '', showDate: true);
        formattedTimes.add(timeStr);
      }
    }
    
    // Join with line break for better readability
    return formattedTimes.join('\n');
  }
}
