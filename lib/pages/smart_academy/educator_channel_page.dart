import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_profile_avatar.dart';
import 'expandable_text.dart';
import 'smart_academy_detail_page.dart';
import 'smart_academy_entry.dart';

/// A public, read-only view of one educator's profile and content -
/// reachable by anyone, including a fully signed-out visitor, via the hub's
/// educator-search box or an educator's own "View public profile" link on
/// their dashboard. Mirrors the hub's Videos/Forum two-section layout, but
/// each section loads independently (same rationale as
/// `EducatorDashboardPage`: one section erroring shouldn't block the other).
class EducatorChannelPage extends StatefulWidget {
  const EducatorChannelPage({super.key, required this.educatorId});

  final String educatorId;

  @override
  State<EducatorChannelPage> createState() => _EducatorChannelPageState();
}

class _EducatorChannelPageState extends State<EducatorChannelPage> {
  final EducatorLogic _logic = EducatorLogic();

  EducatorProfile? _profile;
  bool _loadingProfile = true;
  String? _profileError;

  List<EducatorVideoWithEngagement> _videos = [];
  bool _loadingVideos = true;
  String? _videosError;

  List<ForumPostWithEngagement> _posts = [];
  bool _loadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVideos();
    _loadForumPosts();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await _logic.fetchEducatorProfileById(widget.educatorId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load this educator.',
        );
      });
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loadingVideos = true;
      _videosError = null;
    });

    try {
      final videos = await _logic.fetchVideosWithEngagementForEducator(
        widget.educatorId,
      );
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loadingVideos = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingVideos = false;
        _videosError = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load videos.',
        );
      });
    }
  }

  Future<void> _loadForumPosts() async {
    setState(() {
      _loadingPosts = true;
      _postsError = null;
    });

    try {
      final posts = await _logic.fetchForumPostsWithEngagementForEducator(
        widget.educatorId,
      );
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loadingPosts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _postsError = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load forum posts.',
        );
      });
    }
  }

  void _openVideo(EducatorVideoWithEngagement item) {
    final profile = _profile;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartAcademyDetailPage(
          entry: SmartAcademyEntry(
            id: item.video.id,
            kind: SmartAcademyEntryKind.video,
            title: item.video.title,
            authorName: profile?.username ?? '',
            educatorId: widget.educatorId,
            description: item.video.description,
            durationLabel: item.video.durationLabel,
          ),
        ),
      ),
    );
  }

  void _openForumPost(ForumPostWithEngagement item) {
    final profile = _profile;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartAcademyDetailPage(
          entry: SmartAcademyEntry(
            id: item.post.id,
            kind: SmartAcademyEntryKind.forum,
            title: item.post.title,
            authorName: profile?.username ?? '',
            educatorId: widget.educatorId,
            description: item.post.description,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    if (_loadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileError != null) {
      return Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _profileError!,
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      );
    }

    final profile = _profile!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            EducatorProfileAvatar(
              username: profile.username,
              avatarUrl: profile.avatarUrl,
              radius: 44,
            ),
            const SizedBox(height: 12),
            Text(
              '@${profile.username}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection(ThemeData theme) {
    final cs = theme.colorScheme;

    Widget content;
    if (_loadingVideos) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_videosError != null) {
      content = Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _videosError!,
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      );
    } else if (_videos.isEmpty) {
      content = Card(
        color: cs.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text('No videos yet.'),
        ),
      );
    } else {
      content = Column(
        children: [
          for (final video in _videos) ...[
            _ChannelVideoTile(item: video, onTap: () => _openVideo(video)),
            if (video != _videos.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Videos', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildForumPostsSection(ThemeData theme) {
    final cs = theme.colorScheme;

    Widget content;
    if (_loadingPosts) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_postsError != null) {
      content = Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _postsError!,
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      );
    } else if (_posts.isEmpty) {
      content = Card(
        color: cs.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text('No forum posts yet.'),
        ),
      );
    } else {
      content = Column(
        children: [
          for (final post in _posts) ...[
            _ChannelForumPostTile(
              item: post,
              onTap: () => _openForumPost(post),
            ),
            if (post != _posts.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forum Posts', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Educator Channel'),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cs),
              const SizedBox(height: 24),
              _buildVideosSection(theme),
              const SizedBox(height: 32),
              _buildForumPostsSection(theme),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildPreviewEngagementRow(
  ColorScheme cs, {
  required bool isLiked,
  required int likeCount,
  required int commentCount,
}) {
  return Row(
    children: [
      Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 16,
        color: isLiked ? Colors.pink.shade500 : cs.onSurfaceVariant,
      ),
      const SizedBox(width: 4),
      Text('$likeCount', style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(width: 12),
      Icon(Icons.mode_comment_outlined, size: 16, color: cs.onSurfaceVariant),
      const SizedBox(width: 4),
      Text('$commentCount', style: TextStyle(color: cs.onSurfaceVariant)),
    ],
  );
}

class _ChannelVideoTile extends StatelessWidget {
  const _ChannelVideoTile({required this.item, required this.onTap});

  final EducatorVideoWithEngagement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final video = item.video;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        Icon(Icons.play_circle_fill_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(video.title,
                                  style: theme.textTheme.titleMedium),
                            ),
                            if (video.durationLabel != null) ...[
                              const SizedBox(width: 8),
                              Text(video.durationLabel!,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        ExpandableText(
                          text: video.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPreviewEngagementRow(
                cs,
                isLiked: item.isLikedByCurrentUser,
                likeCount: item.likeCount,
                commentCount: item.commentCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelForumPostTile extends StatelessWidget {
  const _ChannelForumPostTile({required this.item, required this.onTap});

  final ForumPostWithEngagement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final post = item.post;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.forum_rounded, color: cs.tertiary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        ExpandableText(
                          text: post.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPreviewEngagementRow(
                cs,
                isLiked: item.isLikedByCurrentUser,
                likeCount: item.likeCount,
                commentCount: item.commentCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
