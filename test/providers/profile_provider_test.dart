import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/app_user.dart';
import 'package:fittrack/models/fitness_goal.dart';
import 'package:fittrack/providers/profile_provider.dart';

import '../fakes/profile_fakes.dart';

void main() {
  late FakeUserRepository repo;
  late ProfileProvider provider;

  AppUser existingProfile({String uid = 'u1'}) {
    return AppUser(
      uid: uid,
      email: 'ada@example.com',
      displayName: 'Ada',
      height: 170,
      weight: 60,
      fitnessGoal: FitnessGoal.endurance,
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2020, 1, 1),
    );
  }

  setUp(() {
    repo = FakeUserRepository();
    provider = ProfileProvider(repository: repo);
  });

  tearDown(() {
    provider.dispose();
  });

  group('load', () {
    test('reads the signed-in member profile', () async {
      repo.store['u1'] = existingProfile();

      await provider.load(uid: 'u1');

      expect(repo.getCalls, <String>['u1']);
      expect(provider.profile?.displayName, 'Ada');
      expect(provider.profile?.fitnessGoal, FitnessGoal.endurance);
      expect(provider.uid, 'u1');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(repo.created, isEmpty);
    });

    test('seeds the document when it does not exist yet (registration)', () async {
      await provider.load(
        uid: 'u2',
        email: 'newbie@example.com',
        displayName: 'Newbie',
      );

      expect(repo.getCalls, <String>['u2']);
      expect(repo.created, hasLength(1));
      expect(repo.created.single.uid, 'u2');
      expect(repo.created.single.email, 'newbie@example.com');
      expect(repo.created.single.displayName, 'Newbie');
      expect(repo.created.single.createdAt, isNotNull);
      expect(provider.profile?.uid, 'u2');
      expect(provider.errorMessage, isNull);
      expect(repo.updated, isEmpty);
    });

    test('reports the loading state while the repository works', () async {
      repo.getDelay = const Duration(milliseconds: 40);

      final Future<void> pending = provider.load(uid: 'u1');
      expect(provider.isLoading, isTrue);

      await pending;
      expect(provider.isLoading, isFalse);
      expect(provider.profile, isNotNull);
    });

    test('surfaces a repository failure without throwing', () async {
      repo.failGet = true;

      await provider.load(uid: 'u1');

      expect(provider.errorMessage, 'Something went wrong. Please try again.');
      expect(provider.profile, isNull);
      expect(provider.isLoading, isFalse);
      expect(repo.created, isEmpty);
    });

    test('stays quiet when Firebase is not configured', () async {
      repo.configured = false;

      await provider.load(uid: 'u1', email: 'someone@example.com');

      expect(provider.isConfigured, isFalse);
      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
      expect(repo.getCalls, isEmpty);
      expect(repo.created, isEmpty);
    });

    test('clearError clears a reported failure', () async {
      repo.failGet = true;
      await provider.load(uid: 'u1');
      expect(provider.errorMessage, isNotNull);

      repo.failGet = false;
      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });

  group('save', () {
    test('writes the edited values and reports success', () async {
      repo.store['u1'] = existingProfile();
      await provider.load(uid: 'u1');

      final bool saved = await provider.save(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: '  Ada Lifts  ',
        height: 171.5,
        weight: 61,
        fitnessGoal: FitnessGoal.strength,
      );

      expect(saved, isTrue);
      expect(repo.updated, hasLength(1));
      final AppUser written = repo.updated.single;
      expect(written.uid, 'u1');
      expect(written.displayName, 'Ada Lifts');
      expect(written.height, 171.5);
      expect(written.weight, 61);
      expect(written.fitnessGoal, FitnessGoal.strength);
      expect(written.createdAt, DateTime(2020, 1, 1));
      expect(written.updatedAt!.isAfter(DateTime(2021)), isTrue);

      expect(provider.profile?.displayName, 'Ada Lifts');
      expect(provider.profile?.fitnessGoal, FitnessGoal.strength);
      expect(provider.successMessage, 'Profile updated.');
      expect(provider.errorMessage, isNull);
      expect(provider.isSaving, isFalse);
    });

    test('reports the saving state while the write is in flight', () async {
      repo.store['u1'] = existingProfile();
      await provider.load(uid: 'u1');
      repo.writeDelay = const Duration(milliseconds: 40);

      final Future<bool> pending = provider.save(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: 'Ada',
        height: 170,
        weight: 60,
        fitnessGoal: FitnessGoal.generalFitness,
      );
      expect(provider.isSaving, isTrue);

      final bool saved = await pending;
      expect(saved, isTrue);
      expect(provider.isSaving, isFalse);
    });

    test('creates the document when no profile has been loaded', () async {
      final bool saved = await provider.save(
        uid: 'u7',
        email: 'fresh@example.com',
        displayName: 'Fresh Start',
        height: null,
        weight: null,
        fitnessGoal: FitnessGoal.flexibility,
      );

      expect(saved, isTrue);
      expect(repo.created, hasLength(1));
      expect(repo.created.single.height, isNull);
      expect(repo.updated, isEmpty);
      expect(provider.profile?.createdAt, isNotNull);
    });

    test('keeps the previous profile and reports a write failure', () async {
      repo.store['u1'] = existingProfile();
      await provider.load(uid: 'u1');
      repo.failWrite = true;

      final bool saved = await provider.save(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: 'Should Not Persist',
        height: 180,
        weight: 90,
        fitnessGoal: FitnessGoal.strength,
      );

      expect(saved, isFalse);
      expect(repo.updated, isEmpty);
      expect(provider.errorMessage, 'Something went wrong. Please try again.');
      expect(provider.successMessage, isNull);
      expect(provider.profile?.displayName, 'Ada');
      expect(provider.isSaving, isFalse);
    });

    test('refuses to save when Firebase is not configured', () async {
      repo.configured = false;

      final bool saved = await provider.save(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: 'Ada',
        height: 170,
        weight: 60,
        fitnessGoal: FitnessGoal.strength,
      );

      expect(saved, isFalse);
      expect(provider.errorMessage,
          contains('Firebase is not configured yet'));
      expect(repo.updated, isEmpty);
      expect(repo.created, isEmpty);
      expect(provider.isSaving, isFalse);
    });

    test('clearSuccess clears the success message', () async {
      await provider.save(
        uid: 'u1',
        email: 'ada@example.com',
        displayName: 'Ada',
        height: 170,
        weight: 60,
        fitnessGoal: FitnessGoal.strength,
      );
      expect(provider.successMessage, isNotNull);

      provider.clearSuccess();

      expect(provider.successMessage, isNull);
    });
  });
}
