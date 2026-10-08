import 'package:fittrack/models/app_user.dart';
import 'package:fittrack/repositories/user_repository.dart';

/// Scriptable [UserRepository] double.
///
/// Nothing here touches Firebase: the profile "server" is a local map, and
/// every failure or delay is controlled through the public flags below.
class FakeUserRepository implements UserRepository {
  final Map<String, AppUser> store = <String, AppUser>{};
  final List<String> getCalls = <String>[];
  final List<AppUser> created = <AppUser>[];
  final List<AppUser> updated = <AppUser>[];

  bool configured = true;
  bool failGet = false;
  bool failWrite = false;
  Duration getDelay = Duration.zero;
  Duration writeDelay = Duration.zero;

  @override
  bool get isConfigured => configured;

  @override
  Future<AppUser?> get(String uid) async {
    getCalls.add(uid);
    if (getDelay > Duration.zero) {
      await Future<void>.delayed(getDelay);
    }
    if (failGet) throw StateError('fake get failure');
    return store[uid];
  }

  @override
  Future<void> createIfMissing(AppUser user) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrite) throw StateError('fake write failure');
    created.add(user);
    store.putIfAbsent(user.uid, () => user);
  }

  @override
  Future<void> update(AppUser user) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrite) throw StateError('fake write failure');
    updated.add(user);
    store[user.uid] = user;
  }
}
