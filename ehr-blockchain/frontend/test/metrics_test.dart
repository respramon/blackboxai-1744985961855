import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/analytics_service.dart';
import 'package:ehr_blockchain/services/metrics_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'test_helpers.dart';

void main() {
  group('Usage Metrics Tests', () {
    late MockMetricsService mockMetricsService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockMetricsService = MockMetricsService();
      mockAnalyticsService = MockAnalyticsService();
    });

    test('Track screen view', () async {
      final screenView = ScreenViewMetric(
        screenName: 'PatientDashboard',
        timestamp: DateTime.now(),
        duration: const Duration(minutes: 5),
      );

      when(mockMetricsService.trackScreenView(screenView))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackScreenView(screenView);
      expect(result, isTrue);
    });

    test('Track user action', () async {
      final userAction = UserActionMetric(
        action: 'view_record',
        context: 'PatientDashboard',
        timestamp: DateTime.now(),
        metadata: {'recordId': '123'},
      );

      when(mockMetricsService.trackUserAction(userAction))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackUserAction(userAction);
      expect(result, isTrue);
    });

    test('Track feature usage', () async {
      final featureUsage = FeatureUsageMetric(
        feature: 'biometric_auth',
        result: 'success',
        timestamp: DateTime.now(),
        duration: const Duration(seconds: 2),
      );

      when(mockMetricsService.trackFeatureUsage(featureUsage))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackFeatureUsage(featureUsage);
      expect(result, isTrue);
    });
  });

  group('Performance Metrics Tests', () {
    late MockMetricsService mockMetricsService;

    setUp(() {
      mockMetricsService = MockMetricsService();
    });

    test('Track API performance', () async {
      final apiMetric = APIMetric(
        endpoint: '/api/records',
        method: 'GET',
        duration: const Duration(milliseconds: 300),
        statusCode: 200,
        timestamp: DateTime.now(),
      );

      when(mockMetricsService.trackAPIMetric(apiMetric))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackAPIMetric(apiMetric);
      expect(result, isTrue);
    });

    test('Track blockchain transaction performance', () async {
      final txMetric = BlockchainMetric(
        operation: 'addRecord',
        gasUsed: 50000,
        duration: const Duration(seconds: 3),
        timestamp: DateTime.now(),
      );

      when(mockMetricsService.trackBlockchainMetric(txMetric))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackBlockchainMetric(txMetric);
      expect(result, isTrue);
    });

    test('Track app startup time', () async {
      final startupMetric = AppStartupMetric(
        duration: const Duration(milliseconds: 1500),
        timestamp: DateTime.now(),
        coldStart: true,
      );

      when(mockMetricsService.trackAppStartup(startupMetric))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.trackAppStartup(startupMetric);
      expect(result, isTrue);
    });
  });

  group('Analytics Reports Tests', () {
    late MockMetricsService mockMetricsService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockMetricsService = MockMetricsService();
      mockAnalyticsService = MockAnalyticsService();
    });

    test('Generate usage report', () async {
      when(mockAnalyticsService.generateUsageReport(any, any))
          .thenAnswer((_) async => UsageReport(
                period: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
                totalUsers: 100,
                activeUsers: 75,
                screenViews: {
                  'PatientDashboard': 500,
                  'RecordDetails': 300,
                },
                topFeatures: {
                  'biometric_auth': 200,
                  'share_record': 150,
                },
              ));

      final report = await mockAnalyticsService.generateUsageReport(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
      );
      expect(report.totalUsers, equals(100));
      expect(report.activeUsers, equals(75));
    });

    test('Generate performance report', () async {
      when(mockAnalyticsService.generatePerformanceReport(any, any))
          .thenAnswer((_) async => PerformanceReport(
                period: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
                averageAPILatency: const Duration(milliseconds: 250),
                averageBlockchainLatency: const Duration(seconds: 2),
                averageStartupTime: const Duration(milliseconds: 1500),
                errorRate: 0.02,
              ));

      final report = await mockAnalyticsService.generatePerformanceReport(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
      );
      expect(report.errorRate, lessThan(0.05));
    });
  });

  group('Metrics Storage Tests', () {
    late MockMetricsService mockMetricsService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockMetricsService = MockMetricsService();
      mockStorageService = MockStorageService();
    });

    test('Store metrics batch', () async {
      final metrics = [
        UserActionMetric(
          action: 'view_record',
          context: 'PatientDashboard',
          timestamp: DateTime.now(),
          metadata: {'recordId': '123'},
        ),
        APIMetric(
          endpoint: '/api/records',
          method: 'GET',
          duration: const Duration(milliseconds: 300),
          statusCode: 200,
          timestamp: DateTime.now(),
        ),
      ];

      when(mockMetricsService.storeMetricsBatch(metrics))
          .thenAnswer((_) async => true);

      final result = await mockMetricsService.storeMetricsBatch(metrics);
      expect(result, isTrue);
    });

    test('Clean old metrics', () async {
      when(mockMetricsService.cleanOldMetrics(any))
          .thenAnswer((_) async => 100);

      final deletedCount = await mockMetricsService.cleanOldMetrics(
        DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(deletedCount, equals(100));
    });
  });

  group('Real-time Analytics Tests', () {
    late MockMetricsService mockMetricsService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockMetricsService = MockMetricsService();
      mockAnalyticsService = MockAnalyticsService();
    });

    test('Track active users', () async {
      when(mockAnalyticsService.trackActiveUsers())
          .thenAnswer((_) => Stream.fromIterable([75, 80, 85]));

      final activeUsers = mockAnalyticsService.trackActiveUsers();
      expect(activeUsers, emitsInOrder([75, 80, 85]));
    });

    test('Track error rates', () async {
      when(mockAnalyticsService.trackErrorRates())
          .thenAnswer((_) => Stream.fromIterable([0.02, 0.03, 0.01]));

      final errorRates = mockAnalyticsService.trackErrorRates();
      expect(errorRates, emitsInOrder([0.02, 0.03, 0.01]));
    });
  });
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

class ScreenViewMetric {
  final String screenName;
  final DateTime timestamp;
  final Duration duration;

  ScreenViewMetric({
    required this.screenName,
    required this.timestamp,
    required this.duration,
  });
}

class UserActionMetric {
  final String action;
  final String context;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserActionMetric({
    required this.action,
    required this.context,
    required this.timestamp,
    required this.metadata,
  });
}

class FeatureUsageMetric {
  final String feature;
  final String result;
  final DateTime timestamp;
  final Duration duration;

  FeatureUsageMetric({
    required this.feature,
    required this.result,
    required this.timestamp,
    required this.duration,
  });
}

class APIMetric {
  final String endpoint;
  final String method;
  final Duration duration;
  final int statusCode;
  final DateTime timestamp;

  APIMetric({
    required this.endpoint,
    required this.method,
    required this.duration,
    required this.statusCode,
    required this.timestamp,
  });
}

class BlockchainMetric {
  final String operation;
  final int gasUsed;
  final Duration duration;
  final DateTime timestamp;

  BlockchainMetric({
    required this.operation,
    required this.gasUsed,
    required this.duration,
    required this.timestamp,
  });
}

class AppStartupMetric {
  final Duration duration;
  final DateTime timestamp;
  final bool coldStart;

  AppStartupMetric({
    required this.duration,
    required this.timestamp,
    required this.coldStart,
  });
}

class UsageReport {
  final DateTimeRange period;
  final int totalUsers;
  final int activeUsers;
  final Map<String, int> screenViews;
  final Map<String, int> topFeatures;

  UsageReport({
    required this.period,
    required this.totalUsers,
    required this.activeUsers,
    required this.screenViews,
    required this.topFeatures,
  });
}

class PerformanceReport {
  final DateTimeRange period;
  final Duration averageAPILatency;
  final Duration averageBlockchainLatency;
  final Duration averageStartupTime;
  final double errorRate;

  PerformanceReport({
    required this.period,
    required this.averageAPILatency,
    required this.averageBlockchainLatency,
    required this.averageStartupTime,
    required this.errorRate,
  });
}

class MockMetricsService extends Mock implements MetricsService {}
