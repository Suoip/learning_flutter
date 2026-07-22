import 'package:flutter/material.dart';

import 'education_item.dart';
import 'experience_item.dart';
import 'section_header.dart';

class MainColumn extends StatelessWidget {
  const MainColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'Professional Summary'),
        SizedBox(height: 14),
        Text(
          'Front end developer with a strong eye for clean interfaces, accessible UX, and maintainable Flutter code. Experienced in translating product goals into polished mobile experiences with a focus on performance and consistency.',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 15,
            height: 1.55,
          ),
        ),
        SizedBox(height: 28),
        SectionHeader(title: 'Experience'),
        SizedBox(height: 16),
        ExperienceItem(
          company: 'Company Name',
          role: 'Senior Front End Developer',
          period: '2022 - Present',
          details: [
            'Led UI implementation for customer-facing features across web and mobile projects.',
            'Improved design consistency by building reusable components and shared style patterns.',
            'Worked closely with product and design teams to refine user flows and ship updates faster.',
          ],
        ),
        SizedBox(height: 18),
        ExperienceItem(
          company: 'Company Name',
          role: 'Front End Developer',
          period: '2020 - 2022',
          details: [
            'Built responsive interfaces from wireframes and design specifications.',
            'Collaborated on performance improvements and cross-device UX polish.',
            'Maintained code quality through consistent component structure and clean handoffs.',
          ],
        ),
        SizedBox(height: 18),
        ExperienceItem(
          company: 'Company Name',
          role: 'Junior Developer',
          period: '2018 - 2020',
          details: [
            'Supported feature development and UI updates across multiple client projects.',
            'Translated visual mockups into reliable and reusable Flutter widgets.',
            'Gained experience with agile delivery, bug fixing, and iterative improvements.',
          ],
        ),
        SizedBox(height: 28),
        SectionHeader(title: 'Education'),
        SizedBox(height: 16),
        EducationItem(
          degree: 'BSc in Computer Science',
          institution: 'College or University',
          period: '2014 - 2018',
        ),
      ],
    );
  }
}
