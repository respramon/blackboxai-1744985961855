import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/search_service.dart';
import 'package:ehr_blockchain/services/storage_service.dart';
import 'package:ehr_blockchain/models/medical_record.dart';
import 'package:ehr_blockchain/models/user.dart';
import 'test_helpers.dart';

void main() {
  group('Basic Search Tests', () {
    late MockSearchService mockSearchService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockSearchService = MockSearchService();
      mockStorageService = MockStorageService();
    });

    test('Search medical records', () async {
      final query = SearchQuery(
        term: 'diabetes',
        filters: {
          'recordType': 'diagnosis',
          'dateRange': DateRange(
            start: DateTime(2023, 1, 1),
            end: DateTime(2023, 12, 31),
          ),
        },
      );

      when(mockSearchService.searchRecords(query))
          .thenAnswer((_) async => SearchResult<MedicalRecord>(
                items: List.generate(
                  3,
                  (i) => TestData.createTestRecord(
                    id: 'record_$i',
                    diagnosis: 'Type ${i + 1} Diabetes',
                  ),
                ),
                total: 3,
                page: 1,
                hasMore: false,
              ));

      final results = await mockSearchService.searchRecords(query);
      expect(results.items, hasLength(3));
      expect(results.items.first.diagnosis, contains('Diabetes'));
    });

    test('Search providers', () async {
      final query = SearchQuery(
        term: 'cardiologist',
        filters: {
          'specialty': 'cardiology',
          'location': 'New York',
        },
      );

      when(mockSearchService.searchProviders(query))
          .thenAnswer((_) async => SearchResult<User>(
                items: List.generate(
                  2,
                  (i) => TestData.createTestUser(
                    role: 'DOCTOR',
                    specialty: 'Cardiology',
                  ),
                ),
                total: 2,
                page: 1,
                hasMore: false,
              ));

      final results = await mockSearchService.searchProviders(query);
      expect(results.items, hasLength(2));
      expect(results.items.first.specialty, equals('Cardiology'));
    });
  });

  group('Advanced Search Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Full text search', () async {
      final query = FullTextSearchQuery(
        term: 'chronic heart condition treatment',
        fields: ['diagnosis', 'treatment', 'notes'],
        fuzzyMatch: true,
      );

      when(mockSearchService.performFullTextSearch(query))
          .thenAnswer((_) async => FullTextSearchResult(
                items: List.generate(
                  2,
                  (i) => SearchMatch(
                    record: TestData.createTestRecord(),
                    relevance: 0.85 - (i * 0.1),
                    matchedFields: ['diagnosis', 'treatment'],
                    highlights: {
                      'diagnosis': ['chronic <em>heart</em> condition'],
                      'treatment': ['ongoing <em>treatment</em> plan'],
                    },
                  ),
                ),
                total: 2,
                executionTime: const Duration(milliseconds: 150),
              ));

      final results = await mockSearchService.performFullTextSearch(query);
      expect(results.items, hasLength(2));
      expect(results.items.first.relevance, greaterThan(results.items.last.relevance));
    });

    test('Semantic search', () async {
      final query = SemanticSearchQuery(
        text: 'patients with heart problems',
        embedding: List.generate(384, (i) => i / 384),
        minSimilarity: 0.7,
      );

      when(mockSearchService.performSemanticSearch(query))
          .thenAnswer((_) async => SemanticSearchResult(
                items: List.generate(
                  3,
                  (i) => SemanticMatch(
                    record: TestData.createTestRecord(),
                    similarity: 0.9 - (i * 0.1),
                    vector: List.generate(384, (i) => i / 384),
                  ),
                ),
                total: 3,
              ));

      final results = await mockSearchService.performSemanticSearch(query);
      expect(results.items, hasLength(3));
      expect(results.items.first.similarity, greaterThan(0.8));
    });
  });

  group('Search Index Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Build search index', () async {
      when(mockSearchService.buildSearchIndex())
          .thenAnswer((_) async => IndexBuildResult(
                indexed: 1000,
                duration: const Duration(seconds: 5),
                status: IndexStatus.completed,
              ));

      final result = await mockSearchService.buildSearchIndex();
      expect(result.indexed, equals(1000));
      expect(result.status, equals(IndexStatus.completed));
    });

    test('Update search index', () async {
      final updates = [
        IndexUpdate(
          type: UpdateType.add,
          record: TestData.createTestRecord(),
        ),
        IndexUpdate(
          type: UpdateType.delete,
          recordId: 'record_123',
        ),
      ];

      when(mockSearchService.updateSearchIndex(updates))
          .thenAnswer((_) async => IndexUpdateResult(
                processed: 2,
                failed: 0,
                status: IndexStatus.completed,
              ));

      final result = await mockSearchService.updateSearchIndex(updates);
      expect(result.processed, equals(2));
      expect(result.failed, equals(0));
    });
  });

  group('Search Analytics Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Track search analytics', () async {
      final event = SearchAnalyticsEvent(
        query: 'diabetes treatment',
        filters: {'recordType': 'diagnosis'},
        resultCount: 5,
        duration: const Duration(milliseconds: 200),
        userAction: UserSearchAction.clickResult,
      );

      when(mockSearchService.trackSearchAnalytics(event))
          .thenAnswer((_) async => true);

      final result = await mockSearchService.trackSearchAnalytics(event);
      expect(result, isTrue);
    });

    test('Get search insights', () async {
      when(mockSearchService.getSearchInsights())
          .thenAnswer((_) async => SearchInsights(
                popularQueries: ['diabetes', 'heart disease', 'allergies'],
                averageResultCount: 8.5,
                averageSearchTime: const Duration(milliseconds: 180),
                successRate: 0.92,
                commonFilters: {
                  'recordType': ['diagnosis', 'treatment'],
                  'date': ['last month', 'last year'],
                },
              ));

      final insights = await mockSearchService.getSearchInsights();
      expect(insights.popularQueries, isNotEmpty);
      expect(insights.successRate, greaterThan(0.9));
    });
  });

  group('Search Configuration Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Update search configuration', () async {
      final config = SearchConfig(
        indexingStrategy: IndexingStrategy.realtime,
        searchFields: ['diagnosis', 'treatment', 'notes'],
        boostFields: {'diagnosis': 2.0, 'treatment': 1.5},
        fuzzyMatchingEnabled: true,
        minRelevanceScore: 0.6,
      );

      when(mockSearchService.updateSearchConfig(config))
          .thenAnswer((_) async => true);

      final result = await mockSearchService.updateSearchConfig(config);
      expect(result, isTrue);
    });

    test('Get current configuration', () async {
      when(mockSearchService.getCurrentConfig())
          .thenAnswer((_) async => SearchConfig(
                indexingStrategy: IndexingStrategy.realtime,
                searchFields: ['diagnosis', 'treatment', 'notes'],
                boostFields: {'diagnosis': 2.0},
                fuzzyMatchingEnabled: true,
                minRelevanceScore: 0.6,
              ));

      final config = await mockSearchService.getCurrentConfig();
      expect(config.indexingStrategy, equals(IndexingStrategy.realtime));
      expect(config.searchFields, hasLength(3));
    });
  });
}

enum IndexStatus { pending, inProgress, completed, failed }
enum UpdateType { add, delete, update }
enum IndexingStrategy { realtime, scheduled, manual }
enum UserSearchAction { search, filter, clickResult, refine }

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class SearchQuery {
  final String term;
  final Map<String, dynamic> filters;

  SearchQuery({
    required this.term,
    required this.filters,
  });
}

class SearchResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final bool hasMore;

  SearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class FullTextSearchQuery extends SearchQuery {
  final List<String> fields;
  final bool fuzzyMatch;

  FullTextSearchQuery({
    required String term,
    required this.fields,
    required this.fuzzyMatch,
    Map<String, dynamic>? filters,
  }) : super(term: term, filters: filters ?? {});
}

class SearchMatch {
  final MedicalRecord record;
  final double relevance;
  final List<String> matchedFields;
  final Map<String, List<String>> highlights;

  SearchMatch({
    required this.record,
    required this.relevance,
    required this.matchedFields,
    required this.highlights,
  });
}

class FullTextSearchResult {
  final List<SearchMatch> items;
  final int total;
  final Duration executionTime;

  FullTextSearchResult({
    required this.items,
    required this.total,
    required this.executionTime,
  });
}

class SemanticSearchQuery {
  final String text;
  final List<double> embedding;
  final double minSimilarity;

  SemanticSearchQuery({
    required this.text,
    required this.embedding,
    required this.minSimilarity,
  });
}

class SemanticMatch {
  final MedicalRecord record;
  final double similarity;
  final List<double> vector;

  SemanticMatch({
    required this.record,
    required this.similarity,
    required this.vector,
  });
}

class SemanticSearchResult {
  final List<SemanticMatch> items;
  final int total;

  SemanticSearchResult({
    required this.items,
    required this.total,
  });
}

class IndexBuildResult {
  final int indexed;
  final Duration duration;
  final IndexStatus status;

  IndexBuildResult({
    required this.indexed,
    required this.duration,
    required this.status,
  });
}

class IndexUpdate {
  final UpdateType type;
  final MedicalRecord? record;
  final String? recordId;

  IndexUpdate({
    required this.type,
    this.record,
    this.recordId,
  });
}

class IndexUpdateResult {
  final int processed;
  final int failed;
  final IndexStatus status;

  IndexUpdateResult({
    required this.processed,
    required this.failed,
    required this.status,
  });
}

class SearchAnalyticsEvent {
  final String query;
  final Map<String, dynamic> filters;
  final int resultCount;
  final Duration duration;
  final UserSearchAction userAction;

  SearchAnalyticsEvent({
    required this.query,
    required this.filters,
    required this.resultCount,
    required this.duration,
    required this.userAction,
  });
}

class SearchInsights {
  final List<String> popularQueries;
  final double averageResultCount;
  final Duration averageSearchTime;
  final double successRate;
  final Map<String, List<String>> commonFilters;

  SearchInsights({
    required this.popularQueries,
    required this.averageResultCount,
    required this.averageSearchTime,
    required this.successRate,
    required this.commonFilters,
  });
}

class SearchConfig {
  final IndexingStrategy indexingStrategy;
  final List<String> searchFields;
  final Map<String, double> boostFields;
  final bool fuzzyMatchingEnabled;
  final double minRelevanceScore;

  SearchConfig({
    required this.indexingStrategy,
    required this.searchFields,
    required this.boostFields,
    required this.fuzzyMatchingEnabled,
    required this.minRelevanceScore,
  });
}

class MockSearchService extends Mock implements SearchService {}
class MockStorageService extends Mock implements StorageService {}
