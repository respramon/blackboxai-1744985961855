import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

void main() {
  group('Package Metadata Tests', () {
    late File pubspecFile;
    late YamlMap pubspecContent;

    setUp(() {
      pubspecFile = File('pubspec.yaml');
      pubspecContent = loadYaml(pubspecFile.readAsStringSync());
    });

    test('Verify package name', () {
      expect(pubspecContent['name'], 'ehr_blockchain');
    });

    test('Verify package version', () {
      expect(
        pubspecContent['version'],
        matches(r'^\d+\.\d+\.\d+(\+\d+)?$'),
      );
    });

    test('Required dependencies', () {
      final dependencies = pubspecContent['dependencies'] as YamlMap;
      
      final requiredPackages = [
        'flutter',
        'provider',
        'http',
        'shared_preferences',
        'web3dart',
        'flutter_secure_storage',
      ];

      for (final package in requiredPackages) {
        expect(dependencies.containsKey(package), isTrue);
      }
    });

    test('Development dependencies', () {
      final devDependencies = pubspecContent['dev_dependencies'] as YamlMap;
      
      final requiredDevPackages = [
        'flutter_test',
        'mockito',
        'build_runner',
        'flutter_lints',
      ];

      for (final package in requiredDevPackages) {
        expect(devDependencies.containsKey(package), isTrue);
      }
    });
  });

  group('Documentation Tests', () {
    test('README.md exists and contains required sections', () {
      final readmeFile = File('README.md');
      expect(readmeFile.existsSync(), isTrue);

      final content = readmeFile.readAsStringSync();
      
      final requiredSections = [
        '# EHR Blockchain',
        '## Getting Started',
        '## Features',
        '## Installation',
      ];

      for (final section in requiredSections) {
        expect(content.contains(section), isTrue);
      }
    });

    test('API documentation exists', () {
      final apiDocsDir = Directory('doc/api');
      expect(apiDocsDir.existsSync(), isTrue);
    });

    test('License file exists', () {
      final licenseFile = File('LICENSE');
      expect(licenseFile.existsSync(), isTrue);
    });
  });

  group('Code Quality Tests', () {
    test('Analysis options configuration', () {
      final analysisOptionsFile = File('analysis_options.yaml');
      expect(analysisOptionsFile.existsSync(), isTrue);

      final content = loadYaml(analysisOptionsFile.readAsStringSync());
      expect(content['include'], 'package:flutter_lints/flutter.yaml');
    });

    test('Code formatting', () {
      final result = Process.runSync('flutter', ['format', '--set-exit-if-changed', '.']);
      expect(result.exitCode, 0);
    });

    test('Static analysis', () {
      final result = Process.runSync('flutter', ['analyze']);
      expect(result.exitCode, 0);
    });
  });

  group('Asset Tests', () {
    late YamlMap pubspecContent;

    setUp(() {
      final pubspecFile = File('pubspec.yaml');
      pubspecContent = loadYaml(pubspecFile.readAsStringSync());
    });

    test('Required assets are declared', () {
      final assets = pubspecContent['flutter']['assets'] as YamlList?;
      expect(assets, isNotNull);

      final requiredAssets = [
        'assets/images/',
        'assets/icons/',
        'assets/contracts/',
      ];

      for (final asset in requiredAssets) {
        expect(assets!.contains(asset), isTrue);
      }
    });

    test('Font configuration', () {
      final fonts = pubspecContent['flutter']['fonts'] as YamlList?;
      expect(fonts, isNotNull);

      final requiredFonts = ['Roboto', 'OpenSans'];
      for (final font in fonts!) {
        expect(requiredFonts.contains(font['family']), isTrue);
      }
    });
  });

  group('Environment Configuration Tests', () {
    test('.env files exist', () {
      final envFiles = [
        '.env',
        '.env.development',
        '.env.staging',
        '.env.production',
      ];

      for (final file in envFiles) {
        expect(File(file).existsSync(), isTrue);
      }
    });

    test('Environment variables are properly formatted', () {
      final envFile = File('.env');
      final content = envFile.readAsStringSync();
      final lines = content.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty || line.startsWith('#')) continue;
        expect(line, matches(r'^\w+=.+$'));
      }
    });
  });

  group('Build Configuration Tests', () {
    test('Android build configuration', () {
      final buildGradleFile = File('android/app/build.gradle');
      expect(buildGradleFile.existsSync(), isTrue);

      final content = buildGradleFile.readAsStringSync();
      expect(content.contains('applicationId "com.example.ehr_blockchain"'), isTrue);
      expect(content.contains('minSdkVersion'), isTrue);
      expect(content.contains('targetSdkVersion'), isTrue);
    });

    test('iOS build configuration', () {
      final podfileFile = File('ios/Podfile');
      expect(podfileFile.existsSync(), isTrue);

      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue);
    });
  });

  group('Git Configuration Tests', () {
    test('.gitignore configuration', () {
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue);

      final content = gitignoreFile.readAsStringSync();
      final requiredEntries = [
        '.dart_tool/',
        '.flutter-plugins',
        'build/',
        '.env',
        '*.g.dart',
      ];

      for (final entry in requiredEntries) {
        expect(content.contains(entry), isTrue);
      }
    });

    test('Git hooks exist', () {
      final hooksDir = Directory('.git/hooks');
      expect(hooksDir.existsSync(), isTrue);

      final preCommitHook = File('.git/hooks/pre-commit');
      expect(preCommitHook.existsSync(), isTrue);
    });
  });

  group('CI/CD Configuration Tests', () {
    test('GitHub Actions workflow configuration', () {
      final workflowFile = File('.github/workflows/main.yml');
      expect(workflowFile.existsSync(), isTrue);

      final content = loadYaml(workflowFile.readAsStringSync());
      expect(content['name'], isNotNull);
      expect(content['on'], isNotNull);
      expect(content['jobs'], isNotNull);
    });

    test('Firebase configuration', () {
      final firebaseConfigFile = File('android/app/google-services.json');
      expect(firebaseConfigFile.existsSync(), isTrue);

      final iosFirebaseConfigFile = File('ios/Runner/GoogleService-Info.plist');
      expect(iosFirebaseConfigFile.existsSync(), isTrue);
    });
  });
}
