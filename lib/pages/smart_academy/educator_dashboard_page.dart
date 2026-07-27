import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_video_form_page.dart';

/// Post-login landing page for educators: lists the signed-in educator's
/// own SmartAcademy video entries (title/description/duration-label
/// metadata only - no real video file upload exists yet) with create/edit/
/// delete. Scoped entirely to the educator's private dashboard; the public
/// SmartAcademy hub page keeps showing its own static sample data (see
/// smart_academy_entry.dart) until a later PR wires real authored content
/// into it.
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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final videos = await _logic.fetchVideosForCurrentEducator();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load your videos.',
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

  Widget _buildBody() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load videos:\n$_error',
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
          ),
        ],
      );
    }

    if (_videos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
        children: [
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 40,
                    color: cs.primary,
                  ),
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
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _EducatorVideoTile(
          video: video,
          onTap: () => _editVideo(video),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text("${widget.username}'s Videos"),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createVideo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Video'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVideos,
          child: _buildBody(),
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
