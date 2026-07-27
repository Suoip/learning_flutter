import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_forum_post_form_page.dart';
import 'educator_video_form_page.dart';

/// Post-login landing page for educators: lists the signed-in educator's
/// own SmartAcademy content - video entries (title/description/
/// duration-label metadata only, no real video file upload exists yet) and
/// forum posts (title/body text) - each as its own section with
/// independent create/edit/delete. Scoped entirely to the educator's
/// private dashboard; the public SmartAcademy hub page keeps showing its
/// own static sample data (see smart_academy_entry.dart) until a later PR
/// wires real authored content into it.
class EducatorDashboardPage extends StatefulWidget {
  const EducatorDashboardPage({
    super.key,
    required this.username,
    required this.onSignOut,
  });

  final String username;
  final Future<void> Function() onSignOut;

  @override
  State<EducatorDashboardPage> createState() => _EducatorDashboardPageState();
}

class _EducatorDashboardPageState extends State<EducatorDashboardPage> {
  final EducatorLogic _logic = EducatorLogic();

  List<EducatorVideoItem> _videos = [];
  bool _loadingVideos = true;
  String? _videosError;

  List<ForumPostItem> _posts = [];
  bool _loadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadForumPosts();
  }

  Future<void> _refreshAll() {
    return Future.wait([_loadVideos(), _loadForumPosts()]);
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loadingVideos = true;
      _videosError = null;
    });

    try {
      final videos = await _logic.fetchVideosForCurrentEducator();
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
          fallback: 'Could not load your videos.',
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
      final posts = await _logic.fetchForumPostsForCurrentEducator();
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
          fallback: 'Could not load your forum posts.',
        );
      });
    }
  }

  Future<void> _createVideo() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EducatorVideoFormPage()),
    );
    if (changed == true) await _loadVideos();
  }

  Future<void> _editVideo(EducatorVideoItem video) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EducatorVideoFormPage(video: video),
      ),
    );
    if (changed == true) await _loadVideos();
  }

  Future<void> _createForumPost() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EducatorForumPostFormPage()),
    );
    if (changed == true) await _loadForumPosts();
  }

  Future<void> _editForumPost(ForumPostItem post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EducatorForumPostFormPage(post: post),
      ),
    );
    if (changed == true) await _loadForumPosts();
  }

  Widget _buildSectionHeader({
    required String title,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const Spacer(),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(buttonLabel),
        ),
      ],
    );
  }

  Widget _buildVideosSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget content;
    if (_loadingVideos) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_videosError != null) {
      content = Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load videos:\n$_videosError',
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      );
    } else if (_videos.isEmpty) {
      content = Card(
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.video_library_outlined, size: 40, color: cs.primary),
              const SizedBox(height: 12),
              Text('No videos yet', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Create your first video entry to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    } else {
      content = Column(
        children: [
          for (final video in _videos) ...[
            _EducatorVideoTile(
              video: video,
              onTap: () => _editVideo(video),
            ),
            if (video != _videos.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Videos',
          buttonLabel: 'New Video',
          onPressed: _createVideo,
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildForumPostsSection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget content;
    if (_loadingPosts) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_postsError != null) {
      content = Card(
        color: cs.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load forum posts:\n$_postsError',
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      );
    } else if (_posts.isEmpty) {
      content = Card(
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.forum_outlined, size: 40, color: cs.tertiary),
              const SizedBox(height: 12),
              Text('No forum posts yet', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Create your first forum post to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    } else {
      content = Column(
        children: [
          for (final post in _posts) ...[
            _EducatorForumPostTile(
              post: post,
              onTap: () => _editForumPost(post),
            ),
            if (post != _posts.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Forum Posts',
          buttonLabel: 'New Post',
          onPressed: _createForumPost,
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text("${widget.username}'s Dashboard"),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideosSection(),
                const SizedBox(height: 32),
                _buildForumPostsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EducatorVideoTile extends StatelessWidget {
  const _EducatorVideoTile({required this.video, required this.onTap});

  final EducatorVideoItem video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title.isEmpty ? '(untitled)' : video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (video.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (video.durationLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              video.durationLabel!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Updated ${EducatorLogic.formatUpdatedTime(video.updatedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducatorForumPostTile extends StatelessWidget {
  const _EducatorForumPostTile({required this.post, required this.onTap});

  final ForumPostItem post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
                    Text(
                      post.title.isEmpty ? '(untitled)' : post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (post.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Updated ${EducatorLogic.formatUpdatedTime(post.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
