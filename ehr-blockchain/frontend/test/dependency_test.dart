import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import 'package:ehr_blockchain/services/service_locator.dart';
import 'package:ehr_blockchain/services/auth_service.dart';
import 'package:ehr_blockchain/services/blockchain_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'package:ehr_blockchain/services/encryption_service.dart';
import 'test_helpers.dart';

void main() {
  final getIt = GetIt.instance;

  group('Service Registration Tests', () {
    setUp(() {
      getIt.reset();
    });

    test('Register singleton services', () {
      ServiceLocator.setupSingletons();

      expect(getIt.isRegistered<AuthService>(), isTrue);
      expect(getIt.isRegistered<BlockchainService>(), isTrue);
      expect(getIt.isRegistered<StorageService>(), isTrue);
      expect(getIt.isRegistered<EncryptionService>(), isTrue);
    });

    test('Register factory services', () {
      ServiceLocator.setupFactories();

      expect(getIt.isRegistered<DialogService>(), isTrue);
      expect(getIt.isRegistered<NavigationService>(), isTrue);
    });

    test('Register lazy singletons', () {
      ServiceLocator.setupLazySingletons();

      expect(getIt.isRegistered<AnalyticsService>(), isTrue);
      expect(getIt.isRegistered<LoggingService>(), isTrue);
    });
  });

  group('Service Resolution Tests', () {
    setUp(() {
      getIt.reset();
      ServiceLocator.setupSingletons();
    });

    test('Resolve singleton service', () {
      final authService1 = getIt<AuthService>();
      final authService2 = getIt<AuthService>();

      expect(authService1, equals(authService2));
    });

    test('Resolve factory service', () {
      ServiceLocator.setupFactories();

      final dialogService1 = getIt<DialogService>();
      final dialogService2 = getIt<DialogService>();

      expect(dialogService1, isNot(equals(dialogService2)));
    });

    test('Resolve lazy singleton', () {
      ServiceLocator.setupLazySingletons();

      final analyticsService = getIt<AnalyticsService>();
      expect(analyticsService, isNotNull);
    });
  });

  group('Service Dependencies Tests', () {
    late MockAuthService mockAuthService;
    late MockStorageService mockStorageService;

    setUp(() {
      getIt.reset();
      mockAuthService = MockAuthService();
      mockStorageService = MockStorageService();
    });

    test('Register service with dependencies', () {
      getIt.registerSingleton<AuthService>(mockAuthService);
      getIt.registerSingleton<StorageService>(mockStorageService);

      final userService = getIt<UserService>();
      expect(userService, isNotNull);
    });

    test('Override service registration', () {
      getIt.registerSingleton<AuthService>(MockAuthService());
      getIt.registerSingleton<StorageService>(MockStorageService());

      getIt.unregister<AuthService>();
      getIt.registerSingleton<AuthService>(mockAuthService);

      final resolvedService = getIt<AuthService>();
      expect(resolvedService, equals(mockAuthService));
    });
  });

  group('Environment-specific Service Tests', () {
    setUp(() {
      getIt.reset();
    });

    test('Register development services', () {
      ServiceLocator.setupDevelopmentServices();

      expect(getIt.isRegistered<MockBlockchainService>(), isTrue);
      expect(getIt.isRegistered<MockStorageService>(), isTrue);
    });

    test('Register production services', () {
      ServiceLocator.setupProductionServices();

      expect(getIt.isRegistered<BlockchainService>(), isTrue);
      expect(getIt.isRegistered<StorageService>(), isTrue);
    });

    test('Register test services', () {
      ServiceLocator.setupTestServices();

      expect(getIt.isRegistered<MockAuthService>(), isTrue);
      expect(getIt.isRegistered<MockEncryptionService>(), isTrue);
    });
  });

  group('Service Configuration Tests', () {
    setUp(() {
      getIt.reset();
    });

    test('Configure service with parameters', () {
      final config = ServiceConfig(
        apiUrl: 'https://api.example.com',
        timeout: const Duration(seconds: 30),
        retryAttempts: 3,
      );

      ServiceLocator.configureServices(config);

      final apiService = getIt<ApiService>();
      expect(apiService.baseUrl, equals(config.apiUrl));
      expect(apiService.timeout, equals(config.timeout));
    });

    test('Update service configuration', () {
      final initialConfig = ServiceConfig(
        apiUrl: 'https://api.example.com',
        timeout: const Duration(seconds: 30),
        retryAttempts: 3,
      );

      final updatedConfig = ServiceConfig(
        apiUrl: 'https://api2.example.com',
        timeout: const Duration(seconds: 60),
        retryAttempts: 5,
      );

      ServiceLocator.configureServices(initialConfig);
      ServiceLocator.updateConfiguration(updatedConfig);

      final apiService = getIt<ApiService>();
      expect(apiService.baseUrl, equals(updatedConfig.apiUrl));
      expect(apiService.timeout, equals(updatedConfig.timeout));
    });
  });

  group('Service Lifecycle Tests', () {
    late MockLifecycleAwareService mockLifecycleService;

    setUp(() {
      getIt.reset();
      mockLifecycleService = MockLifecycleAwareService();
      getIt.registerSingleton<LifecycleAwareService>(mockLifecycleService);
    });

    test('Initialize services', () async {
      when(mockLifecycleService.initialize())
          .thenAnswer((_) async => true);

      await ServiceLocator.initializeServices();

      verify(mockLifecycleService.initialize()).called(1);
    });

    test('Dispose services', () async {
      when(mockLifecycleService.dispose())
          .thenAnswer((_) async => true);

      await ServiceLocator.disposeServices();

      verify(mockLifecycleService.dispose()).called(1);
    });
  });
}

class ServiceConfig {
  final String apiUrl;
  final Duration timeout;
  final int retryAttempts;

  ServiceConfig({
    required this.apiUrl,
    required this.timeout,
    required this.retryAttempts,
  });
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    required this.timeout,
  });
}

class DialogService {}
class NavigationService {}
class AnalyticsService {}
class LoggingService {}
class UserService {}

abstract class LifecycleAwareService {
  Future<bool> initialize();
  Future<bool> dispose();
}

class MockLifecycleAwareService extends Mock implements LifecycleAwareService {}
class MockBlockchainService extends Mock implements BlockchainService {}
class MockAuthService extends Mock implements AuthService {}
class MockStorageService extends Mock implements StorageService {}
class MockEncryptionService extends Mock implements EncryptionService {}
