import 'package:WorkBridge/data/location/location_resolver.dart';
import 'package:WorkBridge/domain/entities/service_request.dart';
import 'package:intl/intl.dart';

class LocalIntentParser {
  static ServiceRequest parse(String userInput) {
    final lower = userInput.toLowerCase();

    final serviceType = _extractServiceType(lower);
    final location = _extractLocation(lower, userInput);
    final time = _extractTime(lower);

    return ServiceRequest(
      serviceType: serviceType,
      location: location,
      time: time,
    );
  }

  static String _extractServiceType(String lower) {
    const patterns = <String, List<String>>{
      'Restaurant': ['restaurant', 'khana', 'food', 'dining', 'cafe', 'eat'],
      'AC Technician': [
        'ac technician',
        'ac repair',
        'ac wala',
        'air condition',
      ],
      'Plumber': ['plumber', 'plumbing', 'pipe', 'leak'],
      'Electrician': ['electrician', 'electric', 'wiring'],
      'Tutor': ['tutor', 'teacher', 'tuition'],
      'Doctor': ['doctor', 'clinic', 'hospital'],
      'Salon': ['salon', 'haircut', 'barber'],
    };

    for (final entry in patterns.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }

    if (lower.contains('chahiye') || lower.contains('need')) {
      return 'Service';
    }
    return 'Service';
  }

  static String _extractLocation(String lower, String original) {
    final city = LocationResolver.detectCity(lower);
    final country = LocationResolver.detectCountry(lower);

    final koMein = RegExp(
      r'ko\s+(.+?)\s+mein\b',
      caseSensitive: false,
    ).firstMatch(original);
    if (koMein != null) {
      return LocationResolver.enrich(
        _titleCase(koMein.group(1)!.trim()),
        lower,
      );
    }

    final area = _detectNamedArea(lower);
    if (area != null) {
      return LocationResolver.compose(area: area, city: city, country: country);
    }

    final inMatch = RegExp(
      r'\bin\s+([a-z0-9\s,.-]+?)(?:\s+mein|\s+for|\s+at|\s+chahiye|$)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (inMatch != null) {
      return LocationResolver.enrich(
        _titleCase(inMatch.group(1)!.trim()),
        lower,
      );
    }

    final nearMatch = RegExp(
      r'\bnear\s+([a-z0-9\s,.-]+?)(?:\s+for|\s+at|\s+chahiye|$)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (nearMatch != null) {
      return LocationResolver.enrich(
        _titleCase(nearMatch.group(1)!.trim()),
        lower,
      );
    }

    if (city != null || country != null) {
      final composed = LocationResolver.compose(city: city, country: country);
      if (composed.isNotEmpty) return composed;
    }

    return 'Unknown';
  }

  static String? _detectNamedArea(String lower) {
    const areas = <String, String>{
      'blue area': 'Blue Area',
      'mm alam': 'MM Alam Road',
      'liberty market': 'Liberty Market',
      'model town': 'Model Town',
      'johar town': 'Johar Town',
      'bahria town': 'Bahria Town',
      'food street': 'Food Street',
      'gulberg': 'Gulberg',
      'dha': 'DHA',
      'saddar': 'Saddar',
      'cantt': 'Cantt',
      'faisal town': 'Faisal Town',
      'wapda town': 'Wapda Town',
      'township': 'Township',
      'times square': 'Times Square',
      'manhattan': 'Manhattan',
      'brooklyn': 'Brooklyn',
      'marina': 'Dubai Marina',
      'jumeirah': 'Jumeirah',
      'deira': 'Deira',
    };

    for (final entry in areas.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    final gSector = RegExp(
      r'\bg-?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (gSector != null) {
      return 'G-${gSector.group(1)}';
    }

    final fSector = RegExp(
      r'\bf-?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (fSector != null) {
      return 'F-${fSector.group(1)}';
    }

    final iSector = RegExp(
      r'\bi-?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (iSector != null) {
      return 'I-${iSector.group(1)}';
    }

    final eSector = RegExp(
      r'\be-?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (eSector != null) {
      return 'E-${eSector.group(1)}';
    }

    final hSector = RegExp(
      r'\bh-?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (hSector != null) {
      return 'H-${hSector.group(1)}';
    }

    return null;
  }

  static String _extractTime(String lower) {
    String? day;
    if (lower.contains('parso') || lower.contains('parson')) {
      day = 'Day after tomorrow';
    } else if (lower.contains('kal') ||
        lower.contains('kl') ||
        lower.contains('tomorrow')) {
      day = 'Tomorrow';
    } else if (lower.contains('aaj') || lower.contains('today')) {
      day = 'Today';
    }

    String? timeOfDay;
    bool isPm = false;
    bool isAm = false;

    if (lower.contains('subah') ||
        lower.contains('subha') ||
        lower.contains('subh') ||
        lower.contains('suba') ||
        lower.contains('morning')) {
      timeOfDay = 'morning';
      isAm = true;
    } else if (lower.contains('dopahar') ||
        lower.contains('dopaher') ||
        lower.contains('afternoon')) {
      timeOfDay = 'afternoon';
      isPm = true;
    } else if (lower.contains('shaam') ||
        lower.contains('sham') ||
        lower.contains('evening')) {
      timeOfDay = 'evening';
      isPm = true;
    } else if (lower.contains('raat') || lower.contains('night')) {
      timeOfDay = 'night';
      isPm = true;
    }

    String? exactTime;
    int? hour;
    int? minute;
    String? marker;

    final hourWithMarker = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|bjy|baje|bja|o\s*clock)\b',
      caseSensitive: false,
    ).firstMatch(lower);

    final hourWithColon = RegExp(
      r'\b(\d{1,2}):(\d{2})\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (hourWithMarker != null) {
      hour = int.tryParse(hourWithMarker.group(1)!);
      minute = int.tryParse(hourWithMarker.group(2) ?? '00');
      marker = hourWithMarker.group(3)?.toLowerCase();
    } else if (hourWithColon != null) {
      hour = int.tryParse(hourWithColon.group(1)!);
      minute = int.tryParse(hourWithColon.group(2)!);
    }

    if (hour != null && hour >= 1 && hour <= 24) {
      final minuteStr = (minute ?? 0).toString().padLeft(2, '0');

      if (marker == 'pm') {
        isPm = true;
        isAm = false;
      } else if (marker == 'am') {
        isAm = true;
        isPm = false;
      }

      if (hour > 12) {
        isPm = true;
        hour -= 12;
      } else if (hour == 12) {
        isPm = true;
      } else if (hour == 0) {
        isAm = true;
        hour = 12;
      } else {
        if (marker != null &&
            (marker.contains('bjy') ||
                marker.contains('baje') ||
                marker.contains('bja'))) {
          if (isPm) {
          } else if (isAm) {
          } else {
            if (hour >= 1 && hour <= 7) {
              isPm = true;
            } else {
              isAm = true;
            }
          }
        }
      }

      final amPmStr = isPm ? 'PM' : 'AM';
      final displayHour = hour.toString().padLeft(2, '0');
      exactTime = '$displayHour:$minuteStr $amPmStr';
    } else {
      final plainNumberRegex = RegExp(
        r'\b(?:subah|subha|subh|suba|shaam|sham|raat|kl|kal|aaj|at|on)\s+(\d{1,2})\b'
        r'|\b(\d{1,2})\s+(?:subah|subha|subh|suba|shaam|sham|raat|kl|kal|aaj)\b',
        caseSensitive: false,
      );
      final plainMatch = plainNumberRegex.firstMatch(lower);
      if (plainMatch != null) {
        final hourStr = plainMatch.group(1) ?? plainMatch.group(2)!;
        final plainHour = int.parse(hourStr);
        if (plainHour >= 1 && plainHour <= 12) {
          if (isPm) {
            exactTime = '${hourStr.padLeft(2, '0')}:00 PM';
          } else {
            exactTime = '${hourStr.padLeft(2, '0')}:00 AM';
          }
        }
      }
    }

    if (day != null && exactTime != null) {
      return '$day at $exactTime';
    } else if (day != null && timeOfDay != null) {
      return '$day $timeOfDay';
    } else if (day != null) {
      return day;
    } else if (exactTime != null) {
      return exactTime;
    } else if (timeOfDay != null) {
      return timeOfDay[0].toUpperCase() + timeOfDay.substring(1);
    }

    final now = DateTime.now();
    final formattedTime = DateFormat('h:mm a').format(now);
    return 'ASAP ($formattedTime)';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          if (word.length <= 2 && word.contains('-')) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
