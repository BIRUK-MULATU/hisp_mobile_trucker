import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/onboarding/onboarding_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_dimensions.dart';
import '../../../../shared/theme/app_text_styles.dart';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.local_hospital_rounded,
    title: 'Welcome to RDHIS2 Mobile App',
    description: "The official DHIS2 data collection app for health "
        "facilities — record and report your facility's health data "
        'straight from your phone.',
  ),
  _OnboardingSlide(
    icon: Icons.edit_note_rounded,
    title: 'Capture data anywhere',
    description: 'Pick your organisation unit, dataset and period, then '
        'enter values — everything saves to your device first, even '
        'with no signal.',
  ),
  _OnboardingSlide(
    icon: Icons.sync_rounded,
    title: "Syncs when you're connected",
    description: 'Once your phone is back online, saved reports are sent '
        "to the server automatically — no need to remember to do it "
        'yourself.',
  ),
  _OnboardingSlide(
    icon: Icons.insights_rounded,
    title: 'Build and view charts',
    description: 'Turn your indicators, data elements and datasets into '
        'charts, and view them again anytime — even offline.',
  ),
];

/// Shown once, the very first time the app is opened (before login) —
/// see AppRouter's redirect, gated by OnboardingService.hasSeenOnboarding.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingService.markOnboardingSeen();
    if (mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceSM),
                child: isLast
                    ? const SizedBox(height: 36)
                    : TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Skip',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLG,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: AppTextStyles.buttonLarge
                            .copyWith(color: Colors.white),
                      ),
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

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
