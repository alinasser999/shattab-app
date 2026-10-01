/// The shared specialty taxonomy.
///
/// Wire keys are deliberately kept here, away from presentation code. A child
/// specialty is a display detail; matching and filters use its root instead.
class SpecialtyDefinition {
  const SpecialtyDefinition({required this.key, this.children = const []});

  final String key;
  final List<String> children;

  bool get hasChildren => children.isNotEmpty;
}

class SpecialtyCatalog {
  const SpecialtyCatalog._();

  /// Stable order for onboarding, requests, discovery and admin displays.
  static const List<SpecialtyDefinition> roots = [
    SpecialtyDefinition(key: 'paint'),
    SpecialtyDefinition(
      key: 'flooring',
      children: ['flooring:ceramic', 'flooring:porcelain'],
    ),
    SpecialtyDefinition(key: 'kitchen'),
    SpecialtyDefinition(key: 'bathroom'),
    SpecialtyDefinition(key: 'electrical'),
    SpecialtyDefinition(key: 'plumbing'),
    SpecialtyDefinition(key: 'carpentry'),
    SpecialtyDefinition(key: 'design'),
    SpecialtyDefinition(key: 'full_reno'),
    SpecialtyDefinition(key: 'plastering'),
    SpecialtyDefinition(key: 'gypsum_board'),
    SpecialtyDefinition(key: 'marble_granite'),
    SpecialtyDefinition(key: 'aluminum_upvc'),
    SpecialtyDefinition(key: 'hvac'),
  ];

  /// Curated short-list order for compact home/discovery rails. The complete
  /// catalog above remains the source for forms and filters.
  static const List<String> popularRootKeys = [
    'full_reno',
    'design',
    'paint',
    'electrical',
    'plumbing',
  ];

  static final Map<String, String> _childParents = {
    for (final root in roots)
      for (final child in root.children) child: root.key,
  };

  static final Set<String> _rootKeys = {for (final root in roots) root.key};

  static String rootKeyFor(String value) {
    final trimmed = value.trim();
    return _childParents[trimmed] ?? trimmed;
  }

  static bool isRoot(String value) => _rootKeys.contains(value.trim());

  static List<String> childrenFor(String rootKey) {
    final key = rootKey.trim();
    for (final root in roots) {
      if (root.key == key) return root.children;
    }
    return const [];
  }

  /// Returns stored values in a stable, database-compatible order:
  /// primary/root values first, then known child details, then unknown legacy
  /// values. Unknown values are preserved so an old account is not rewritten
  /// destructively while the client learns about newer catalog entries.
  static List<String> normalizeSelection(
    Iterable<String> values, {
    String? primary,
  }) {
    final knownRoots = <String>[];
    final knownChildren = <String>[];
    final unknown = <String>[];
    final seenRoots = <String>{};
    final seenChildren = <String>{};
    final seenUnknown = <String>{};

    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final parent = _childParents[value];
      if (parent != null) {
        if (seenChildren.add(value)) knownChildren.add(value);
        // Treat the parent as selected at the child's position. This keeps
        // the first logical choice primary even when restoring a child-only
        // or hand-authored legacy array.
        if (seenRoots.add(parent)) knownRoots.add(parent);
      } else if (_rootKeys.contains(value)) {
        if (seenRoots.add(value)) knownRoots.add(value);
      } else if (seenUnknown.add(value)) {
        unknown.add(value);
      }
    }

    final primaryRoot = primary == null ? null : rootKeyFor(primary);
    if (primaryRoot != null && seenRoots.contains(primaryRoot)) {
      knownRoots
        ..remove(primaryRoot)
        ..insert(0, primaryRoot);
    }

    // Children follow their catalog order, which makes a restored selection
    // deterministic even when an older client wrote them in another order.
    final children = <String>[
      for (final root in roots)
        for (final child in root.children)
          if (seenChildren.contains(child)) child,
    ];
    return [...knownRoots, ...children, ...unknown];
  }

  /// Projects any stored selection to root semantics for matching and query
  /// parameters. Unknown values are retained as opaque legacy roots.
  static List<String> rootKeys(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final root = rootKeyFor(value);
      if (seen.add(root)) result.add(root);
    }
    return result;
  }

  /// Values safe to send to a legacy array-overlap query. Roots are always
  /// included, and known children are included too so a pre-normalization row
  /// that stored only `flooring:ceramic` still matches a `flooring` request.
  static List<String> matchingKeys(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final root in rootKeys(values)) {
      if (seen.add(root)) result.add(root);
      for (final child in childrenFor(root)) {
        if (seen.add(child)) result.add(child);
      }
    }
    return result;
  }

  static List<String> knownRootKeys(Iterable<String> values) => [
    for (final key in rootKeys(values))
      if (_rootKeys.contains(key)) key,
  ];
}
