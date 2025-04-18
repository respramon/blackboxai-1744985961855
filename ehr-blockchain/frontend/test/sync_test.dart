import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/sync_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'package:ehr_blockchain/services/connectivity_service.dart';
import 'test_helpers.dart';

void main() {
  group('Data Synchronization Tests', () {
    late MockSyncService mockSyncService;
    late MockStorageService mockStorageService;
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockSyncService = MockSyncService();
      mockStorageService = MockStorageService();
      mockConnectivityService = MockConnectivityService();
    });

    test('Sync medical records', () async {
      when(mockSyncService.syncRecords())
          .thenAnswer((_) async => SyncResult(
                success: true,
                syncedItems: 10,
                conflicts: [],
                timestamp: DateTime.now(),
                stats: SyncStats(
                  uploaded: 3,
                  downloaded: 7,
                  deleted: 0,
                  duration: const Duration(seconds: 5),
                ),
              ));

      final result = await mockSyncService.syncRecords();
      expect(result.success, isTrue);
      expect(result.syncedItems, equals(10));
      expect(result.stats.uploaded + result.stats.downloaded, equals(10));
    });

    test('Handle sync conflicts', () async {
      final localRecord = TestData.createTestMedicalRecord(
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final remoteRecord = TestData.createTestMedicalRecord(
        lastModified: DateTime.now(),
      );

      when(mockSyncService.resolveConflict(
        local: localRecord,
        remote: remoteRecord,
        strategy: ConflictResolutionStrategy.remoteWins,
      )).thenAnswer((_) async => ConflictResolution(
            resolved: true,
            winner: remoteRecord,
            action: ResolutionAction.useRemote,
          ));

      final resolution = await mockSyncService.resolveConflict(
        local: localRecord,
        remote: remoteRecord,
        strategy: ConflictResolutionStrategy.remoteWins,
      );
      expect(resolution.resolved, isTrue);
      expect(resolution.action, equals(ResolutionAction.useRemote));
    });

    test('Sync with offline changes', () async {
      when(mockSyncService.syncOfflineChanges())
          .thenAnswer((_) async => OfflineSyncResult(
                syncedChanges: 5,
                pendingChanges: 0,
                conflicts: [],
                changesByType: {
                  'create': 2,
                  'update': 2,
                  'delete': 1,
                },
              ));

      final result = await mockSyncService.syncOfflineChanges();
      expect(result.syncedChanges, equals(5));
      expect(result.pendingChanges, equals(0));
    });
  });

  group('Sync Strategy Tests', () {
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
    });

    test('Configure sync strategy', () async {
      final strategy = SyncStrategy(
        mode: SyncMode.automatic,
        interval: const Duration(minutes: 30),
        conflictResolution: ConflictResolutionStrategy.remoteWins,
        retryPolicy: RetryPolicy(
          maxAttempts: 3,
          backoffInterval: const Duration(minutes: 5),
        ),
      );

      when(mockSyncService.configureSyncStrategy(strategy))
          .thenAnswer((_) async => true);

      final result = await mockSyncService.configureSyncStrategy(strategy);
      expect(result, isTrue);
    });

    test('Get sync status', () async {
      when(mockSyncService.getSyncStatus())
          .thenAnswer((_) async => SyncStatus(
                lastSync: DateTime.now().subtract(const Duration(minutes: 15)),
                currentState: SyncState.idle,
                pendingChanges: 2,
                lastError: null,
                nextScheduledSync: DateTime.now().add(const Duration(minutes: 15)),
              ));

      final status = await mockSyncService.getSyncStatus();
      expect(status.currentState, equals(SyncState.idle));
      expect(status.pendingChanges, equals(2));
    });
  });

  group('Sync Progress Monitoring Tests', () {
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
    });

    test('Monitor sync progress', () async {
      when(mockSyncService.monitorSyncProgress())
          .thenAnswer((_) => Stream.fromIterable([
                SyncProgress(
                  phase: SyncPhase.preparing,
                  progress: 0.0,
                  message: 'Preparing sync...',
                ),
                SyncProgress(
                  phase: SyncPhase.uploading,
                  progress: 0.5,
                  message: 'Uploading changes...',
                ),
                SyncProgress(
                  phase: SyncPhase.downloading,
                  progress: 0.8,
                  message: 'Downloading updates...',
                ),
                SyncProgress(
                  phase: SyncPhase.completed,
                  progress: 1.0,
                  message: 'Sync completed',
                ),
              ]));

      final progress = await mockSyncService.monitorSyncProgress().toList();
      expect(progress, hasLength(4));
      expect(progress.last.progress, equals(1.0));
      expect(progress.last.phase, equals(SyncPhase.completed));
    });

    test('Track sync metrics', () async {
      when(mockSyncService.getSyncMetrics())
          .thenAnswer((_) async => SyncMetrics(
                averageDuration: const Duration(seconds: 45),
                successRate: 0.95,
                conflictRate: 0.03,
                dataTransferred: 1024 * 1024, // 1MB
                syncFrequency: const Duration(minutes: 30),
              ));

      final metrics = await mockSyncService.getSyncMetrics();
      expect(metrics.successRate, greaterThan(0.9));
      expect(metrics.conflictRate, lessThan(0.05));
    });
  });

  group('Selective Sync Tests', () {
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
    });

    test('Configure selective sync', () async {
      final config = SelectiveSyncConfig(
        enabledTypes: ['medical_records', 'prescriptions'],
        filters: {
          'date_range': {
            'start': DateTime.now().subtract(const Duration(days: 90)),
            'end': DateTime.now(),
          },
          'status': ['active', 'pending'],
        },
        priority: {
          'medical_records': SyncPriority.high,
          'prescriptions': SyncPriority.normal,
        },
      );

      when(mockSyncService.configureSelectiveSync(config))
          .thenAnswer((_) async => SelectiveSyncResult(
                configured: true,
                estimatedSize: 1024 * 1024 * 50, // 50MB
                affectedItems: 1000,
              ));

      final result = await mockSyncService.configureSelectiveSync(config);
      expect(result.configured, isTrue);
      expect(result.affectedItems, equals(1000));
    });

    test('Get selective sync status', () async {
      when(mockSyncService.getSelectiveSyncStatus())
          .thenAnswer((_) async => SelectiveSyncStatus(
                enabledTypes: ['medical_records', 'prescriptions'],
                syncedSize: 1024 * 1024 * 30, // 30MB
                totalSize: 1024 * 1024 * 50, // 50MB
                lastUpdated: DateTime.now(),
              ));

      final status = await mockSyncService.getSelectiveSyncStatus();
      expect(status.enabledTypes, hasLength(2));
      expect(status.syncedSize, lessThan(status.totalSize));
    });
  });
}

enum SyncMode { manual, automatic, scheduled }
enum SyncState { idle, syncing, error }
enum SyncPhase { preparing, uploading, downloading, completed }
enum ConflictResolutionStrategy { localWins, remoteWins, manual, lastModifiedWins }
enum ResolutionAction { useLocal, useRemote, merge, skip }
enum SyncPriority { low, normal, high }

class SyncResult {
  final bool success;
  final int syncedItems;
  final List<SyncConflict> conflicts;
  final DateTime timestamp;
  final SyncStats stats;

  SyncResult({
    required this.success,
    required this.syncedItems,
    required this.conflicts,
    required this.timestamp,
    required this.stats,
  });
}

class SyncStats {
  final int uploaded;
  final int downloaded;
  final int deleted;
  final Duration duration;

  SyncStats({
    required this.uploaded,
    required this.downloaded,
    required this.deleted,
    required this.duration,
  });
}

class SyncConflict {
  final dynamic local;
  final dynamic remote;
  final String type;
  final DateTime detectedAt;

  SyncConflict({
    required this.local,
    required this.remote,
    required this.type,
    required this.detectedAt,
  });
}

class ConflictResolution {
  final bool resolved;
  final dynamic winner;
  final ResolutionAction action;

  ConflictResolution({
    required this.resolved,
    required this.winner,
    required this.action,
  });
}

class OfflineSyncResult {
  final int syncedChanges;
  final int pendingChanges;
  final List<SyncConflict> conflicts;
  final Map<String, int> changesByType;

  OfflineSyncResult({
    required this.syncedChanges,
    required this.pendingChanges,
    required this.conflicts,
    required this.changesByType,
  });
}

class SyncStrategy {
  final SyncMode mode;
  final Duration interval;
  final ConflictResolutionStrategy conflictResolution;
  final RetryPolicy retryPolicy;

  SyncStrategy({
    required this.mode,
    required this.interval,
    required this.conflictResolution,
    required this.retryPolicy,
  });
}

class RetryPolicy {
  final int maxAttempts;
  final Duration backoffInterval;

  RetryPolicy({
    required this.maxAttempts,
    required this.backoffInterval,
  });
}

class SyncStatus {
  final DateTime lastSync;
  final SyncState currentState;
  final int pendingChanges;
  final String? lastError;
  final DateTime? nextScheduledSync;

  SyncStatus({
    required this.lastSync,
    required this.currentState,
    required this.pendingChanges,
    this.lastError,
    this.nextScheduledSync,
  });
}

class SyncProgress {
  final SyncPhase phase;
  final double progress;
  final String message;

  SyncProgress({
    required this.phase,
    required this.progress,
    required this.message,
  });
}

class SyncMetrics {
  final Duration averageDuration;
  final double successRate;
  final double conflictRate;
  final int dataTransferred;
  final Duration syncFrequency;

  SyncMetrics({
    required this.averageDuration,
    required this.successRate,
    required this.conflictRate,
    required this.dataTransferred,
    required this.syncFrequency,
  });
}

class SelectiveSyncConfig {
  final List<String> enabledTypes;
  final Map<String, dynamic> filters;
  final Map<String, SyncPriority> priority;

  SelectiveSyncConfig({
    required this.enabledTypes,
    required this.filters,
    required this.priority,
  });
}

class SelectiveSyncResult {
  final bool configured;
  final int estimatedSize;
  final int affectedItems;

  SelectiveSyncResult({
    required this.configured,
    required this.estimatedSize,
    required this.affectedItems,
  });
}

class SelectiveSyncStatus {
  final List<String> enabledTypes;
  final int syncedSize;
  final int totalSize;
  final DateTime lastUpdated;

  SelectiveSyncStatus({
    required this.enabledTypes,
    required this.syncedSize,
    required this.totalSize,
    required this.lastUpdated,
  });
}

class MockSyncService extends Mock implements SyncService {}
class MockStorageService extends Mock implements StorageService {}
class MockConnectivityService extends Mock implements ConnectivityService {}
