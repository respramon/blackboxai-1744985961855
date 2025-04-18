import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/utils/validators.dart';
import 'package:ehr_blockchain/widgets/custom_text_field.dart';
import 'test_helpers.dart';

void main() {
  group('Input Validation Tests', () {
    test('Email validation', () {
      final validator = Validators.email;

      // Valid emails
      expect(validator('test@example.com'), isNull);
      expect(validator('user.name+tag@domain.co.uk'), isNull);

      // Invalid emails
      expect(validator(''), isNotNull);
      expect(validator('invalid'), isNotNull);
      expect(validator('test@'), isNotNull);
      expect(validator('@domain.com'), isNotNull);
      expect(validator('test@domain'), isNotNull);
    });

    test('Password validation', () {
      final validator = Validators.password;

      // Valid passwords
      expect(validator('Password123!'), isNull);
      expect(validator('Str0ng#Pass'), isNull);

      // Invalid passwords
      expect(validator(''), isNotNull);
      expect(validator('short'), isNotNull);
      expect(validator('nodigits'), isNotNull);
      expect(validator('no-uppercase'), isNotNull);
      expect(validator('NO-LOWERCASE'), isNotNull);
      expect(validator('NoSpecialChar1'), isNotNull);
    });

    test('Phone number validation', () {
      final validator = Validators.phone;

      // Valid phone numbers
      expect(validator('+1234567890'), isNull);
      expect(validator('123-456-7890'), isNull);

      // Invalid phone numbers
      expect(validator(''), isNotNull);
      expect(validator('123'), isNotNull);
      expect(validator('abcdefghij'), isNotNull);
    });

    test('Required field validation', () {
      final validator = Validators.required('Field is required');

      expect(validator('value'), isNull);
      expect(validator(''), 'Field is required');
      expect(validator(null), 'Field is required');
    });
  });

  group('Form Validation Tests', () {
    testWidgets('Login form validation', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: emailController,
                    validator: Validators.email,
                    label: 'Email',
                  ),
                  CustomTextField(
                    controller: passwordController,
                    validator: Validators.password,
                    label: 'Password',
                    isPassword: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test invalid form
      expect(formKey.currentState!.validate(), isFalse);

      // Test valid form
      emailController.text = 'test@example.com';
      passwordController.text = 'Password123!';
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('Registration form validation', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController();
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final confirmPasswordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: nameController,
                    validator: Validators.required('Name is required'),
                    label: 'Name',
                  ),
                  CustomTextField(
                    controller: emailController,
                    validator: Validators.email,
                    label: 'Email',
                  ),
                  CustomTextField(
                    controller: passwordController,
                    validator: Validators.password,
                    label: 'Password',
                    isPassword: true,
                  ),
                  CustomTextField(
                    controller: confirmPasswordController,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      passwordController.text,
                    ),
                    label: 'Confirm Password',
                    isPassword: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test invalid form
      expect(formKey.currentState!.validate(), isFalse);

      // Test valid form
      nameController.text = 'John Doe';
      emailController.text = 'john@example.com';
      passwordController.text = 'Password123!';
      confirmPasswordController.text = 'Password123!';
      expect(formKey.currentState!.validate(), isTrue);
    });
  });

  group('Custom Validation Tests', () {
    test('Ethereum address validation', () {
      final validator = Validators.ethereumAddress;

      // Valid addresses
      expect(validator('0x1234567890123456789012345678901234567890'), isNull);
      expect(validator('0xabcdef1234567890abcdef1234567890abcdef12'), isNull);

      // Invalid addresses
      expect(validator(''), isNotNull);
      expect(validator('0x123'), isNotNull);
      expect(validator('1234567890123456789012345678901234567890'), isNotNull);
      expect(validator('0xGHIJKL1234567890GHIJKL1234567890GHIJKL12'), isNotNull);
    });

    test('Medical record type validation', () {
      final validator = Validators.recordType;

      // Valid types
      expect(validator('PRESCRIPTION'), isNull);
      expect(validator('LAB_RESULT'), isNull);
      expect(validator('DIAGNOSIS'), isNull);

      // Invalid types
      expect(validator(''), isNotNull);
      expect(validator('INVALID_TYPE'), isNotNull);
    });

    test('Date validation', () {
      final validator = Validators.date;

      // Valid dates
      expect(validator('2023-08-15'), isNull);
      expect(validator('2023/08/15'), isNull);

      // Invalid dates
      expect(validator(''), isNotNull);
      expect(validator('2023-13-15'), isNotNull);
      expect(validator('2023-08-32'), isNotNull);
      expect(validator('invalid-date'), isNotNull);
    });
  });

  group('Form State Management Tests', () {
    testWidgets('Form field state updates', (WidgetTester tester) async {
      final controller = TextEditingController();
      String? fieldValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              onChanged: (value) => fieldValue = value,
              label: 'Test Field',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test value');
      expect(fieldValue, equals('test value'));
    });

    testWidgets('Form submission handling', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      bool formSubmitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              onChanged: () {
                if (formKey.currentState!.validate()) {
                  formSubmitted = true;
                }
              },
              child: CustomTextField(
                controller: TextEditingController(),
                validator: Validators.required('Required'),
                label: 'Test Field',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'valid input');
      expect(formSubmitted, isTrue);
    });
  });

  group('Error Message Tests', () {
    test('Validation error messages', () {
      expect(
        Validators.getErrorMessage('INVALID_EMAIL'),
        'Please enter a valid email address',
      );
      expect(
        Validators.getErrorMessage('INVALID_PASSWORD'),
        'Password must be at least 8 characters long and contain uppercase, lowercase, number and special character',
      );
      expect(
        Validators.getErrorMessage('REQUIRED_FIELD'),
        'This field is required',
      );
    });

    testWidgets('Error message display', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              validator: (_) => 'Error message',
              label: 'Test Field',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('Error message'), findsOneWidget);
    });
  });
}
