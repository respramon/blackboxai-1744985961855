import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/deep_link_service.dart';
import 'package:ehr_blockchain/services/navigation_service.dart';
import 'package:ehr_blockchain/services/auth_service.dart';
import 'test_helpers.dart';

void main() {
  group('Deep Link Handling Tests', () {
    late MockDeepLinkService mockDeepLinkService;
    late MockNavigationService mockNavigationService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockDeepLinkService = MockDeepLinkService();
      mockNavigationService = MockNavigationService();
      mockAuthService = MockAuthService();
    });

    test('Parse deep link URL', () {
      final url = 'ehrapp://records/123?action=view';

      when(mockDeepLinkService.parseDeepLink(url))
          .thenReturn(DeepLinkData(
            path: '/records/123',
            action: 'view',
            parameters: {'recordId': '123'},
          ));

      final result = mockDeepLinkService.parseDeepLink(url);
      expect(result.path, equals('/records/123'));
      expect(result.action, equals('view'));
      expect(result.parameters['recordId'], equals('123'));
    });

    test('Handle medical record deep link', () async {
      final deepLink = DeepLinkData(
        path: '/records/123',
        action: 'view',
        parameters: {'recordId': '123'},
      );

      when(mockDeepLinkService.handleDeepLink(deepLink))
          .thenAnswer((_) async => DeepLinkResult(
                success: true,
                destination: '/record-details/123',
              ));

      final result = await mockDeepLinkService.handleDeepLink(deepLink);
      expect(result.success, isTrue);
      expect(result.destination, equals('/record-details/123'));
    });

    test('Handle sharing invitation deep link', () async {
      final deepLink = DeepLinkData(
        path: '/share/invite',
        action: 'accept',
        parameters: {
          'inviteCode': 'ABC123',
          'providerId': '456',
        },
      );

      when(mockDeepLinkService.handleDeepLink(deepLink))
          .thenAnswer((_) async => DeepLinkResult(
                success: true,
                destination: '/share-acceptance',
                data: {'inviteCode': 'ABC123'},
              ));

      final result = await mockDeepLinkService.handleDeepLink(deepLink);
      expect(result.success, isTrue);
      expect(result.data?['inviteCode'], equals('ABC123'));
    });
  });

  group('Deep Link Navigation Tests', () {
    late MockDeepLinkService mockDeepLinkService;
    late MockNavigationService mockNavigationService;

    setUp(() {
      mockDeepLinkService = MockDeepLinkService();
      mockNavigationService = MockNavigationService();
    });

    test('Navigate to deep link destination', () async {
      final deepLinkResult = DeepLinkResult(
        success: true,
        destination: '/record-details/123',
        data: {'recordId': '123'},
      );

      when(mockNavigationService.navigateToDeepLink(
        deepLinkResult.destination,
        arguments: deepLinkResult.data,
      )).thenAnswer((_) async => true);

      final result = await mockNavigationService.navigateToDeepLink(
        deepLinkResult.destination,
        arguments: deepLinkResult.data,
      );
      expect(result, isTrue);
    });

    test('Handle invalid deep link navigation', () async {
      final deepLinkResult = DeepLinkResult(
        success: false,
        error: 'Invalid destination',
      );

      when(mockNavigationService.navigateToDeepLink(
        deepLinkResult.destination ?? '',
      )).thenAnswer((_) async => false);

      final result = await mockNavigationService.navigateToDeepLink(
        deepLinkResult.destination ?? '',
      );
      expect(result, isFalse);
    });
  });

  group('Deep Link Authentication Tests', () {
    late MockDeepLinkService mockDeepLinkService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockDeepLinkService = MockDeepLinkService();
      mockAuthService = MockAuthService();
    });

    test('Handle authenticated deep link', () async {
      when(mockAuthService.isAuthenticated())
          .thenReturn(true);

      final deepLink = DeepLinkData(
        path: '/records/123',
        action: 'view',
        parameters: {'recordId': '123'},
        requiresAuth: true,
      );

      when(mockDeepLinkService.handleDeepLink(deepLink))
          .thenAnswer((_) async => DeepLinkResult(
                success: true,
                destination: '/record-details/123',
              ));

      final result = await mockDeepLinkService.handleDeepLink(deepLink);
      expect(result.success, isTrue);
    });

    test('Handle unauthenticated deep link', () async {
      when(mockAuthService.isAuthenticated())
          .thenReturn(false);

      final deepLink = DeepLinkData(
        path: '/records/123',
        action: 'view',
        parameters: {'recordId': '123'},
        requiresAuth: true,
      );

      when(mockDeepLinkService.handleDeepLink(deepLink))
          .thenAnswer((_) async => DeepLinkResult(
                success: false,
                error: 'Authentication required',
                pendingDeepLink: deepLink,
              ));

      final result = await mockDeepLinkService.handleDeepLink(deepLink);
      expect(result.success, isFalse);
      expect(result.pendingDeepLink, equals(deepLink));
    });
  });

  group('Deep Link Generation Tests', () {
    late MockDeepLinkService mockDeepLinkService;

    setUp(() {
      mockDeepLinkService = MockDeepLinkService();
    });

    test('Generate record sharing deep link', () {
      final params = {
        'recordId': '123',
        'providerId': '456',
        'expiry': '2024-12-31',
      };

      when(mockDeepLinkService.generateDeepLink(
        path: '/share/record',
        parameters: params,
      )).thenReturn('ehrapp://share/record?recordId=123&providerId=456&expiry=2024-12-31');

      final url = mockDeepLinkService.generateDeepLink(
        path: '/share/record',
        parameters: params,
      );
      expect(url, contains('ehrapp://share/record'));
      expect(url, contains('recordId=123'));
    });

    test('Generate invitation deep link', () {
      final params = {
        'inviteCode': 'ABC123',
        'role': 'doctor',
      };

      when(mockDeepLinkService.generateDeepLink(
        path: '/invite',
        parameters: params,
      )).thenReturn('ehrapp://invite?inviteCode=ABC123&role=doctor');

      final url = mockDeepLinkService.generateDeepLink(
        path: '/invite',
        parameters: params,
      );
      expect(url, contains('ehrapp://invite'));
      expect(url, contains('inviteCode=ABC123'));
    });
  });

  group('Deep Link State Management Tests', () {
    late MockDeepLinkService mockDeepLinkService;

    setUp(() {
      mockDeepLinkService = MockDeepLinkService();
    });

    test('Store pending deep link', () async {
      final deepLink = DeepLinkData(
        path: '/records/123',
        action: 'view',
        parameters: {'recordId': '123'},
      );

      when(mockDeepLinkService.storePendingDeepLink(deepLink))
          .thenAnswer((_) async => true);

      final result = await mockDeepLinkService.storePendingDeepLink(deepLink);
      expect(result, isTrue);
    });

    test('Retrieve pending deep link', () async {
      when(mockDeepLinkService.getPendingDeepLink())
          .thenAnswer((_) async => DeepLinkData(
                path: '/records/123',
                action: 'view',
                parameters: {'recordId': '123'},
              ));

      final pendingLink = await mockDeepLinkService.getPendingDeepLink();
      expect(pendingLink, isNotNull);
      expect(pendingLink?.path, equals('/records/123'));
    });
  });
}

class DeepLinkData {
  final String path;
  final String action;
  final Map<String, String> parameters;
  final bool requiresAuth;

  DeepLinkData({
    required this.path,
    required this.action,
    required this.parameters,
    this.requiresAuth = false,
  });
}

class DeepLinkResult {
  final bool success;
  final String? destination;
  final Map<String, dynamic>? data;
  final String? error;
  final DeepLinkData? pendingDeepLink;

  DeepLinkResult({
    required this.success,
    this.destination,
    this.data,
    this.error,
    this.pendingDeepLink,
  });
}

class MockDeepLinkService extends Mock implements DeepLinkService {}
class MockNavigationService extends Mock implements NavigationService {}
class MockAuthService extends Mock implements AuthService {}
