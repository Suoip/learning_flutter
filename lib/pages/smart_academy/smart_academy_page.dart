import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_dashboard_page.dart';
import 'educator_profile_avatar.dart';
import 'educator_search_bar.dart';
import 'smart_academy_activation_required_page.dart';
import 'smart_academy_auth_page.dart';
import 'smart_academy_detail_page.dart';
import 'smart_academy_entry.dart';
import 'smart_academy_hub_toolbar.dart';
import 'smart_academy_not_an_educator_page.dart';

/// SmartAcademy's main hub: a YouTube-style grid of real educator-authored
/// videos (metadata only, no file upload yet), plus a separate forum-style
/// section of real text-only posts, across ALL educators. Public/browsable
/// without an account; the AppBar action is the only entry point into
/// educator auth.
class SmartAcademyPage extends StatefulWidget {
  const SmartAcademyPage({super.key});

  @override
  State<SmartAcademyPage> createState() => _SmartAcademyPageState();
}

class _SmartAcademyPageState extends State<SmartAcademyPage> {
  final EducatorLogic _logic = EducatorLogic();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  SmartAcademyHubFilter _activeFilter = SmartAcademyHubFilter.all;

  List<SmartAcademyEntry> _videos = [];
  bool _loadingVideos = true;
  String? _videosError;

  List<SmartAcademyEntry> _posts = [];
  bool _loadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadVideos();
    _loadForumPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final videos = await _logic.fetchRecentVideos();
      if (!mounted) return;
      setState(() {
        _videos = videos.map((item) {
          return SmartAcademyEntry(
            id: item.video.id,
            kind: SmartAcademyEntryKind.video,
            title: item.video.title,
            authorName: item.authorUsername,
            authorAvatarUrl: item.authorAvatarUrl,
            educatorId: item.educatorId,
            description: item.video.description,
            durationLabel: item.video.durationLabel,
          );
        }).toList();
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
      final posts = await _logic.fetchRecentForumPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts.map((item) {
          return SmartAcademyEntry(
            id: item.post.id,
            kind: SmartAcademyEntryKind.forum,
            title: item.post.title,
            authorName: item.authorUsername,
            authorAvatarUrl: item.authorAvatarUrl,
            educatorId: item.educatorId,
            description: item.post.description,
          );
        }).toList();
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

  static int _videoColumnsForWidth(double width) {
    if (width >= 1600) return 5;
    if (width >= 1200) return 4;
    if (width >= 840) return 3;
    if (width >= 480) return 2;
    return 1;
  }

  void _openEntry(BuildContext context, SmartAcademyEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartAcademyDetailPage(entry: entry),
      ),
    );
  }

  Future<void> _openEducatorArea() async {
    final user = _logic.currentUser;

    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartAcademyAuthPage(
            onAuthenticated: () async {
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (!EducatorLogic.isUserEmailConfirmed(user)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartAcademyActivationRequiredPage(
            onSignOut: () async {
              await _logic.signOut();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    final isEducator = await _logic.hasEducatorAccount();
    if (!mounted) return;

    if (!isEducator) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartAcademyNotAnEducatorPage(
            onSignOut: () async {
              await _logic.signOut();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EducatorDashboardPage(
          username: EducatorLogic.defaultUsernameForUser(user),
          onSignOut: () async {
            await _logic.signOut();
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
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
      content = Text(
        'No videos published yet.',
        style: theme.textTheme.bodyMedium,
      );
    } else {
      final filteredVideos = filterSmartAcademyEntries(
        entries: _videos,
        searchQuery: _searchQuery,
      );
      if (filteredVideos.isEmpty) {
        content = Text(
          'No videos match your search.',
          style: theme.textTheme.bodyMedium,
        );
      } else {
        content = LayoutBuilder(
          builder: (context, constraints) {
            final columns = _videoColumnsForWidth(constraints.maxWidth);
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: filteredVideos.map((entry) {
                return SizedBox(
                  width: cardWidth,
                  child: _VideoCard(
                    entry: entry,
                    onTap: () => _openEntry(context, entry),
                  ),
                );
              }).toList(),
            );
          },
        );
      }
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

  Widget _buildForumSection(ThemeData theme) {
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
      content = Text(
        'No forum posts published yet.',
        style: theme.textTheme.bodyMedium,
      );
    } else {
      final filteredForum = filterSmartAcademyEntries(
        entries: _posts,
        searchQuery: _searchQuery,
      );
      if (filteredForum.isEmpty) {
        content = Text(
          'No forum posts match your search.',
          style: theme.textTheme.bodyMedium,
        );
      } else {
        content = Column(
          children: filteredForum.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ForumEntryCard(
                entry: entry,
                onTap: () => _openEntry(context, entry),
              ),
            );
          }).toList(),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forum', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _logic.currentUser;

    final showVideos = _activeFilter != SmartAcademyHubFilter.forum;
    final showForum = _activeFilter != SmartAcademyHubFilter.videos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartAcademy'),
        actions: [
          IconButton(
            tooltip: user == null ? 'Educator sign in' : 'Educator dashboard',
            onPressed: _openEducatorArea,
            icon: Icon(
              user == null ? Icons.login_rounded : Icons.school_outlined,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EducatorSearchBar(),
              const SizedBox(height: 24),
              SmartAcademyHubToolbar(
                searchController: _searchController,
                activeFilter: _activeFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (showVideos) ...[
                _buildVideosSection(theme),
                const SizedBox(height: 32),
              ],
              if (showForum) _buildForumSection(theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.entry, required this.onTap});

  final SmartAcademyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 40,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  if (entry.durationLabel != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.scrim.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.durationLabel!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        EducatorProfileAvatar(
                          username: entry.authorName,
                          avatarUrl: entry.authorAvatarUrl,
                          radius: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumEntryCard extends StatelessWidget {
  const _ForumEntryCard({required this.entry, required this.onTap});

  final SmartAcademyEntry entry;
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
                    Row(
                      children: [
                        EducatorProfileAvatar(
                          username: entry.authorName,
                          avatarUrl: entry.authorAvatarUrl,
                          radius: 9,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'by ${entry.authorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
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
