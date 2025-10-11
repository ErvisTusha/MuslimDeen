class Hadith {
  final String text;
  final String narrator;
  final String source;
  final String grade;

  const Hadith({
    required this.text,
    required this.narrator,
    required this.source,
    required this.grade,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      text: json['text'] as String,
      narrator: json['narrator'] as String,
      source: json['source'] as String,
      grade: json['grade'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'narrator': narrator,
      'source': source,
      'grade': grade,
    };
  }
}
