import 'package:dailycompany/app/brand.dart';
import 'package:dailycompany/app/theme/palette.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.sizeOf(context).height;
    final logoHeight = height < 700 ? 120.0 : 160.0;

    return Scaffold(
      backgroundColor: const Color(0xFF640F0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/branding/app_logo.png',
                              height: logoHeight,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              Brand.appName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'EBGaramond',
                                fontSize: 40,
                                height: 1.1,
                                color: Color(0xFFF3EDE1),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Keep company with a saint and their writing.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'EBGaramond',
                                fontSize: 18,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFD9CFBE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'How this works',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      const _HowLine(
                        title: 'The day is already chosen',
                        body:
                            'Open the app, walk the hallway, and enter a house. Benedict’s is open — one chapter of his Life, in order. The Rule is there when you want the monastic cycle.',
                      ),
                      const _HowLine(
                        title: 'Depth is optional',
                        body:
                            'Hours, Lectio, and the Tools are here when you want them — never as guilt.',
                      ),
                      const _HowLine(
                        title: 'A quiet signal',
                        body:
                            'Bells and haptics can mark the hours. You can change display and sound anytime in More.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .completeOnboarding();
                  if (context.mounted) context.go('/hallway');
                },
                child: const Text('Enter the hallway'),
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
      padding: const EdgeInsets.only(bottom: 20),
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
