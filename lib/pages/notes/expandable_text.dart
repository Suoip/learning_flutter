import 'package:flutter/material.dart';

/// Text that truncates to [trimLines] with a "Show more"/"Show less" toggle,
/// YouTube-description style. Uses a simple character-length heuristic
/// rather than real overflow measurement: text at or under
/// [toggleThreshold] always renders in full with no toggle at all, so
/// getting the threshold slightly wrong only ever produces an unnecessary
/// toggle, never hidden, unreachable content.
class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.trimLines = 4,
    this.style,
  });

  final String text;
  final int trimLines;
  final TextStyle? style;

  static const int toggleThreshold = 240;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ?? theme.textTheme.bodyMedium;
    final trimmed = widget.text.trim();
    final needsToggle = trimmed.length > ExpandableText.toggleThreshold;
    final showEllipsis = needsToggle && !_expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trimmed,
          style: style,
          maxLines: showEllipsis ? widget.trimLines : null,
          overflow: showEllipsis ? TextOverflow.ellipsis : TextOverflow.visible,
        ),
        if (needsToggle) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
