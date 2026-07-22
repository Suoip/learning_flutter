import 'package:flutter/material.dart';

import 'contact_line.dart';
import 'side_panel.dart';
import 'skill_chip.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SidePanel(
          title: 'Contact',
          children: [
            ContactLine(label: 'Email', value: 'john.smith@email.com'),
            ContactLine(label: 'Phone', value: '+1 234 567 890'),
            ContactLine(label: 'Location', value: 'New York, USA'),
          ],
        ),
        SizedBox(height: 20),
        SidePanel(
          title: 'Portfolio',
          children: [
            ContactLine(label: 'Website', value: 'www.johnsmith.dev'),
            ContactLine(label: 'GitHub', value: 'github.com/johnsmith'),
            ContactLine(label: 'LinkedIn', value: 'linkedin.com/in/johnsmith'),
          ],
        ),
        SizedBox(height: 20),
        SidePanel(
          title: 'Expertise',
          children: [
            SkillChip(text: 'Flutter & Dart'),
            SkillChip(text: 'UI/UX Design'),
            SkillChip(text: 'JavaScript & React'),
            SkillChip(text: 'Responsive Layouts'),
            SkillChip(text: 'State Management'),
          ],
        ),
      ],
    );
  }
}
