import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/app_user.dart';
import 'package:fittrack/models/fitness_goal.dart';

void main() {
  group('AppUser serialization', () {
    test('toMap carries every profile contract field', () {
      final DateTime stamp = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final AppUser user = AppUser(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: 'Ada Lifts',
        height: 172.5,
        weight: 61,
        fitnessGoal: FitnessGoal.strength,
        createdAt: stamp,
        updatedAt: stamp,
      );

      final Map<String, dynamic> map = user.toMap();

      expect(
        map.keys,
        containsAll(<String>[
          'uid',
          'email',
          'displayName',
          'height',
          'weight',
          'fitnessGoal',
          'createdAt',
          'updatedAt',
        ]),
      );
      expect(map['uid'], 'u1');
      expect(map['height'], 172.5);
      expect(map['fitnessGoal'], 'Strength');
    });

    test('round-trips through fromMap', () {
      final DateTime created = DateTime.utc(2026, 3, 1, 8, 30);
      final AppUser original = AppUser(
        uid: 'u2',
        email: 'ada@example.com',
        displayName: 'Ada Lifts',
        height: 170,
        weight: 60.5,
        fitnessGoal: FitnessGoal.flexibility,
        createdAt: created,
        updatedAt: created,
      );

      final AppUser restored = AppUser.fromMap(original.uid, original.toMap());

      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.height, original.height);
      expect(restored.weight, original.weight);
      expect(restored.fitnessGoal, original.fitnessGoal);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('reads a document that only has the auth basics', () {
      final AppUser user = AppUser.fromMap('u9', <String, dynamic>{
        'email': 'fresh@example.com',
      });

      expect(user.uid, 'u9');
      expect(user.email, 'fresh@example.com');
      expect(user.displayName, '');
      expect(user.height, isNull);
      expect(user.weight, isNull);
      expect(user.fitnessGoal, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('coerces integer height and weight from Firestore', () {
      final AppUser user = AppUser.fromMap('u1', <String, dynamic>{
        'height': 180,
        'weight': 75,
      });

      expect(user.height, 180.0);
      expect(user.weight, 75.0);
    });

    test('parses the stored fitness goal label', () {
      expect(
        AppUser.fromMap('u1', <String, dynamic>{'fitnessGoal': 'Endurance'})
            .fitnessGoal,
        FitnessGoal.endurance,
      );
      expect(
        AppUser.fromMap('u1', <String, dynamic>{'fitnessGoal': 'Strength'})
            .fitnessGoal,
        FitnessGoal.strength,
      );
    });

    test('never invents a fitness goal from a bad value', () {
      expect(
        AppUser.fromMap('u1', <String, dynamic>{'fitnessGoal': 'Powerlifting'})
            .fitnessGoal,
        isNull,
      );
      expect(
        AppUser.fromMap('u1', <String, dynamic>{'fitnessGoal': null})
            .fitnessGoal,
        isNull,
      );
      expect(
        AppUser.fromMap('u1', <String, dynamic>{}).fitnessGoal,
        isNull,
      );
    });

    test('reads timestamps written as DateTime or ISO strings', () {
      final DateTime stamp = DateTime.utc(2026, 5, 4);

      final AppUser fromDateTime = AppUser.fromMap('u1', <String, dynamic>{
        'createdAt': stamp,
      });
      final AppUser fromString = AppUser.fromMap('u1', <String, dynamic>{
        'createdAt': stamp.toIso8601String(),
      });

      expect(fromDateTime.createdAt, stamp);
      expect(fromString.createdAt, stamp);
    });

    test('the caller uid wins over the document payload', () {
      final AppUser user = AppUser.fromMap('authenticated-uid', <String, dynamic>{
        'uid': 'someone-else',
      });

      expect(user.uid, 'authenticated-uid');
    });
  });

  group('FitnessGoal', () {
    test('offers exactly the five supported goals', () {
      expect(
        FitnessGoal.values.map((FitnessGoal goal) => goal.label).toList(),
        <String>[
          'General Fitness',
          'Weight Management',
          'Strength',
          'Endurance',
          'Flexibility',
        ],
      );
    });

    test('fromValue accepts labels and enum names, rejects unknown input', () {
      expect(FitnessGoal.fromValue('Weight Management'),
          FitnessGoal.weightManagement);
      expect(FitnessGoal.fromValue('strength'), FitnessGoal.strength);
      expect(FitnessGoal.fromValue('powerlifting'), isNull);
      expect(FitnessGoal.fromValue(''), isNull);
      expect(FitnessGoal.fromValue(42), isNull);
      expect(FitnessGoal.fromValue(null), isNull);
    });
  });
}
