import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/features/explore/domain/post.dart';

void main() {
  test('community kinds map to the supported post storage types', () {
    expect(CommunityPostKind.standard.storageType, PostType.renovationUpdate);
    expect(CommunityPostKind.beforeAfter.storageType, PostType.projectShowcase);
    expect(CommunityPostKind.question.storageType, PostType.tip);
    expect(CommunityPostKind.question.categoryMarker, 'question');
  });

  test('unknown route values fall back to a standard community post', () {
    expect(
      CommunityPostKind.fromQuery('not-a-kind'),
      CommunityPostKind.standard,
    );
    expect(CommunityPostKind.fromQuery('question'), CommunityPostKind.question);
  });

  test('question marker is exposed on hydrated posts', () {
    final post = Post(
      id: 'post-id',
      authorId: 'author-id',
      authorRole: 'homeowner',
      postType: PostType.tip,
      caption: 'هل اللون مناسب؟',
      category: 'question',
      createdAt: DateTime(2026, 1, 1),
    );

    expect(post.isQuestion, isTrue);
  });
}
