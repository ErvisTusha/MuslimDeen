import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_deen/models/hadith.dart';

void main() {
  group('Hadith Model', () {
    const testHadith = Hadith(
      text: 'Test hadith text',
      narrator: 'Test narrator',
      source: 'Test source',
      grade: 'Sahih',
    );

    test('Hadith constructor creates instance correctly', () {
      expect(testHadith.text, 'Test hadith text');
      expect(testHadith.narrator, 'Test narrator');
      expect(testHadith.source, 'Test source');
      expect(testHadith.grade, 'Sahih');
    });

    test('Hadith.fromJson creates instance from JSON', () {
      final json = {
        'text': 'JSON hadith text',
        'narrator': 'JSON narrator',
        'source': 'JSON source',
        'grade': 'Hasan',
      };

      final hadith = Hadith.fromJson(json);

      expect(hadith.text, 'JSON hadith text');
      expect(hadith.narrator, 'JSON narrator');
      expect(hadith.source, 'JSON source');
      expect(hadith.grade, 'Hasan');
    });

    test('Hadith.toJson returns correct JSON', () {
      final json = testHadith.toJson();

      expect(json['text'], 'Test hadith text');
      expect(json['narrator'], 'Test narrator');
      expect(json['source'], 'Test source');
      expect(json['grade'], 'Sahih');
    });

    test('Hadith is immutable', () {
      // Since all fields are final, the object is immutable
      expect(testHadith.text, 'Test hadith text');
    });
  });
}
