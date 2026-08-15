import 'package:benedictdaily/app/brand.dart';
import 'package:benedictdaily/app/theme/palette.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF640F0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Brand.studio.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 11,
                  letterSpacing: 0.1,
                  color: Color(0xFFD9CFBE),
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/branding/app_logo.png',
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              const Text(
                'Benedict Daily',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 40,
                  height: 1.1,
                  color: Color(0xFFF3EDE1),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The Rule, read as monks read it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 18,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFD9CFBE),
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Vellum.gold,
                  foregroundColor: Compline.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => context.push('/welcome/how'),
                child: const Text('Begin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeHowScreen extends ConsumerWidget {
  const WelcomeHowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How this works',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              const _HowLine(
                title: 'The day is already chosen',
                body:
                    'Open the app on any date and the Rule portion is waiting. There is no plan to start.',
              ),
              const _HowLine(
                title: 'Depth is optional',
                body:
                    'Hours, Lectio, Life, and the Tools are here when you want them — never as guilt.',
              ),
              const _HowLine(
                title: 'A quiet signal',
                body:
                    'Bells and haptics can mark the hours. You can change display and sound anytime in More.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .completeOnboarding();
                  if (context.mounted) context.go('/hub');
                },
                child: const Text('Enter Benedict Daily'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowLine extends StatelessWidget {
  const _HowLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
