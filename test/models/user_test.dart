import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/models/user.dart';

void main() {
  group('User', () {
    const json = {
      'id': '65f1c0ffee',
      'name': 'Aung Aung',
      'email': 'aung@example.com',
      'role': 'admin',
      'isActive': true,
      'lastLoginAt': '2026-11-10T07:00:00.000Z',
      'createdAt': '2026-11-09T10:00:00.000Z',
      'updatedAt': '2026-11-10T07:00:00.000Z',
    };

    test('parses the API representation', () {
      final user = User.fromJson(json);

      expect(user.id, '65f1c0ffee');
      expect(user.name, 'Aung Aung');
      expect(user.email, 'aung@example.com');
      expect(user.isAdmin, isTrue);
      expect(user.lastLoginAt, DateTime.utc(2026, 11, 10, 7));
    });

    test('falls back to safe defaults for incomplete payloads', () {
      final user = User.fromJson(const {'_id': 'abc'});

      expect(user.id, 'abc');
      expect(user.name, isEmpty);
      expect(user.email, isEmpty);
      expect(user.role, UserRole.user);
      expect(user.isActive, isTrue);
      expect(user.lastLoginAt, isNull);
    });

    test('round-trips through toJson', () {
      final user = User.fromJson(json);
      final restored = User.fromJson(user.toJson());

      expect(restored, user);
    });

    test('derives initials for the avatar', () {
      expect(
        const User(id: '1', name: 'Aung Aung', email: 'a@b.com').initials,
        'AA',
      );
      expect(const User(id: '1', name: 'Aung', email: 'a@b.com').initials, 'A');
      expect(const User(id: '1', name: '', email: 'a@b.com').initials, '?');
    });
  });
}
