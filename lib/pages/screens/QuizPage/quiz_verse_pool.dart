/// Verses loaded for quiz generation.
///
/// For large ranges we sample anchors and fetch each with neighbours, so
/// [anchorIndices] marks indices that are real question targets. [anchorsWithPrev]
/// / [anchorsWithNext] record true adjacency within each sampled window (so we
/// never treat the next window's ayah as a neighbour).
///
/// When [anchorIndices] is null, [verses] is a contiguous range and normal
/// index adjacency applies.
class QuizVersePool {
  const QuizVersePool({
    required this.verses,
    this.anchorIndices,
    this.anchorsWithPrev = const {},
    this.anchorsWithNext = const {},
  });

  final List<dynamic> verses;

  /// Safe primary indices into [verses]. Null means every index may be used
  /// (subject to normal per-type eligibility).
  final Set<int>? anchorIndices;

  final Set<int> anchorsWithPrev;
  final Set<int> anchorsWithNext;

  int get effectiveVerseCount => anchorIndices?.length ?? verses.length;
}
