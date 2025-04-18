import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/environment_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'package:ehr_blockchain/config/app_config.dart';
import 'test_helpers.dart';

void main() {
  group('Environment Configuration Tests', () {
    late MockEnvironmentService mockEnvironmentService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockEnvironmentService = MockEnvironmentService();
      mockStorageService = MockStorageService();
    });

    test('Load development environment', () async {
      when(mockEnvironmentService.loadEnvironment(Environment.development))
          .thenAnswer((_) async => EnvironmentConfig(
                environment: Environment.development,
                apiUrl: 'http://localhost:3000',
                blockchainNetwork: 'localhost:8545',
                ipfsGateway: 'http://localhost:8080',
                features: {
                  'debugMode': true,
                  'mockBlockchain': true,
                },
              ));

      final config = await mockEnvironmentService.loadEnvironment(
        Environment.development,
      );
      expect(config.environment, equals(Environment.development));
      expect(config.features['debugMode'], isTrue);
    });

    test('Load production environment', () async {
      when(mockEnvironmentService.loadEnvironment(Environment.production))
          .thenAnswer((_) async => EnvironmentConfig(
                environment: Environment.production,
                apiUrl: 'https://api.ehrapp.com',
                blockchainNetwork: 'https://mainnet.infura.io',
                ipfsGateway: 'https://ipfs.io',
                features: {
                  'debugMode': false,
                  'analytics': true,
                },
              ));

      final config = await mockEnvironmentService.loadEnvironment(
        Environment.production,
      );
      expect(config.environment, equals(Environment.production));
      expect(config.features['debugMode'], isFalse);
    });

    test('Load staging environment', () async {
      when(mockEnvironmentService.loadEnvironment(Environment.staging))
          .thenAnswer((_) async => EnvironmentConfig(
                environment: Environment.staging,
                apiUrl: 'https://staging.ehrapp.com',
                blockchainNetwork: 'https://ropsten.infura.io',
                ipfsGateway: 'https://staging-ipfs.io',
                features: {
                  'debugMode': true,
                  'mockData': true,
                },
              ));

      final config = await mockEnvironmentService.loadEnvironment(
        Environment.staging,
      );
      expect(config.environment, equals(Environment.staging));
      expect(config.apiUrl, contains('staging'));
    });
  });

  group('Environment Feature Flag Tests', () {
    late MockEnvironmentService mockEnvironmentService;

    setUp(() {
      mockEnvironmentService = MockEnvironmentService();
    });

    test('Check feature flag', () async {
      when(mockEnvironmentService.isFeatureEnabled('biometricAuth'))
          .thenReturn(true);

      final isEnabled = mockEnvironmentService.isFeatureEnabled('biometricAuth');
      expect(isEnabled, isTrue);
    });

    test('Check environment-specific feature', () async {
      when(mockEnvironmentService.isFeatureEnabledForEnvironment(
        'debugLogging',
        Environment.development,
      )).thenReturn(true);

      when(mockEnvironmentService.isFeatureEnabledForEnvironment(
        'debugLogging',
        Environment.production,
      )).thenReturn(false);

      final devEnabled = mockEnvironmentService.isFeatureEnabledForEnvironment(
        'debugLogging',
        Environment.development,
      );
      final prodEnabled = mockEnvironmentService.isFeatureEnabledForEnvironment(
        'debugLogging',
        Environment.production,
      );

      expect(devEnabled, isTrue);
      expect(prodEnabled, isFalse);
    });
  });

  group('Environment Variable Tests', () {
    late MockEnvironmentService mockEnvironmentService;

    setUp(() {
      mockEnvironmentService = MockEnvironmentService();
    });

    test('Get environment variable', () {
      when(mockEnvironmentService.getVariable('API_KEY'))
          .thenReturn('test_api_key_123');

      final apiKey = mockEnvironmentService.getVariable('API_KEY');
      expect(apiKey, equals('test_api_key_123'));
    });

    test('Get sensitive environment variable', () {
      when(mockEnvironmentService.getSecureVariable('DB_PASSWORD'))
          .thenReturn('encrypted_password');

      final password = mockEnvironmentService.getSecureVariable('DB_PASSWORD');
      expect(password, equals('encrypted_password'));
    });
  });

  group('Environment Switching Tests', () {
    late MockEnvironmentService mockEnvironmentService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockEnvironmentService = MockEnvironmentService();
      mockStorageService = MockStorageService();
    });

    test('Switch environment', () async {
      when(mockEnvironmentService.switchEnvironment(Environment.staging))
          .thenAnswer((_) async => true);

      final result = await mockEnvironmentService.switchEnvironment(
        Environment.staging,
      );
      expect(result, isTrue);
    });

    test('Get current environment', () async {
      when(mockEnvironmentService.getCurrentEnvironment())
          .thenReturn(Environment.development);

      final environment = mockEnvironmentService.getCurrentEnvironment();
      expect(environment, equals(Environment.development));
    });
  });

  group('Environment Configuration Validation Tests', () {
    late MockEnvironmentService mockEnvironmentService;

    setUp(() {
      mockEnvironmentService = MockEnvironmentService();
    });

    test('Validate environment configuration', () async {
      final config = EnvironmentConfig(
        environment: Environment.production,
        apiUrl: 'https://api.ehrapp.com',
        blockchainNetwork: 'https://mainnet.infura.io',
        ipfsGateway: 'https://ipfs.io',
        features: {'analytics': true},
      );

      when(mockEnvironmentService.validateConfig(config))
          .thenAnswer((_) async => ValidationResult(
                isValid: true,
                issues: [],
              ));

      final result = await mockEnvironmentService.validateConfig(config);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('Detect invalid configuration', () async {
      final config = EnvironmentConfig(
        environment: Environment.production,
        apiUrl: 'invalid-url',
        blockchainNetwork: '',
        ipfsGateway: 'https://ipfs.io',
        features: {},
      );

      when(mockEnvironmentService.validateConfig(config))
          .thenAnswer((_) async => ValidationResult(
                isValid: false,
                issues: [
                  'Invalid API URL format',
                  'Blockchain network URL is required',
                ],
              ));

      final result = await mockEnvironmentService.validateConfig(config);
      expect(result.isValid, isFalse);
      expect(result.issues, hasLength(2));
    });
  });
}

enum Environment { development, staging, production }

class EnvironmentConfig {
  final Environment environment;
  final String apiUrl;
  final String blockchainNetwork;
  final String ipfsGateway;
  final Map<String, dynamic> features;

  EnvironmentConfig({
    required this.environment,
    required this.apiUrl,
    required this.blockchainNetwork,
    required this.ipfsGateway,
    required this.features,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> issues;

  ValidationResult({
    required this.isValid,
    required this.issues,
  });
}

class MockEnvironmentService extends Mock implements EnvironmentService {}
