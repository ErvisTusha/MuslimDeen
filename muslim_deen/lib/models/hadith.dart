/// Hadith data model for Islamic prophetic traditions
/// 
/// This model represents a single hadith (prophetic tradition) with
/// its text, narrator, source, and authenticity grade. Hadiths are
/// fundamental sources of Islamic guidance and law, second only to
/// the Quran in authority.

/// Model representing a single Islamic hadith (prophetic tradition)
/// 
/// This data structure encapsulates all essential information about a
/// hadith, including the actual text, chain of narration, source
/// collection, and authenticity grading. It provides a complete
/// representation for display, study, and reference purposes.
/// 
/// Design principles:
/// - Immutable data structure for authenticity preservation
/// - Comprehensive metadata for scholarly reference
/// - Support for multiple languages and translations
/// - Efficient serialization for storage and caching
/// 
/// Key responsibilities:
/// - Store hadith text and narrator information
/// - Maintain source and authenticity data
/// - Support serialization for persistent storage
/// - Provide display-ready data for UI components
/// 
/// Usage patterns:
/// - Loaded from hadith databases or APIs
/// - Displayed in daily hadith features
/// - Used in study and reference applications
/// - Cached for offline access and performance
class Hadith {
  /// The actual text content of the hadith
  /// The prophetic saying or action being reported
  /// Typically in Arabic with translations available
  final String text;
  
  /// The narrator or chain of narrators (isnad)
  /// Reports who transmitted the hadith from the Prophet
  /// Important for authenticity verification
  final String narrator;
  
  /// The source collection where this hadith is found
  /// Examples: Sahih Bukhari, Sahih Muslim, Sunan Abu Dawood
  /// Indicates the primary reference for the hadith
  final String source;
  
  /// The authenticity grade or classification
  /// Indicates the reliability and strength of the hadith
  /// Examples: Sahih (authentic), Hasan (good), Da'if (weak)
  final String grade;

  /// Creates a new Hadith with complete information
  /// 
  /// Parameters:
  /// - [text]: The hadith text content (required)
  /// - [narrator]: Chain of narrators (required)
  /// - [source]: Source collection (required)
  /// - [grade]: Authenticity grade (required)
  /// 
  /// Example:
  /// ```dart
  /// final hadith = Hadith(
  ///   text: 'Actions are judged by intentions...',
  ///   narrator: 'Narrated by Umar ibn al-Khattab',
  ///   source: 'Sahih Bukhari',
  ///   grade: 'Sahih',
  /// );
  /// ```
  /// 
  /// Notes:
  /// - All fields are required for complete hadith information
  /// - Text should include translation if using non-Arabic language
  /// - Narrator should include complete chain when available
  /// - Source should include collection number when applicable
  const Hadith({
    required this.text,
    required this.narrator,
    required this.source,
    required this.grade,
  });

  /// Creates a Hadith from JSON data
  /// 
  /// Factory method for deserializing stored hadith data from
  /// databases or network sources. Handles type checking and
  /// appropriate error handling for missing fields.
  /// 
  /// Parameters:
  /// - [json]: Map containing serialized hadith data
  /// 
  /// Returns: New Hadith with restored data
  /// 
  /// Error handling:
  /// - Assumes valid JSON structure (should be validated before use)
  /// - May throw type errors if JSON structure is invalid
  /// - Null values in required fields will cause null reference errors
  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      text: json['text'] as String,
      narrator: json['narrator'] as String,
      source: json['source'] as String,
      grade: json['grade'] as String,
    );
  }

  /// Serializes this Hadith to JSON for storage
  /// 
  /// Converts the hadith to a format suitable for persistent
  /// storage in databases, SharedPreferences, or network transmission.
  /// 
  /// Serialization details:
  /// - All string fields are stored directly
  /// - No special handling for null values (all fields required)
  /// - Maintains data integrity for round-trip serialization
  /// 
  /// Returns: Map<String, dynamic> containing all hadith data
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'narrator': narrator,
      'source': source,
      'grade': grade,
    };
  }

  // ==================== UTILITY METHODS ====================
  
  /// Gets the first line of the hadith text
  /// 
  /// Useful for preview displays where only a brief excerpt
  /// is needed, such as in lists or notifications.
  /// 
  /// Returns: First line of hadith text, or full text if no line breaks
  String get firstLine {
    final lines = text.split('\n');
    return lines.isNotEmpty ? lines.first : text;
  }
  
  /// Gets a shortened version of the hadith text
  /// 
  /// Creates a brief excerpt of the hadith for preview purposes,
  /// truncating at word boundaries to maintain readability.
  /// 
  /// Parameters:
  /// - [maxLength]: Maximum length of the excerpt (defaults to 100)
  /// - [suffix]: Text to append if truncated (defaults to '...')
  /// 
  /// Returns: Shortened version of the hadith text
  String getShortText({int maxLength = 100, String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    
    final truncated = text.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    
    if (lastSpace > 0) {
      return truncated.substring(0, lastSpace) + suffix;
    } else {
      return truncated + suffix;
    }
  }
  
  /// Checks if the hadith is considered authentic
  /// 
  /// Determines if the hadith meets the criteria for authenticity
  /// based on Islamic scholarly classification.
  /// 
  /// Returns: true if the hadith is authentic (Sahih/Hasan), false otherwise
  bool get isAuthentic {
    final authenticGrades = ['sahih', 'hasan', 'authentic'];
    return authenticGrades.contains(grade.toLowerCase());
  }
  
  /// Gets the authenticity category
  /// 
  /// Categorizes the hadith into broader authenticity groups
  /// for simplified display and filtering.
  /// 
  /// Returns: Category string ('Authentic', 'Good', 'Weak', 'Unknown')
  String get authenticityCategory {
    switch (grade.toLowerCase()) {
      case 'sahih':
      case 'authentic':
        return 'Authentic';
      case 'hasan':
      case 'good':
        return 'Good';
      case 'da\'if':
      case 'weak':
        return 'Weak';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'Hadith(source: $source, grade: $grade, narrator: $narrator)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hadith &&
        other.text == text &&
        other.narrator == narrator &&
        other.source == source &&
        other.grade == grade;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        narrator.hashCode ^
        source.hashCode ^
        grade.hashCode;
  }
}

// ==================== HADITH COLLECTION CONSTANTS ====================

/// Common hadith collection references
/// 
/// These constants represent the major authentic hadith collections
/// in Islamic literature. They can be used for validation,
/// categorization, and UI display purposes.
class HadithCollections {
  /// Sahih al-Bukhari - Most authentic collection after Quran
  static const String sahihBukhari = 'Sahih Bukhari';
  
  /// Sahih Muslim - Second most authentic collection
  static const String sahihMuslim = 'Sahih Muslim';
  
  /// Sunan Abu Dawood - Collection of hadith with legal focus
  static const String sunanAbuDawood = 'Sunan Abu Dawood';
  
  /// Sunan at-Tirmidhi - Collection with juristic notes
  static const String sunanTirmidhi = 'Sunan at-Tirmidhi';
  
  /// Sunan an-Nasa'i - Collection organized by legal topics
  static const String sunanNasai = 'Sunan an-Nasa\'i';
  
  /// Sunan Ibn Majah - Collection of hadith with various topics
  static const String sunanIbnMajah = 'Sunan Ibn Majah';
  
  /// Muwatta Imam Malik - Early collection with Maliki jurisprudence
  static const String muwattaMalik = 'Muwatta Imam Malik';
  
  /// List of all major authentic collections
  static const List<String> majorCollections = [
    sahihBukhari,
    sahihMuslim,
    sunanAbuDawood,
    sunanTirmidhi,
    sunanNasai,
    sunanIbnMajah,
    muwattaMalik,
  ];
}

// ==================== HADITH AUTHENTICITY GRADES ====================

/// Hadith authenticity grading system
/// 
/// These constants represent the standard authenticity grades used
/// by Islamic scholars to classify hadith reliability.
class HadithGrades {
  /// Sahih - Authentic, reliable hadith with sound chain
  static const String sahih = 'Sahih';
  
  /// Hasan - Good hadith, slightly less authentic than Sahih
  static const String hasan = 'Hasan';
  
  /// Da'if - Weak hadith with deficiencies in chain
  static const String daif = 'Da\'if';
  
  /// Maudu' - Fabricated or forged hadith
  static const String maudu = 'Maudu\'';
  
  /// List of all authenticity grades in order of reliability
  static const List<String> reliabilityOrder = [
    sahih,
    hasan,
    daif,
    maudu,
  ];
}

// ==================== HADITH CATEGORIES ====================

/// Common hadith categories for organization
/// 
/// These categories represent common themes and topics found
/// in hadith collections. They can be used for filtering,
/// searching, and organized display of hadith content.
class HadithCategories {
  /// Faith and belief (Iman)
  static const String faith = 'Faith';
  
  /// Prayer and worship (Salah)
  static const String prayer = 'Prayer';
  
  /// Fasting (Sawm)
  static const String fasting = 'Fasting';
  
  /// Charity (Zakat and Sadaqa)
  static const String charity = 'Charity';
  
  /// Pilgrimage (Hajj)
  static const String pilgrimage = 'Pilgrimage';
  
  /// Character and manners (Akhlaq)
  static const String character = 'Character';
  
  /// Knowledge and learning
  static const String knowledge = 'Knowledge';
  
  /// Family and marriage
  static const String family = 'Family';
  
  /// Business and transactions
  static const String business = 'Business';
  
  /// Food and drink
  static const String food = 'Food';
  
  /// List of all common categories
  static const List<String> allCategories = [
    faith,
    prayer,
    fasting,
    charity,
    pilgrimage,
    character,
    knowledge,
    family,
    business,
    food,
  ];
}