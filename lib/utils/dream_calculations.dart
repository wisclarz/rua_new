// lib/utils/dream_calculations.dart
// Dream statistics calculations - extracted for reusability and performance

import '../models/dream_model.dart';

/// Utility class for dream-related calculations
/// 
/// Performance optimizations:
/// - Static methods (no instance needed)
/// - Efficient algorithms
/// - Early returns for empty data
class DreamCalculations {
  DreamCalculations._(); // Private constructor

  /// Check if a dream was logged today
  static bool checkTodayDreamLogged(List<Dream> dreams) {
    if (dreams.isEmpty) return false;
    
    final today = DateTime.now();
    return dreams.any((dream) {
      final dreamDate = dream.createdAt;
      return dreamDate.year == today.year &&
          dreamDate.month == today.month &&
          dreamDate.day == today.day;
    });
  }

  /// Calculate current streak
  static int calculateCurrentStreak(List<Dream> dreams) {
    if (dreams.isEmpty) return 0;

    final sortedDreams = dreams.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    final latestDream = sortedDreams.first;
    final latestDate = DateTime(
      latestDream.createdAt.year,
      latestDream.createdAt.month,
      latestDream.createdAt.day,
    );
    
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    // Early return if not part of current streak
    if (latestDate != todayDate && latestDate != yesterdayDate) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = todayDate;
    
    for (var dream in sortedDreams) {
      final dreamDate = DateTime(
        dream.createdAt.year,
        dream.createdAt.month,
        dream.createdAt.day,
      );
      
      if (dreamDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (dreamDate.isBefore(checkDate)) {
        final daysDiff = checkDate.difference(dreamDate).inDays;
        if (daysDiff > 1) break;
        checkDate = dreamDate.subtract(const Duration(days: 1));
      }
    }
    
    return streak;
  }

  /// Calculate longest streak
  static int calculateLongestStreak(List<Dream> dreams) {
    if (dreams.isEmpty) return 0;

    final sortedDreams = dreams.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int maxStreak = 0;
    int currentStreak = 1;
    
    for (int i = 0; i < sortedDreams.length - 1; i++) {
      final current = DateTime(
        sortedDreams[i].createdAt.year,
        sortedDreams[i].createdAt.month,
        sortedDreams[i].createdAt.day,
      );
      final next = DateTime(
        sortedDreams[i + 1].createdAt.year,
        sortedDreams[i + 1].createdAt.month,
        sortedDreams[i + 1].createdAt.day,
      );
      
      final diff = current.difference(next).inDays;
      
      if (diff == 1) {
        currentStreak++;
      } else {
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
        currentStreak = 1;
      }
    }
    
    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  /// Get dreams count for this week
  static int getThisWeekDreamsCount(List<Dream> dreams) {
    if (dreams.isEmpty) return 0;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return dreams.where((dream) {
      return dream.createdAt.isAfter(weekStartDate);
    }).length;
  }

  /// Get dreams count for this month
  static int getThisMonthDreamsCount(List<Dream> dreams) {
    if (dreams.isEmpty) return 0;
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return dreams.where((dream) {
      return dream.createdAt.isAfter(monthStart);
    }).length;
  }

  /// Check if a dream exists on a specific date
  static bool hasDreamOnDate(List<Dream> dreams, DateTime date) {
    return dreams.any((dream) => isSameDay(dream.createdAt, date));
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  /// Get week days for calendar view
  static List<DateTime> getWeekDays() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
  }
}

