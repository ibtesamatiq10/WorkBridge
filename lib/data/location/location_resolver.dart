class LocationResolver {
  LocationResolver._();

  static const _cities = <String, String>{
    'new york city': 'New York',
    'new york': 'New York',
    'los angeles': 'Los Angeles',
    'san francisco': 'San Francisco',
    'abu dhabi': 'Abu Dhabi',
    'hong kong': 'Hong Kong',
    'kuwait city': 'Kuwait City',
    'mexico city': 'Mexico City',
    'rio de janeiro': 'Rio de Janeiro',
    'sao paulo': 'São Paulo',
    'islamabad': 'Islamabad',
    'rawalpindi': 'Rawalpindi',
    'lahore': 'Lahore',
    'karachi': 'Karachi',
    'peshawar': 'Peshawar',
    'quetta': 'Quetta',
    'multan': 'Multan',
    'faisalabad': 'Faisalabad',
    'sialkot': 'Sialkot',
    'dubai': 'Dubai',
    'sharjah': 'Sharjah',
    'london': 'London',
    'manchester': 'Manchester',
    'birmingham': 'Birmingham',
    'paris': 'Paris',
    'berlin': 'Berlin',
    'madrid': 'Madrid',
    'rome': 'Rome',
    'amsterdam': 'Amsterdam',
    'istanbul': 'Istanbul',
    'ankara': 'Ankara',
    'riyadh': 'Riyadh',
    'jeddah': 'Jeddah',
    'doha': 'Doha',
    'muscat': 'Muscat',
    'cairo': 'Cairo',
    'mumbai': 'Mumbai',
    'delhi': 'Delhi',
    'bangalore': 'Bangalore',
    'hyderabad': 'Hyderabad',
    'chennai': 'Chennai',
    'kolkata': 'Kolkata',
    'dhaka': 'Dhaka',
    'singapore': 'Singapore',
    'bangkok': 'Bangkok',
    'jakarta': 'Jakarta',
    'kuala lumpur': 'Kuala Lumpur',
    'tokyo': 'Tokyo',
    'seoul': 'Seoul',
    'beijing': 'Beijing',
    'shanghai': 'Shanghai',
    'sydney': 'Sydney',
    'melbourne': 'Melbourne',
    'toronto': 'Toronto',
    'vancouver': 'Vancouver',
    'montreal': 'Montreal',
    'chicago': 'Chicago',
    'houston': 'Houston',
    'miami': 'Miami',
    'boston': 'Boston',
    'seattle': 'Seattle',
    'atlanta': 'Atlanta',
  };

  static const _countries = <String, String>{
    'united arab emirates': 'United Arab Emirates',
    'saudi arabia': 'Saudi Arabia',
    'united kingdom': 'United Kingdom',
    'united states': 'United States',
    'south africa': 'South Africa',
    'new zealand': 'New Zealand',
    'sri lanka': 'Sri Lanka',
    'pakistan': 'Pakistan',
    'india': 'India',
    'bangladesh': 'Bangladesh',
    'afghanistan': 'Afghanistan',
    'china': 'China',
    'japan': 'Japan',
    'korea': 'South Korea',
    'australia': 'Australia',
    'canada': 'Canada',
    'germany': 'Germany',
    'france': 'France',
    'italy': 'Italy',
    'spain': 'Spain',
    'netherlands': 'Netherlands',
    'turkey': 'Turkey',
    'egypt': 'Egypt',
    'qatar': 'Qatar',
    'oman': 'Oman',
    'kuwait': 'Kuwait',
    'bahrain': 'Bahrain',
    'malaysia': 'Malaysia',
    'thailand': 'Thailand',
    'indonesia': 'Indonesia',
    'singapore': 'Singapore',
    'uae': 'United Arab Emirates',
    'usa': 'United States',
    'us': 'United States',
    'uk': 'United Kingdom',
    'u.k.': 'United Kingdom',
    'u.s.': 'United States',
    'u.s.a.': 'United States',
  };

  static String? detectCity(String lower) {
    final sortedKeys = _cities.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (key.trim().isEmpty) continue;
      if (lower.contains(key)) {
        return _cities[key];
      }
    }
    return null;
  }

  static String? detectCountry(String lower) {
    final sortedKeys = _countries.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        return _countries[key];
      }
    }
    return null;
  }

  static bool containsPlaceHint(String text) {
    final lower = text.toLowerCase();
    if (detectCity(lower) != null || detectCountry(lower) != null) {
      return true;
    }
    return RegExp(
      r'\b(in|near|at|mein|ko)\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static String compose({String? area, String? city, String? country}) {
    final parts = <String>[];

    void addPart(String? part) {
      if (part == null || part.trim().isEmpty) return;
      final normalized = part.trim();
      final lowerParts = parts.map((p) => p.toLowerCase()).toList();
      if (lowerParts.any((p) => p.contains(normalized.toLowerCase()))) {
        return;
      }
      if (lowerParts.any((p) => normalized.toLowerCase().contains(p))) {
        return;
      }
      parts.add(normalized);
    }

    addPart(area);
    addPart(city);
    addPart(country);
    return parts.join(', ');
  }

  static String enrich(String phrase, String lowerSource) {
    final trimmed = phrase.trim();
    if (trimmed.isEmpty) return 'Unknown';

    final lower = trimmed.toLowerCase();
    final city = detectCity(lower) ?? detectCity(lowerSource);
    final country = detectCountry(lower) ?? detectCountry(lowerSource);

    if (city != null || country != null) {
      final hasCity = city != null && lower.contains(city.toLowerCase());
      final hasCountry =
          country != null && lower.contains(country.toLowerCase());
      return compose(
        area: trimmed,
        city: hasCity ? null : city,
        country: hasCountry ? null : country,
      );
    }

    return trimmed;
  }
}
