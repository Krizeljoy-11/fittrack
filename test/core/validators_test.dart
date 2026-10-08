import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/core/validators/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(Validators.required(null, field: 'Name'), 'Name is required.');
      expect(Validators.required('', field: 'Name'), 'Name is required.');
      expect(Validators.required('   ', field: 'Name'), 'Name is required.');
    });

    test('accepts a value and uses the field name in the message', () {
      expect(Validators.required('Push day', field: 'Routine'), isNull);
      expect(Validators.required(null), 'This field is required.');
    });
  });

  group('Validators.email', () {
    test('requires a value', () {
      expect(Validators.email(null), 'Email is required.');
      expect(Validators.email(''), 'Email is required.');
      expect(Validators.email('   '), 'Email is required.');
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('nope'), 'Enter a valid email address.');
      expect(Validators.email('nope@'), 'Enter a valid email address.');
      expect(Validators.email('nope@domain'), 'Enter a valid email address.');
      expect(Validators.email('a b@c.com'), 'Enter a valid email address.');
    });

    test('accepts valid addresses and trims surrounding spaces', () {
      expect(Validators.email('tester@example.com'), isNull);
      expect(Validators.email('  tester+tag@sub.example.co '), isNull);
    });
  });

  group('Validators.password', () {
    test('requires a value', () {
      expect(Validators.password(null), 'Password is required.');
      expect(Validators.password(''), 'Password is required.');
    });

    test('enforces the eight character minimum', () {
      expect(Validators.password('short1'), 'Password must be at least 8 characters.');
      expect(Validators.password('1234567'), 'Password must be at least 8 characters.');
    });

    test('accepts eight characters or more', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('longer-password'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('requires a value', () {
      expect(
        Validators.confirmPassword(null, 'secret123'),
        'Please confirm your password.',
      );
      expect(
        Validators.confirmPassword('', 'secret123'),
        'Please confirm your password.',
      );
    });

    test('detects mismatch and accepts a match', () {
      expect(
        Validators.confirmPassword('different', 'secret123'),
        'Passwords do not match.',
      );
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('requires a value', () {
      expect(Validators.displayName(null), 'Display name is required.');
      expect(Validators.displayName(''), 'Display name is required.');
      expect(Validators.displayName('   '), 'Display name is required.');
    });

    test('enforces a sensible length range', () {
      expect(
        Validators.displayName('A'),
        'Display name must be at least 2 characters.',
      );
      expect(
        Validators.displayName('x' * 51),
        'Display name must be 50 characters or fewer.',
      );
    });

    test('accepts a trimmed name', () {
      expect(Validators.displayName('Ada Lifts'), isNull);
      expect(Validators.displayName('  Ada  '), isNull);
      expect(Validators.displayName('Aa'), isNull);
    });
  });

  group('Validators.number', () {
    test('allows empty input by default', () {
      expect(Validators.number(null), isNull);
      expect(Validators.number('  '), isNull);
    });

    test('requires a value when allowEmpty is false', () {
      expect(
        Validators.number('', field: 'Height', allowEmpty: false),
        'Height is required.',
      );
    });

    test('rejects non-numeric input', () {
      expect(Validators.number('tall', field: 'Height'), 'Height must be a number.');
    });

    test('enforces min and max bounds inclusively', () {
      expect(Validators.number('160', field: 'Height', min: 50, max: 250), isNull);
      expect(
        Validators.number('49', field: 'Height', min: 50),
        'Height must be at least 50.0.',
      );
      expect(
        Validators.number('251', field: 'Height', max: 250),
        'Height must be at most 250.0.',
      );
    });
  });
}
