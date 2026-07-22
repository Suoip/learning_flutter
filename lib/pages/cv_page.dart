import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    ));

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        toolbarHeight: 132.0,
        backgroundColor: const Color(0xFF1F3A5F),
        elevation: 0,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'John Smith',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Front End Developer',
              style: TextStyle(
                fontSize: 16.0,
                color: Color(0xFFD7E3F4),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Body(),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(flex: 7, child: _MainColumn()),
                  SizedBox(width: 24),
                  Expanded(flex: 3, child: _SideColumn()),
                ],
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SideColumn(),
                  SizedBox(height: 24),
                  _MainColumn(),
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(title: 'Professional Summary'),
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
        _SectionHeader(title: 'Experience'),
        SizedBox(height: 16),
        _ExperienceItem(
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
        _ExperienceItem(
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
        _ExperienceItem(
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
        _SectionHeader(title: 'Education'),
        SizedBox(height: 16),
        _EducationItem(
          degree: 'BSc in Computer Science',
          institution: 'College or University',
          period: '2014 - 2018',
        ),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SidePanel(
          title: 'Contact',
          children: [
            _ContactLine(label: 'Email', value: 'john.smith@email.com'),
            _ContactLine(label: 'Phone', value: '+1 234 567 890'),
            _ContactLine(label: 'Location', value: 'New York, USA'),
          ],
        ),
        SizedBox(height: 20),
        _SidePanel(
          title: 'Portfolio',
          children: [
            _ContactLine(label: 'Website', value: 'www.johnsmith.dev'),
            _ContactLine(label: 'GitHub', value: 'github.com/johnsmith'),
            _ContactLine(label: 'LinkedIn', value: 'linkedin.com/in/johnsmith'),
          ],
        ),
        SizedBox(height: 20),
        _SidePanel(
          title: 'Expertise',
          children: [
            _SkillChip(text: 'Flutter & Dart'),
            _SkillChip(text: 'UI/UX Design'),
            _SkillChip(text: 'JavaScript & React'),
            _SkillChip(text: 'Responsive Layouts'),
            _SkillChip(text: 'State Management'),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF1F3A5F),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  const _ExperienceItem({
    required this.company,
    required this.role,
    required this.period,
    required this.details,
  });

  final String company;
  final String role;
  final String period;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF375B92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                period,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF1F3A5F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  const _EducationItem({
    required this.degree,
    required this.institution,
    required this.period,
  });

  final String degree;
  final String institution;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  institution,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF375B92),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            period,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
