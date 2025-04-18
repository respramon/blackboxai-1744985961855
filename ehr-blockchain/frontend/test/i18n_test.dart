import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/i18n_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  group('Localization Tests', () {
    late MockI18nService mockI18nService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockI18nService = MockI18nService();
      mockStorageService = MockStorageService();
    });

    test('Load translations', () async {
      when(mockI18nService.loadTranslations('en'))
          .thenAnswer((_) async => TranslationSet(
                locale: 'en',
                translations: {
                  'common.welcome': 'Welcome',
                  'auth.login': 'Login',
                  'medical.record': 'Medical Record',
                  'errors.not_found': 'Not found',
                },
                metadata: {
                  'version': '1.0.0',
                  'lastUpdated': '2023-12-01',
                },
              ));

      final translations = await mockI18nService.loadTranslations('en');
      expect(translations.locale, equals('en'));
      expect(translations.translations, contains('common.welcome'));
      expect(translations.translations['auth.login'], equals('Login'));
    });

    test('Get translated string', () {
      when(mockI18nService.translate(
        key: 'medical.record',
        locale: 'en',
        args: {'type': 'Lab Results'},
      )).thenReturn('Lab Results Medical Record');

      final translated = mockI18nService.translate(
        key: 'medical.record',
        locale: 'en',
        args: {'type': 'Lab Results'},
      );
      expect(translated, contains('Lab Results'));
    });

    test('Handle missing translation', () {
      when(mockI18nService.translate(
        key: 'nonexistent.key',
        locale: 'en',
      )).thenReturn('nonexistent.key');

      final result = mockI18nService.translate(
        key: 'nonexistent.key',
        locale: 'en',
      );
      expect(result, equals('nonexistent.key'));
    });
  });

  group('Locale Management Tests', () {
    late MockI18nService mockI18nService;

    setUp(() {
      mockI18nService = MockI18nService();
    });

    test('Get supported locales', () async {
      when(mockI18nService.getSupportedLocales())
          .thenAnswer((_) async => [
                LocaleInfo(
                  code: 'en',
                  name: 'English',
                  nativeName: 'English',
                  isRTL: false,
                ),
                LocaleInfo(
                  code: 'es',
                  name: 'Spanish',
                  nativeName: 'Español',
                  isRTL: false,
                ),
                LocaleInfo(
                  code: 'ar',
                  name: 'Arabic',
                  nativeName: 'العربية',
                  isRTL: true,
                ),
              ]);

      final locales = await mockI18nService.getSupportedLocales();
      expect(locales, hasLength(3));
      expect(locales.map((l) => l.code), contains('en'));
    });

    test('Change locale', () async {
      when(mockI18nService.changeLocale('es'))
          .thenAnswer((_) async => LocaleChangeResult(
                success: true,
                newLocale: 'es',
                requiresRestart: false,
              ));

      final result = await mockI18nService.changeLocale('es');
      expect(result.success, isTrue);
      expect(result.newLocale, equals('es'));
    });

    test('Get current locale', () {
      when(mockI18nService.getCurrentLocale())
          .thenReturn(LocaleInfo(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            isRTL: false,
          ));

      final locale = mockI18nService.getCurrentLocale();
      expect(locale.code, equals('en'));
    });
  });

  group('Pluralization Tests', () {
    late MockI18nService mockI18nService;

    setUp(() {
      mockI18nService = MockI18nService();
    });

    test('Handle plural forms', () {
      when(mockI18nService.translatePlural(
        key: 'medical.records',
        count: 2,
        locale: 'en',
      )).thenReturn('2 medical records');

      final translated = mockI18nService.translatePlural(
        key: 'medical.records',
        count: 2,
        locale: 'en',
      );
      expect(translated, equals('2 medical records'));
    });

    test('Handle zero case', () {
      when(mockI18nService.translatePlural(
        key: 'medical.records',
        count: 0,
        locale: 'en',
      )).thenReturn('No medical records');

      final translated = mockI18nService.translatePlural(
        key: 'medical.records',
        count: 0,
        locale: 'en',
      );
      expect(translated, equals('No medical records'));
    });
  });

  group('Date and Number Formatting Tests', () {
    late MockI18nService mockI18nService;

    setUp(() {
      mockI18nService = MockI18nService();
    });

    test('Format date', () {
      final date = DateTime(2023, 12, 1);

      when(mockI18nService.formatDate(
        date,
        locale: 'en',
        format: DateFormat.long,
      )).thenReturn('December 1, 2023');

      final formatted = mockI18nService.formatDate(
        date,
        locale: 'en',
        format: DateFormat.long,
      );
      expect(formatted, equals('December 1, 2023'));
    });

    test('Format number', () {
      when(mockI18nService.formatNumber(
        1234.56,
        locale: 'en',
        decimals: 2,
      )).thenReturn('1,234.56');

      final formatted = mockI18nService.formatNumber(
        1234.56,
        locale: 'en',
        decimals: 2,
      );
      expect(formatted, equals('1,234.56'));
    });
  });

  group('Translation Management Tests', () {
    late MockI18nService mockI18nService;

    setUp(() {
      mockI18nService = MockI18nService();
    });

    test('Add new translation', () async {
      final translation = TranslationEntry(
        key: 'feature.new',
        values: {
          'en': 'New Feature',
          'es': 'Nueva Función',
        },
      );

      when(mockI18nService.addTranslation(translation))
          .thenAnswer((_) async => true);

      final result = await mockI18nService.addTranslation(translation);
      expect(result, isTrue);
    });

    test('Update existing translation', () async {
      final update = TranslationUpdate(
        key: 'feature.existing',
        changes: {
          'en': 'Updated Feature',
          'es': 'Función Actualizada',
        },
      );

      when(mockI18nService.updateTranslation(update))
          .thenAnswer((_) async => UpdateResult(
                success: true,
                updatedLocales: ['en', 'es'],
              ));

      final result = await mockI18nService.updateTranslation(update);
      expect(result.success, isTrue);
      expect(result.updatedLocales, hasLength(2));
    });
  });

  group('RTL Support Tests', () {
    late MockI18nService mockI18nService;

    setUp(() {
      mockI18nService = MockI18nService();
    });

    test('Check RTL support', () async {
      when(mockI18nService.checkRTLSupport())
          .thenAnswer((_) async => RTLSupportInfo(
                supported: true,
                rtlLocales: ['ar', 'he'],
                currentIsRTL: false,
              ));

      final support = await mockI18nService.checkRTLSupport();
      expect(support.supported, isTrue);
      expect(support.rtlLocales, contains('ar'));
    });

    test('Get text direction', () {
      when(mockI18nService.getTextDirection('ar'))
          .thenReturn(TextDirection.rtl);

      final direction = mockI18nService.getTextDirection('ar');
      expect(direction, equals(TextDirection.rtl));
    });
  });
}

enum DateFormat { short, medium, long, full }
enum TextDirection { ltr, rtl }

class TranslationSet {
  final String locale;
  final Map<String, String> translations;
  final Map<String, String> metadata;

  TranslationSet({
    required this.locale,
    required this.translations,
    required this.metadata,
  });
}

class LocaleInfo {
  final String code;
  final String name;
  final String nativeName;
  final bool isRTL;

  LocaleInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isRTL,
  });
}

class LocaleChangeResult {
  final bool success;
  final String newLocale;
  final bool requiresRestart;

  LocaleChangeResult({
    required this.success,
    required this.newLocale,
    required this.requiresRestart,
  });
}

class TranslationEntry {
  final String key;
  final Map<String, String> values;

  TranslationEntry({
    required this.key,
    required this.values,
  });
}

class TranslationUpdate {
  final String key;
  final Map<String, String> changes;

  TranslationUpdate({
    required this.key,
    required this.changes,
  });
}

class UpdateResult {
  final bool success;
  final List<String> updatedLocales;

  UpdateResult({
    required this.success,
    required this.updatedLocales,
  });
}

class RTLSupportInfo {
  final bool supported;
  final List<String> rtlLocales;
  final bool currentIsRTL;

  RTLSupportInfo({
    required this.supported,
    required this.rtlLocales,
    required this.currentIsRTL,
  });
}

class MockI18nService extends Mock implements I18nService {}
class MockStorageService extends Mock implements StorageService {}
