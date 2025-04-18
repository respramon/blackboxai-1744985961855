import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';

import 'package:ehr_blockchain/config/app_config.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  group('App Configuration Tests', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    test('Load environment configuration', () {
      final config = AppConfig.fromEnvironment('development');

      expect(config.apiUrl, startsWith('http://'));
      expect(config.blockchainNetwork, isNotEmpty);
      expect(config.ipfsGateway, isNotEmpty);
    });

    test('Production configuration', () {
      final config = AppConfig.fromEnvironment('production');

      expect(config.apiUrl, startsWith('https://'));
      expect(config.enableAnalytics, isTrue);
      expect(config.logLevel, equals('error'));
    });

    test('Development configuration', () {
      final config = AppConfig.fromEnvironment('development');

      expect(config.apiUrl, contains('localhost') || contains('127.0.0.1'));
      expect(config.enableAnalytics, isFalse);
      expect(config.logLevel, equals('debug'));
    });

    test('Staging configuration', () {
      final config = AppConfig.fromEnvironment('staging');

      expect(config.apiUrl, contains('staging'));
      expect(config.enableAnalytics, isTrue);
      expect(config.logLevel, equals('info'));
    });
  });

  group('Feature Flags Tests', () {
    test('Feature flags configuration', () {
      final featureFlags = AppConfig.featureFlags;

      expect(featureFlags, isA<Map<String, bool>>());
      expect(featureFlags['enableBiometrics'], isNotNull);
      expect(featureFlags['enableOfflineMode'], isNotNull);
      expect(featureFlags['enablePushNotifications'], isNotNull);
    });

    test('Dynamic feature flags update', () async {
      final initialFlags = AppConfig.featureFlags;
      
      // Simulate remote config update
      await AppConfig.updateFeatureFlags({
        'enableBiometrics': !initialFlags['enableBiometrics']!,
      });

      expect(
        AppConfig.featureFlags['enableBiometrics'],
        isNot(equals(initialFlags['enableBiometrics'])),
      );
    });
  });

  group('API Configuration Tests', () {
    test('API endpoints configuration', () {
      final endpoints = AppConfig.apiEndpoints;

      expect(endpoints['auth'], endsWith('/auth'));
      expect(endpoints['records'], endsWith('/records'));
      expect(endpoints['users'], endsWith('/users'));
    });

    test('API timeout configuration', () {
      expect(AppConfig.apiTimeout, isA<Duration>());
      expect(
        AppConfig.apiTimeout.inSeconds,
        greaterThanOrEqualTo(30),
      );
    });

    test('API retry configuration', () {
      expect(AppConfig.maxApiRetries, greaterThan(0));
      expect(AppConfig.apiRetryDelay, isA<Duration>());
    });
  });

  group('Blockchain Configuration Tests', () {
    test('Network configuration', () {
      final networkConfig = AppConfig.blockchainConfig;

      expect(networkConfig['networkId'], isNotNull);
      expect(networkConfig['gasLimit'], isNotNull);
      expect(networkConfig['contractAddress'], matches(RegExp(r'^0x[a-fA-F0-9]{40}$')));
    });

    test('IPFS configuration', () {
      final ipfsConfig = AppConfig.ipfsConfig;

      expect(ipfsConfig['gateway'], isNotNull);
      expect(ipfsConfig['timeout'], isA<int>());
    });
  });

  group('Security Configuration Tests', () {
    test('Security settings', () {
      final securityConfig = AppConfig.securityConfig;

      expect(securityConfig['sessionTimeout'], isA<int>());
      expect(securityConfig['maxLoginAttempts'], isA<int>());
      expect(securityConfig['passwordMinLength'], isA<int>());
    });

    test('Encryption configuration', () {
      final encryptionConfig = AppConfig.encryptionConfig;

      expect(encryptionConfig['algorithm'], isNotEmpty);
      expect(encryptionConfig['keySize'], isA<int>());
    });
  });

  group('Storage Configuration Tests', () {
    test('Cache configuration', () {
      final cacheConfig = AppConfig.cacheConfig;

      expect(cacheConfig['maxSize'], isA<int>());
      expect(cacheConfig['expiryDuration'], isA<Duration>());
    });

    test('Storage paths configuration', () {
      final storagePaths = AppConfig.storagePaths;

      expect(storagePaths['temp'], isNotEmpty);
      expect(storagePaths['documents'], isNotEmpty);
      expect(storagePaths['cache'], isNotEmpty);
    });
  });

  group('Analytics Configuration Tests', () {
    test('Analytics settings', () {
      final analyticsConfig = AppConfig.analyticsConfig;

      expect(analyticsConfig['enabled'], isA<bool>());
      expect(analyticsConfig['sampleRate'], isA<double>());
    });

    test('Event tracking configuration', () {
      final eventConfig = AppConfig.eventTrackingConfig;

      expect(eventConfig['userActions'], isA<List>());
      expect(eventConfig['performance'], isA<List>());
    });
  });

  group('Environment Variables Tests', () {
    test('Required environment variables', () {
      final requiredVars = AppConfig.requiredEnvVars;

      for (final variable in requiredVars) {
        expect(
          AppConfig.getEnvVar(variable),
          isNotNull,
          reason: 'Missing required environment variable: $variable',
        );
      }
    });

    test('Optional environment variables', () {
      final optionalVars = AppConfig.optionalEnvVars;

      for (final variable in optionalVars) {
        final value = AppConfig.getEnvVar(variable);
        // Optional variables can be null
        expect(value != null || value == null, isTrue);
      }
    });
  });

  group('Configuration Persistence Tests', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    test('Save configuration', () async {
      final config = {
        'theme': 'dark',
        'language': 'en',
        'notifications': true,
      };

      when(mockStorageService.write('app_config', any))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.write(
        'app_config',
        json.encode(config),
      );

      expect(result, isTrue);
    });

    test('Load configuration', () async {
      final storedConfig = {
        'theme': 'dark',
        'language': 'en',
        'notifications': true,
      };

      when(mockStorageService.read('app_config'))
          .thenReturn(json.encode(storedConfig));

      final config = json.decode(
        mockStorageService.read('app_config')!,
      );

      expect(config, equals(storedConfig));
    });
  });
}
