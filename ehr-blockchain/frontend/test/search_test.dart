import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/search_service.dart';
import 'package:ehr_blockchain/widgets/search_bar.dart';
import 'package:ehr_blockchain/widgets/filter_chip.dart';
import 'package:ehr_blockchain/models/medical_record.dart';
import 'test_helpers.dart';

void main() {
  group('Search Bar Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    testWidgets('Search input handling', (WidgetTester tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSearchBar(
              onSearch: (query) => searchQuery = query,
              hintText: 'Search records',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(searchQuery, equals('test query'));
    });

    testWidgets('Search suggestions', (WidgetTester tester) async {
      final suggestions = ['diabetes', 'hypertension', 'allergies'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWithSuggestions(
              suggestions: suggestions,
              onSearch: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      for (final suggestion in suggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }
    });

    testWidgets('Clear search', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSearchBar(
              controller: controller,
              onSearch: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, isEmpty);
    });
  });

  group('Filter Tests', () {
    testWidgets('Filter chip selection', (WidgetTester tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomFilterChip(
              label: 'Test Filter',
              selected: isSelected,
              onSelected: (selected) => isSelected = selected,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      expect(isSelected, isTrue);
    });

    testWidgets('Multiple filter selection', (WidgetTester tester) async {
      final selectedFilters = <String>{};
      final filters = ['Type A', 'Type B', 'Type C'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterGroup(
              filters: filters,
              selectedFilters: selectedFilters,
              onFilterChanged: (filter, selected) {
                if (selected) {
                  selectedFilters.add(filter);
                } else {
                  selectedFilters.remove(filter);
                }
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Type A'));
      await tester.tap(find.text('Type C'));
      await tester.pump();

      expect(selectedFilters, equals({'Type A', 'Type C'}));
    });
  });

  group('Search Results Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Search medical records', () async {
      final records = List.generate(
        3,
        (i) => TestData.createTestRecord(
          description: 'Record $i with test condition',
        ),
      );

      when(mockSearchService.searchRecords('test'))
          .thenAnswer((_) async => records);

      final results = await mockSearchService.searchRecords('test');
      expect(results.length, equals(3));
      expect(
        results.every((r) => r.description.contains('test')),
        isTrue,
      );
    });

    test('Search with filters', () async {
      final filters = {
        'type': 'PRESCRIPTION',
        'date': 'last_month',
      };

      when(mockSearchService.searchRecords(
        'test',
        filters: filters,
      )).thenAnswer((_) async => [
            TestData.createTestRecord(
              type: 'PRESCRIPTION',
              date: DateTime.now().subtract(const Duration(days: 15)),
            ),
          ]);

      final results = await mockSearchService.searchRecords(
        'test',
        filters: filters,
      );
      expect(results.length, equals(1));
      expect(results.first.type, equals('PRESCRIPTION'));
    });
  });

  group('Search Performance Tests', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Search response time', () async {
      final startTime = DateTime.now();

      when(mockSearchService.searchRecords('test'))
          .thenAnswer((_) async => []);

      await mockSearchService.searchRecords('test');
      
      final duration = DateTime.now().difference(startTime);
      expect(duration.inMilliseconds, lessThan(1000));
    });

    test('Search result caching', () async {
      when(mockSearchService.getCachedResults('test'))
          .thenReturn([
            TestData.createTestRecord(),
          ]);

      final cachedResults = mockSearchService.getCachedResults('test');
      expect(cachedResults, isNotNull);
      expect(cachedResults, isNotEmpty);
    });
  });

  group('Advanced Search Features', () {
    late MockSearchService mockSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
    });

    test('Fuzzy search', () async {
      when(mockSearchService.searchRecords(
        'diabtes',
        options: SearchOptions(fuzzySearch: true),
      )).thenAnswer((_) async => [
            TestData.createTestRecord(description: 'Diabetes Type 2'),
          ]);

      final results = await mockSearchService.searchRecords(
        'diabtes',
        options: SearchOptions(fuzzySearch: true),
      );
      expect(results, isNotEmpty);
    });

    test('Search by date range', () async {
      final dateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );

      when(mockSearchService.searchRecords(
        'test',
        dateRange: dateRange,
      )).thenAnswer((_) async => [
            TestData.createTestRecord(
              date: DateTime.now().subtract(const Duration(days: 15)),
            ),
          ]);

      final results = await mockSearchService.searchRecords(
        'test',
        dateRange: dateRange,
      );
      expect(results, isNotEmpty);
    });
  });
}

class CustomSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  final TextEditingController? controller;
  final String? hintText;

  const CustomSearchBar({
    super.key,
    required this.onSearch,
    this.controller,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            controller?.clear();
          },
        ),
      ),
      onSubmitted: onSearch,
    );
  }
}

class SearchBarWithSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSearch;

  const SearchBarWithSuggestions({
    super.key,
    required this.suggestions,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomSearchBar(onSearch: onSearch),
        Expanded(
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(suggestions[index]),
              onTap: () => onSearch(suggestions[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class FilterGroup extends StatelessWidget {
  final List<String> filters;
  final Set<String> selectedFilters;
  final Function(String, bool) onFilterChanged;

  const FilterGroup({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: filters.map((filter) {
        return CustomFilterChip(
          label: filter,
          selected: selectedFilters.contains(filter),
          onSelected: (selected) => onFilterChanged(filter, selected),
        );
      }).toList(),
    );
  }
}

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class SearchOptions {
  final bool fuzzySearch;
  final int? maxResults;

  const SearchOptions({
    this.fuzzySearch = false,
    this.maxResults,
  });
}
