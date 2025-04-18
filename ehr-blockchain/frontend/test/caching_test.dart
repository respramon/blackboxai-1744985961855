import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';

import 'package:ehr_blockchain/services/storage_service.dart';
import 'package:ehr_blockchain/services/blockchain_service.dart';
import 'package:ehr_blockchain/services/ipfs_service.dart';
import 'package:ehr_blockchain/models/medical_record.dart';
import 'test_helpers.dart';

void main() {
  group('Local Storage Tests', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    test('Cache medical records', () async {
      final records = List.generate(
        3,
        (i) => TestData.createTestRecord(id: 'record_$i'),
      );

      when(mockStorageService.write('cached_records', any))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.write(
        'cached_records',
        json.encode(records.map((r) => r.toJson()).toList()),
      );

      expect(result, isTrue);
      verify(mockStorageService.write('cached_records', any)).called(1);
    });

    test('Retrieve cached records', () async {
      final cachedData = json.encode([
        TestData.createTestRecord().toJson(),
      ]);

      when(mockStorageService.read('cached_records'))
          .thenReturn(cachedData);

      final data = mockStorageService.read('cached_records');
      final records = json.decode(data!)
          .map((r) => MedicalRecord.fromJson(r))
          .toList();

      expect(records, isNotEmpty);
      expect(records.first, isA<MedicalRecord>());
    });

    test('Cache expiration', () async {
      when(mockStorageService.getLastCacheUpdate('records'))
          .thenReturn(DateTime.now().subtract(const Duration(hours: 25)));

      when(mockStorageService.isCacheExpired('records'))
          .thenAnswer((_) async => true);

      final isExpired = await mockStorageService.isCacheExpired('records');
      expect(isExpired, isTrue);
    });
  });

  group('Cache Management Tests', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    test('Clear expired cache', () async {
      when(mockStorageService.clearExpiredCache())
          .thenAnswer((_) async => true);

      final result = await mockStorageService.clearExpiredCache();
      expect(result, isTrue);
    });

    test('Cache size management', () async {
      when(mockStorageService.getCacheSize())
          .thenAnswer((_) async => 1024 * 1024); // 1MB

      when(mockStorageService.enforceMaxCacheSize())
          .thenAnswer((_) async => true);

      final size = await mockStorageService.getCacheSize();
      expect(size, lessThanOrEqual(mockStorageService.maxCacheSize));

      final result = await mockStorageService.enforceMaxCacheSize();
      expect(result, isTrue);
    });

    test('Cache priority', () async {
      when(mockStorageService.setCachePriority('records', CachePriority.high))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.setCachePriority(
        'records',
        CachePriority.high,
      );
      expect(result, isTrue);
    });
  });

  group('IPFS Cache Tests', () {
    late MockIPFSService mockIpfsService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockIpfsService = MockIPFSService();
      mockStorageService = MockStorageService();
    });

    test('Cache IPFS file', () async {
      final fileData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileHash = 'QmTest...';

      when(mockStorageService.write('ipfs_$fileHash', any))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.write(
        'ipfs_$fileHash',
        base64Encode(fileData),
      );

      expect(result, isTrue);
    });

    test('Retrieve cached IPFS file', () async {
      final fileHash = 'QmTest...';
      final cachedData = base64Encode(Uint8List.fromList([1, 2, 3, 4, 5]));

      when(mockStorageService.read('ipfs_$fileHash'))
          .thenReturn(cachedData);

      final data = mockStorageService.read('ipfs_$fileHash');
      expect(data, isNotNull);
      expect(base64Decode(data!), isA<Uint8List>());
    });
  });

  group('Blockchain Cache Tests', () {
    late MockBlockchainService mockBlockchainService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockBlockchainService = MockBlockchainService();
      mockStorageService = MockStorageService();
    });

    test('Cache transaction history', () async {
      final transactions = [
        {'hash': '0x123...', 'status': 'confirmed'},
        {'hash': '0x456...', 'status': 'pending'},
      ];

      when(mockStorageService.write('tx_history', any))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.write(
        'tx_history',
        json.encode(transactions),
      );

      expect(result, isTrue);
    });

    test('Cache smart contract state', () async {
      final contractState = {
        'totalRecords': 100,
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      when(mockStorageService.write('contract_state', any))
          .thenAnswer((_) async => true);

      final result = await mockStorageService.write(
        'contract_state',
        json.encode(contractState),
      );

      expect(result, isTrue);
    });
  });

  group('Cache Synchronization Tests', () {
    late MockStorageService mockStorageService;
    late MockBlockchainService mockBlockchainService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockBlockchainService = MockBlockchainService();
    });

    test('Sync cached data with blockchain', () async {
      final cachedRecords = [
        TestData.createTestRecord(version: 1),
      ];

      final blockchainRecords = [
        TestData.createTestRecord(version: 2),
      ];

      when(mockStorageService.read('cached_records'))
          .thenReturn(json.encode(cachedRecords.map((r) => r.toJson()).toList()));

      when(mockBlockchainService.getRecords())
          .thenAnswer((_) async => blockchainRecords);

      when(mockStorageService.write('cached_records', any))
          .thenAnswer((_) async => true);

      // Simulate sync
      final cached = json.decode(mockStorageService.read('cached_records')!);
      final updated = await mockBlockchainService.getRecords();
      
      expect(cached.first['version'], lessThan(updated.first.version));

      final result = await mockStorageService.write(
        'cached_records',
        json.encode(updated.map((r) => r.toJson()).toList()),
      );

      expect(result, isTrue);
    });

    test('Handle sync conflicts', () async {
      final localRecord = TestData.createTestRecord(
        id: 'record_1',
        version: 1,
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final remoteRecord = TestData.createTestRecord(
        id: 'record_1',
        version: 2,
        lastModified: DateTime.now(),
      );

      final resolvedRecord = await mockBlockchainService.resolveConflict(
        localRecord,
        remoteRecord,
      );

      expect(resolvedRecord.version, equals(2));
      expect(resolvedRecord.lastModified, equals(remoteRecord.lastModified));
    });
  });
}

enum CachePriority {
  low,
  medium,
  high,
}
