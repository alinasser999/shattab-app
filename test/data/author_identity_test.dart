import 'package:batsh/features/explore/data/post_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the step that attaches an author's name to a post.
///
/// The saved-posts and author-profile reads used to issue one identity RPC per
/// row inside a `Future.wait`; they now fetch once per distinct author and map
/// the results back. That mapping is the part worth testing: get it wrong and
/// the failure is not a crash but the wrong person's name and avatar appearing
/// on someone else's post — a privacy problem that looks like a rendering
/// quirk.
void main() {
  Map<String, dynamic> row(
    String id,
    String authorId,
    String role, {
    String? name,
  }) => {
    'id': id,
    'author_id': authorId,
    'author_role': role,
    'profiles': name == null ? null : {'full_name': name},
  };

  group('authorIdentityKey', () {
    test('separates the same uuid under different roles', () {
      // A uuid can be resolved through two projections. Keying on the id alone
      // would let a contractor-facing identity satisfy a homeowner-facing row.
      expect(
        authorIdentityKey('u1', 'contractor'),
        isNot(authorIdentityKey('u1', 'homeowner')),
      );
    });
  });

  group('applyAuthorIdentities', () {
    test('fills only the rows that were missing a name', () {
      final rows = [
        row('p1', 'u1', 'contractor'),
        row('p2', 'u2', 'homeowner', name: 'Existing Name'),
      ];
      final result = applyAuthorIdentities(rows, {
        authorIdentityKey('u1', 'contractor'): {'full_name': 'Fetched Name'},
        authorIdentityKey('u2', 'homeowner'): {'full_name': 'Should Not Win'},
      });

      expect(result[0]['profiles']['full_name'], 'Fetched Name');
      // A row that arrived with a name keeps it; the embed is authoritative.
      expect(result[1]['profiles']['full_name'], 'Existing Name');
    });

    test('never puts one author identity on another author row', () {
      final rows = [
        row('p1', 'u1', 'contractor'),
        row('p2', 'u2', 'contractor'),
      ];
      final result = applyAuthorIdentities(rows, {
        authorIdentityKey('u1', 'contractor'): {'full_name': 'Author One'},
        authorIdentityKey('u2', 'contractor'): {'full_name': 'Author Two'},
      });

      expect(result[0]['profiles']['full_name'], 'Author One');
      expect(result[1]['profiles']['full_name'], 'Author Two');
    });

    test('applies one identity to every row by that author', () {
      // The whole point of deduplicating the fetch: three posts by one author
      // are hydrated from a single lookup.
      final rows = [
        row('p1', 'u1', 'contractor'),
        row('p2', 'u1', 'contractor'),
        row('p3', 'u1', 'contractor'),
      ];
      final result = applyAuthorIdentities(rows, {
        authorIdentityKey('u1', 'contractor'): {'full_name': 'One Author'},
      });

      expect(
        result.map((r) => r['profiles']['full_name']),
        everyElement('One Author'),
      );
    });

    test('leaves a row untouched when the lookup found nothing', () {
      // Better a post with no name than a post wearing someone else's.
      final rows = [row('p1', 'u1', 'contractor')];
      final result = applyAuthorIdentities(rows, const {});
      expect(result.single['profiles'], isNull);
    });

    test('preserves order and length', () {
      final rows = [
        row('p1', 'u1', 'contractor'),
        row('p2', 'u2', 'homeowner', name: 'Kept'),
        row('p3', 'u3', 'contractor'),
      ];
      final result = applyAuthorIdentities(rows, {
        authorIdentityKey('u3', 'contractor'): {'full_name': 'Third'},
      });

      expect(result.length, 3);
      expect(result.map((r) => r['id']), ['p1', 'p2', 'p3']);
    });

    test('treats a blank name as missing', () {
      // An embed that returns an empty string is not an identity; it is RLS
      // having withheld one.
      final rows = [row('p1', 'u1', 'contractor', name: '   ')];
      final result = applyAuthorIdentities(rows, {
        authorIdentityKey('u1', 'contractor'): {'full_name': 'Real Name'},
      });
      expect(result.single['profiles']['full_name'], 'Real Name');
    });
  });

  group('applyFeedAuthorIdentities', () {
    test('fills missing public name and avatar fields', () {
      final rows = [
        {
          'id': 'p1',
          'author_id': 'u1',
          'author_role': 'homeowner',
          'author_name': null,
          'author_avatar_url': null,
        },
      ];

      final result = applyFeedAuthorIdentities(rows, {
        authorIdentityKey('u1', 'homeowner'): {
          'full_name': 'سارة أحمد',
          'avatar_url': 'https://cdn.example/avatar.jpg',
          'phone': '+201000000000',
        },
      });

      expect(result.single['author_name'], 'سارة أحمد');
      expect(
        result.single['author_avatar_url'],
        'https://cdn.example/avatar.jpg',
      );
      expect(result.single.containsKey('phone'), isFalse);
    });

    test('preserves supplied feed identity and isolates roles', () {
      final rows = [
        {
          'id': 'p1',
          'author_id': 'same-id',
          'author_role': 'contractor',
          'author_name': 'اسم من الخلاصة',
          'author_avatar_url': 'https://cdn.example/original.jpg',
        },
        {
          'id': 'p2',
          'author_id': 'same-id',
          'author_role': 'homeowner',
          'author_name': null,
          'author_avatar_url': null,
        },
      ];

      final result = applyFeedAuthorIdentities(rows, {
        authorIdentityKey('same-id', 'homeowner'): {
          'full_name': 'صاحب البيت',
          'avatar_url': 'https://cdn.example/homeowner.jpg',
        },
      });

      expect(result[0]['author_name'], 'اسم من الخلاصة');
      expect(
        result[0]['author_avatar_url'],
        'https://cdn.example/original.jpg',
      );
      expect(result[1]['author_name'], 'صاحب البيت');
      expect(
        result[1]['author_avatar_url'],
        'https://cdn.example/homeowner.jpg',
      );
    });
  });
}
