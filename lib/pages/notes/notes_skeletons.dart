import 'package:flutter/material.dart';

/// Content-shaped loading placeholders for Notes/Feed/Friends/comments,
/// replacing the old bare centered spinner. Each skeleton's layout mirrors
/// the real widget it stands in for (see `note_list_tile.dart`,
/// `feed_item_card.dart`, `friends_tab.dart`) so the swap from loading to
/// loaded doesn't jump around.

/// Sweeps a soft highlight across [child] on a loop. [child] should be built
/// from solid [_SkeletonBox]es - the sweep is a moving gradient rendered
/// with [BlendMode.srcATop], so it reads as a highlight passing over solid
/// shapes rather than anything being redrawn.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              cs.surfaceContainerHigh,
              cs.surfaceContainerHighest,
              cs.surfaceContainerHigh,
            ],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment(-1 - 2 * t, 0),
            end: Alignment(1 - 2 * t, 0),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

Widget _skeletonCard({
  required ColorScheme cs,
  required double borderRadius,
  required Widget child,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
    ),
    child: child,
  );
}

class _NoteTileSkeleton extends StatelessWidget {
  const _NoteTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _skeletonCard(
      cs: cs,
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _SkeletonBox(height: 16)),
                const SizedBox(width: 12),
                _SkeletonBox(width: 24, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 10),
            const _SkeletonBox(width: 90, height: 11),
            const SizedBox(height: 10),
            const _SkeletonBox(height: 13),
            const SizedBox(height: 6),
            const _SkeletonBox(width: 160, height: 13),
          ],
        ),
      ),
    );
  }
}

/// Stands in for `notes_page.dart`'s `NoteListTile` list while notes load.
class NotesListSkeleton extends StatelessWidget {
  const NotesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _NoteTileSkeleton(),
      ),
    );
  }
}

class _FeedItemSkeleton extends StatelessWidget {
  const _FeedItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _skeletonCard(
      cs: cs,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SkeletonBox(width: 32, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBox(width: 100, height: 13),
                      SizedBox(height: 6),
                      _SkeletonBox(width: 70, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SkeletonBox(width: 180, height: 15),
            const SizedBox(height: 8),
            const _SkeletonBox(height: 13),
            const SizedBox(height: 6),
            const _SkeletonBox(width: 220, height: 13),
            const SizedBox(height: 12),
            Row(
              children: [
                _SkeletonBox(width: 24, height: 24, borderRadius: 12),
                const SizedBox(width: 6),
                const _SkeletonBox(width: 20, height: 11),
                const SizedBox(width: 16),
                _SkeletonBox(width: 24, height: 24, borderRadius: 12),
                const SizedBox(width: 6),
                const _SkeletonBox(width: 20, height: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for `feed_page.dart`'s `FeedItemCard` list while the feed loads.
class FeedListSkeleton extends StatelessWidget {
  const FeedListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _FeedItemSkeleton(),
      ),
    );
  }
}

class _AvatarRowSkeleton extends StatelessWidget {
  const _AvatarRowSkeleton({this.withSubtitle = false});

  final bool withSubtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const _SkeletonBox(width: 36, height: 36, borderRadius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBox(width: 120, height: 13),
                if (withSubtitle) ...[
                  const SizedBox(height: 6),
                  const _SkeletonBox(width: 90, height: 11),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionCardSkeleton(
  ColorScheme cs, {
  required double titleWidth,
  required List<Widget> rows,
}) {
  return _skeletonCard(
    cs: cs,
    borderRadius: 16,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: titleWidth, height: 15),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    ),
  );
}

/// Stands in for `friends_tab.dart`'s three section cards (search, incoming
/// requests, friends) while friends/requests load.
class FriendsTabSkeleton extends StatelessWidget {
  const FriendsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _sectionCardSkeleton(
            cs,
            titleWidth: 160,
            rows: const [_SkeletonBox(height: 44, borderRadius: 12)],
          ),
          const SizedBox(height: 12),
          _sectionCardSkeleton(
            cs,
            titleWidth: 140,
            rows: const [
              _AvatarRowSkeleton(),
              _AvatarRowSkeleton(),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCardSkeleton(
            cs,
            titleWidth: 100,
            rows: const [
              _AvatarRowSkeleton(withSubtitle: true),
              _AvatarRowSkeleton(withSubtitle: true),
              _AvatarRowSkeleton(withSubtitle: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentRowSkeleton extends StatelessWidget {
  const _CommentRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 28, height: 28, borderRadius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(width: 80, height: 12),
                SizedBox(height: 6),
                _SkeletonBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _SkeletonBox(width: 30, height: 11),
        ],
      ),
    );
  }
}

/// Stands in for `feed_post_detail_page.dart`'s inline comment list while
/// comments load.
class CommentsListSkeleton extends StatelessWidget {
  const CommentsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Shimmer(
      child: Column(
        children: [
          _CommentRowSkeleton(),
          _CommentRowSkeleton(),
          _CommentRowSkeleton(),
        ],
      ),
    );
  }
}

class _AvatarSectionSkeleton extends StatelessWidget {
  const _AvatarSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _skeletonCard(
      cs: cs,
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const _SkeletonBox(width: 88, height: 88, borderRadius: 44),
            const SizedBox(height: 12),
            const _SkeletonBox(width: 100, height: 16),
            const SizedBox(height: 12),
            _SkeletonBox(width: 180, height: 40, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// Stands in for `notes_profile_page.dart`'s avatar/username/password
/// sections while the profile loads.
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const _AvatarSectionSkeleton(),
          const SizedBox(height: 14),
          _sectionCardSkeleton(
            cs,
            titleWidth: 90,
            rows: const [
              _SkeletonBox(height: 48, borderRadius: 14),
              SizedBox(height: 12),
              _SkeletonBox(width: 140, height: 40, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCardSkeleton(
            cs,
            titleWidth: 110,
            rows: const [
              _SkeletonBox(height: 48, borderRadius: 14),
              SizedBox(height: 10),
              _SkeletonBox(height: 48, borderRadius: 14),
              SizedBox(height: 12),
              _SkeletonBox(width: 140, height: 40, borderRadius: 14),
            ],
          ),
        ],
      ),
    );
  }
}
