import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../branding.dart';
import '../../data/exam_catalog.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_GuidePage>[
    _GuidePage(
      icon: Icons.menu_book_rounded,
      title: 'Welcome to PassForge',
      body:
          'Simulate. Study. Pass.\n\n'
          'Your offline Philippine board exam simulator for LET, PNLE, CPALE, CELE, CSE, ALE (Agriculture), and CLE — all scoped to PRC/CSC coverage.',
      color: AppColors.violet,
    ),
    _GuidePage(
      icon: Icons.palette_outlined,
      title: 'Each exam has a color',
      body:
          'LET is sky blue, Nursing is light green, Engineering is grey, and so on. Those exam accents stay unique — PassForge itself uses the glossy violet from the logo.',
      color: AppColors.violetLight,
      showExamColors: true,
    ),
    _GuidePage(
      icon: Icons.touch_app_rounded,
      title: 'How answering works',
      body:
          '1) Configure exam, difficulty, and focus.\n'
          '2) Tap an answer — it flashes your exam color.\n'
          '3) Then it turns green if correct, or red if wrong.\n'
          '4) Read the offline tutor note before continuing.',
      color: Color(0xFF16A34A),
    ),
    _GuidePage(
      icon: Icons.insights_rounded,
      title: 'Results & remedial drills',
      body:
          'After a simulation you get a mastery score, a simulated pass/fail verdict (75% pass mark), passing stats, and a knowledge heat map. Start a targeted remedial drill on your weakest topic.',
      color: Color(0xFFEA580C),
    ),
    _GuidePage(
      icon: Icons.rocket_launch_rounded,
      title: 'Ready to practice',
      body:
          'You get 1 free 20-question simulation per day. Set your exam date in Settings for a countdown. Replay this guide anytime from Settings → User guide.',
      color: AppColors.violetDark,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    await state.completeGuide();
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return GradientScaffold(
      accent: page.color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${AppBranding.name} guide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                if (!isLast)
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final p = _pages[index];
                  return _GuidePageView(page: p, isFirst: index == 0);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? page.color : AppColors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (_page > 0)
                  OutlinedButton(
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    },
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Color.lerp(page.color, Colors.black, 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  onPressed: _next,
                  child: Text(isLast ? 'Get started' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.showExamColors = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final bool showExamColors;
}

class _GuidePageView extends StatelessWidget {
  const _GuidePageView({required this.page, required this.isFirst});

  final _GuidePage page;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (isFirst)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                AppBranding.iconAsset,
                width: 108,
                height: 108,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 52, color: page.color),
            ),
          const SizedBox(height: 20),
          if (isFirst) ...[
            const Text(
              AppBranding.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.violetDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            accent: page.color,
            child: Text(
              page.body,
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
          ),
          if (page.showExamColors) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ExamCatalog.exams
                  .map(
                    (e) => ExamColorChip(
                      label: e.shortName,
                      color: e.accent,
                      selected: true,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Not affiliated with PRC or CSC. Practice content only.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
