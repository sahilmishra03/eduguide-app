enum ProfessorStatus { inCabin, busy, absent, outsideCollegeHours }

class ProfessorStatusResult {
  final ProfessorStatus status;
  final Duration? nextAvailableIn;
  ProfessorStatusResult(this.status, this.nextAvailableIn);
}

class ProfessorStatusHelper {
  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static ProfessorStatusResult calculate(Map<String, dynamic> availability) {
    final now = DateTime.now();
    final today = days[now.weekday - 1];

    // Check if current time is within college hours (9AM - 5PM)
    final collegeStart = DateTime(now.year, now.month, now.day, 9, 0);
    final collegeEnd = DateTime(now.year, now.month, now.day, 17, 0);

    if (now.isBefore(collegeStart) || now.isAfter(collegeEnd)) {
      return ProfessorStatusResult(ProfessorStatus.outsideCollegeHours, null);
    }

    // Check if today is in weekly availability
    if (!availability.containsKey(today)) {
      return ProfessorStatusResult(ProfessorStatus.absent, null);
    }

    final slot = availability[today];
    if (slot == null || !slot.contains('-')) {
      return ProfessorStatusResult(ProfessorStatus.absent, null);
    }

    final parts = slot.split('-');
    final start = _parse(parts[0], now);
    final end = _parse(parts[1], now);

    if (now.isAfter(start) && now.isBefore(end)) {
      return ProfessorStatusResult(ProfessorStatus.inCabin, null);
    }

    if (now.isBefore(start)) {
      return ProfessorStatusResult(ProfessorStatus.busy, start.difference(now));
    }

    return ProfessorStatusResult(ProfessorStatus.busy, null);
  }

  static DateTime _parse(String t, DateTime base) {
    final isPM = t.toUpperCase().contains('PM');
    final clean = t.replaceAll(RegExp(r'AM|PM'), '').trim();
    final p = clean.split(':');
    int h = int.parse(p[0]);
    int m = p.length > 1 ? int.parse(p[1]) : 0;

    if (isPM && h != 12) h += 12;
    if (!isPM && h == 12) h = 0;

    return DateTime(base.year, base.month, base.day, h, m);
  }
}
