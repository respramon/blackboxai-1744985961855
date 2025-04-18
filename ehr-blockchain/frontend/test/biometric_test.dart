import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/biometric_service.dart';
import 'package:ehr_blockchain/services/auth_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  group('Biometric Authentication Tests', () {
    late MockBiometricService mockBiometricService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockBiometricService = MockBiometricService();
      mockAuthService = MockAuthService();
    });

    test('Check biometric availability', () async {
      when(mockBiometricService.checkBiometricAvailability())
          .thenAnswer((_) async => BiometricAvailability(
                available: true,
                types: [
                  BiometricType.fingerprint,
                  BiometricType.faceId,
                ],
                canAuthenticate: true,
              ));

      final availability = await mockBiometricService.checkBiometricAvailability();
      expect(availability.available, isTrue);
      expect(availability.types, contains(BiometricType.fingerprint));
    });

    test('Authenticate with biometrics', () async {
      when(mockBiometricService.authenticate(
        reason: 'Access medical records',
        options: any,
      )).thenAnswer((_) async => AuthenticationResult(
            success: true,
            method: BiometricType.fingerprint,
            timestamp: DateTime.now(),
          ));

      final result = await mockBiometricService.authenticate(
        reason: 'Access medical records',
        options: const BiometricOptions(
          allowDeviceCredential: true,
          confirmationRequired: true,
        ),
      );
      expect(result.success, isTrue);
      expect(result.method, equals(BiometricType.fingerprint));
    });

    test('Handle biometric failure', () async {
      when(mockBiometricService.authenticate(
        reason: 'Access medical records',
        options: any,
      )).thenAnswer((_) async => AuthenticationResult(
            success: false,
            error: BiometricError.userCanceled,
            timestamp: DateTime.now(),
          ));

      final result = await mockBiometricService.authenticate(
        reason: 'Access medical records',
        options: const BiometricOptions(
          allowDeviceCredential: true,
          confirmationRequired: true,
        ),
      );
      expect(result.success, isFalse);
      expect(result.error, equals(BiometricError.userCanceled));
    });
  });

  group('Biometric Enrollment Tests', () {
    late MockBiometricService mockBiometricService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockBiometricService = MockBiometricService();
      mockStorageService = MockStorageService();
    });

    test('Enroll biometric', () async {
      final enrollment = BiometricEnrollment(
        userId: 'user123',
        type: BiometricType.fingerprint,
        timestamp: DateTime.now(),
      );

      when(mockBiometricService.enrollBiometric(enrollment))
          .thenAnswer((_) async => EnrollmentResult(
                success: true,
                enrollmentId: 'enroll_123',
                requiresConfirmation: false,
              ));

      final result = await mockBiometricService.enrollBiometric(enrollment);
      expect(result.success, isTrue);
      expect(result.enrollmentId, isNotNull);
    });

    test('Remove biometric enrollment', () async {
      when(mockBiometricService.removeBiometricEnrollment('enroll_123'))
          .thenAnswer((_) async => true);

      final result = await mockBiometricService.removeBiometricEnrollment(
        'enroll_123',
      );
      expect(result, isTrue);
    });

    test('List enrolled biometrics', () async {
      when(mockBiometricService.getEnrolledBiometrics())
          .thenAnswer((_) async => [
                BiometricEnrollment(
                  userId: 'user123',
                  type: BiometricType.fingerprint,
                  timestamp: DateTime.now(),
                ),
                BiometricEnrollment(
                  userId: 'user123',
                  type: BiometricType.faceId,
                  timestamp: DateTime.now(),
                ),
              ]);

      final enrollments = await mockBiometricService.getEnrolledBiometrics();
      expect(enrollments, hasLength(2));
      expect(
        enrollments.map((e) => e.type),
        containsAll([BiometricType.fingerprint, BiometricType.faceId]),
      );
    });
  });

  group('Biometric Security Tests', () {
    late MockBiometricService mockBiometricService;

    setUp(() {
      mockBiometricService = MockBiometricService();
    });

    test('Verify biometric strength', () async {
      when(mockBiometricService.verifyBiometricStrength())
          .thenAnswer((_) async => SecurityAssessment(
                level: SecurityLevel.high,
                requirements: [
                  SecurityRequirement(
                    type: RequirementType.hardware,
                    met: true,
                    details: 'Secure hardware available',
                  ),
                  SecurityRequirement(
                    type: RequirementType.encryption,
                    met: true,
                    details: 'Strong encryption supported',
                  ),
                ],
              ));

      final assessment = await mockBiometricService.verifyBiometricStrength();
      expect(assessment.level, equals(SecurityLevel.high));
      expect(assessment.requirements, hasLength(2));
    });

    test('Check biometric policy compliance', () async {
      final policy = BiometricPolicy(
        requiredStrength: SecurityLevel.high,
        allowedTypes: [BiometricType.fingerprint, BiometricType.faceId],
        maxAttempts: 3,
        lockoutDuration: const Duration(minutes: 5),
      );

      when(mockBiometricService.checkPolicyCompliance(policy))
          .thenAnswer((_) async => ComplianceResult(
                compliant: true,
                violations: [],
                recommendations: [
                  'Consider enabling attestation',
                ],
              ));

      final result = await mockBiometricService.checkPolicyCompliance(policy);
      expect(result.compliant, isTrue);
      expect(result.violations, isEmpty);
    });
  });

  group('Biometric Event Handling Tests', () {
    late MockBiometricService mockBiometricService;

    setUp(() {
      mockBiometricService = MockBiometricService();
    });

    test('Handle authentication events', () async {
      final event = BiometricEvent(
        type: EventType.authenticationAttempt,
        success: true,
        biometricType: BiometricType.fingerprint,
        timestamp: DateTime.now(),
      );

      when(mockBiometricService.handleBiometricEvent(event))
          .thenAnswer((_) async => EventHandlingResult(
                handled: true,
                action: EventAction.allow,
                metadata: {'attemptCount': 1},
              ));

      final result = await mockBiometricService.handleBiometricEvent(event);
      expect(result.handled, isTrue);
      expect(result.action, equals(EventAction.allow));
    });

    test('Track authentication attempts', () async {
      when(mockBiometricService.getAuthenticationAttempts())
          .thenAnswer((_) async => AttemptHistory(
                total: 5,
                successful: 4,
                lastAttempt: DateTime.now(),
                attempts: [
                  BiometricEvent(
                    type: EventType.authenticationAttempt,
                    success: true,
                    biometricType: BiometricType.fingerprint,
                    timestamp: DateTime.now(),
                  ),
                ],
              ));

      final history = await mockBiometricService.getAuthenticationAttempts();
      expect(history.total, equals(5));
      expect(history.successful, equals(4));
    });
  });
}

enum BiometricType { fingerprint, faceId, irisScanner }
enum BiometricError { userCanceled, lockout, hardware, timeout }
enum SecurityLevel { low, medium, high }
enum RequirementType { hardware, software, encryption, policy }
enum EventType { authenticationAttempt, enrollment, removal }
enum EventAction { allow, deny, lockout }

class BiometricAvailability {
  final bool available;
  final List<BiometricType> types;
  final bool canAuthenticate;

  BiometricAvailability({
    required this.available,
    required this.types,
    required this.canAuthenticate,
  });
}

class BiometricOptions {
  final bool allowDeviceCredential;
  final bool confirmationRequired;

  const BiometricOptions({
    required this.allowDeviceCredential,
    required this.confirmationRequired,
  });
}

class AuthenticationResult {
  final bool success;
  final BiometricType? method;
  final BiometricError? error;
  final DateTime timestamp;

  AuthenticationResult({
    required this.success,
    this.method,
    this.error,
    required this.timestamp,
  });
}

class BiometricEnrollment {
  final String userId;
  final BiometricType type;
  final DateTime timestamp;

  BiometricEnrollment({
    required this.userId,
    required this.type,
    required this.timestamp,
  });
}

class EnrollmentResult {
  final bool success;
  final String? enrollmentId;
  final bool requiresConfirmation;

  EnrollmentResult({
    required this.success,
    this.enrollmentId,
    required this.requiresConfirmation,
  });
}

class SecurityRequirement {
  final RequirementType type;
  final bool met;
  final String details;

  SecurityRequirement({
    required this.type,
    required this.met,
    required this.details,
  });
}

class SecurityAssessment {
  final SecurityLevel level;
  final List<SecurityRequirement> requirements;

  SecurityAssessment({
    required this.level,
    required this.requirements,
  });
}

class BiometricPolicy {
  final SecurityLevel requiredStrength;
  final List<BiometricType> allowedTypes;
  final int maxAttempts;
  final Duration lockoutDuration;

  BiometricPolicy({
    required this.requiredStrength,
    required this.allowedTypes,
    required this.maxAttempts,
    required this.lockoutDuration,
  });
}

class ComplianceResult {
  final bool compliant;
  final List<String> violations;
  final List<String> recommendations;

  ComplianceResult({
    required this.compliant,
    required this.violations,
    required this.recommendations,
  });
}

class BiometricEvent {
  final EventType type;
  final bool success;
  final BiometricType biometricType;
  final DateTime timestamp;

  BiometricEvent({
    required this.type,
    required this.success,
    required this.biometricType,
    required this.timestamp,
  });
}

class EventHandlingResult {
  final bool handled;
  final EventAction action;
  final Map<String, dynamic> metadata;

  EventHandlingResult({
    required this.handled,
    required this.action,
    required this.metadata,
  });
}

class AttemptHistory {
  final int total;
  final int successful;
  final DateTime lastAttempt;
  final List<BiometricEvent> attempts;

  AttemptHistory({
    required this.total,
    required this.successful,
    required this.lastAttempt,
    required this.attempts,
  });
}

class MockBiometricService extends Mock implements BiometricService {}
class MockAuthService extends Mock implements AuthService {}
class MockStorageService extends Mock implements StorageService {}
