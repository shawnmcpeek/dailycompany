import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PracticeCopy {
  const _PracticeCopy({
    required this.title,
    required this.intro,
    required this.timerLabel,
    required this.timerIntro,
    required this.movements,
    required this.reminderLabel,
    required this.defaultHour,
  });

  final String title;
  final String intro;
  final String timerLabel;
  final String timerIntro;
  final List<TimerMovement> movements;
  final String reminderLabel;
  final int defaultHour;
}

_PracticeCopy _copyFor(String portalId) => switch (portalId) {
      'catherine' => const _PracticeCopy(
          title: 'Four requests',
          intro:
              'From the opening of the Dialogue: she asked for herself, '
              'for the Church, for the world, and for a particular case. '
              'Remain first in the cell of self-knowledge.',
          timerLabel: 'The four requests',
          timerIntro: 'Two minutes each. Her order, not a method invented here.',
          movements: [
            TimerMovement(
              label: 'Yourself',
              prompt:
                  'Remain in the cell of self-knowledge, in order to know '
                  'better the goodness of God towards you.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'The Church',
              prompt: 'The reformation of the Holy Church.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'The world',
              prompt: 'A general prayer for the whole world.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'This case',
              prompt:
                  'The particular case with which you are concerned today.',
              seconds: 120,
            ),
          ],
          reminderLabel: 'Hour of the requests',
          defaultHour: 7,
        ),
      'montfort' => const _PracticeCopy(
          title: 'To Jesus through Mary',
          intro:
              'His opening: it is by the most holy Virgin Mary that Jesus '
              'has come into the world, and it is also by her that He has '
              'to reign in the world. Not a thirty-three-day program.',
          timerLabel: 'Remain',
          timerIntro: 'Five minutes. To Jesus through Mary.',
          movements: [
            TimerMovement(
              label: 'Remain',
              prompt:
                  'It is by Mary that He has to reign in the world.',
              seconds: 300,
            ),
          ],
          reminderLabel: 'Hour of offering',
          defaultHour: 7,
        ),
      'scupoli' => const _PracticeCopy(
          title: 'The combat',
          intro:
              'Four things necessary for the conflict, as he wrote them: '
              'distrust of self, trust in God, spiritual exercise, and prayer.',
          timerLabel: 'Today’s combat',
          timerIntro: 'Two minutes on each of the four.',
          movements: [
            TimerMovement(
              label: 'Distrust',
              prompt: 'Distrust yourself.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Trust',
              prompt: 'Trust in God.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Exercise',
              prompt: 'The spiritual exercise of the understanding and the will.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Prayer',
              prompt: 'Ask for the help without which the combat is lost.',
              seconds: 120,
            ),
          ],
          reminderLabel: 'Hour of the combat',
          defaultHour: 7,
        ),
      'lawrence' => const _PracticeCopy(
          title: 'The presence',
          intro:
              'His practice was to remain with God, and to return when he '
              'noticed he had left. Not a set of jittered hours.',
          timerLabel: 'Remain',
          timerIntro: 'Ten minutes in His presence. Return if you wander.',
          movements: [
            TimerMovement(
              label: 'Remain',
              prompt: 'Practice the presence of God.',
              seconds: 600,
            ),
          ],
          reminderLabel: 'Hour of presence',
          defaultHour: 8,
        ),
      'cassian' => const _PracticeCopy(
          title: 'The elder',
          intro:
              'Purity of heart is the goal. Sit with today’s conference as '
              'they sat with the abbot — the word, then silence.',
          timerLabel: 'Sit',
          timerIntro: 'Twelve minutes. The elder’s word is on Today.',
          movements: [
            TimerMovement(
              label: 'Sit',
              prompt: 'Purity of heart is the goal.',
              seconds: 720,
            ),
          ],
          reminderLabel: 'Hour of the conference',
          defaultHour: 8,
        ),
      'newman' => const _PracticeCopy(
          title: 'Kindly Light',
          intro:
              'Heart speaks to heart. Three stanzas of The Pillar of the '
              'Cloud — Lead, kindly Light — as he wrote them at sea in 1833.',
          timerLabel: 'Lead, kindly Light',
          timerIntro: 'Two minutes on each stanza. His order.',
          movements: [
            TimerMovement(
              label: 'The gloom',
              prompt:
                  'Lead, kindly Light, amid the encircling gloom, '
                  'Lead Thou me on. The night is dark, and I am far from home; '
                  'Lead Thou me on. Keep Thou my feet; I do not ask to see '
                  'the distant scene — one step enough for me.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Not ever thus',
              prompt:
                  'I was not ever thus, nor prayed that Thou shouldst lead me on. '
                  'I loved to choose and see my path; but now, Lead Thou me on. '
                  'I loved the garish day, and, spite of fears, pride ruled my will: '
                  'remember not past years.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Till the night is gone',
              prompt:
                  'So long Thy power hath blest me, sure it still will lead me on, '
                  'o’er moor and fen, o’er crag and torrent, till the night is gone; '
                  'and with the morn those angel faces smile, which I have loved '
                  'long since, and lost awhile.',
              seconds: 120,
            ),
          ],
          reminderLabel: 'Hour of the kindly Light',
          defaultHour: 8,
        ),
      'desert-fathers' => const _PracticeCopy(
          title: 'A word',
          intro:
              'Abba, give me a word. Sit with one sentence from today’s '
              'reading. Do not add another.',
          timerLabel: 'The word',
          timerIntro: 'Ten minutes. One word.',
          movements: [
            TimerMovement(
              label: 'The word',
              prompt: 'Abba, give me a word.',
              seconds: 600,
            ),
          ],
          reminderLabel: 'Hour of the word',
          defaultHour: 8,
        ),
      'bernard' => const _PracticeCopy(
          title: 'The four degrees',
          intro:
              'Love is sufficient of itself. Four degrees from On Loving God: '
              'we begin with ourselves, and are drawn toward God.',
          timerLabel: 'The four degrees',
          timerIntro: 'Two minutes each. His order, not a method invented here.',
          movements: [
            TimerMovement(
              label: 'Self for self',
              prompt: 'Man loves himself for his own sake.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'God for self',
              prompt: 'Man loves God for his own sake.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'God for God',
              prompt: 'Man loves God for God’s sake.',
              seconds: 120,
            ),
            TimerMovement(
              label: 'Self for God',
              prompt: 'Man loves himself for God’s sake.',
              seconds: 120,
            ),
          ],
          reminderLabel: 'Hour of love',
          defaultHour: 8,
        ),
      _ => const _PracticeCopy(
          title: 'Practice',
          intro: 'Today’s practice.',
          timerLabel: 'Remain',
          timerIntro: 'Five minutes.',
          movements: [
            TimerMovement(
              label: 'Remain',
              prompt: 'Remain.',
              seconds: 300,
            ),
          ],
          reminderLabel: 'Hour',
          defaultHour: 8,
        ),
    };

class SimplePracticeScreen extends ConsumerWidget {
  const SimplePracticeScreen({super.key, required this.portalId});

  final String portalId;

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final copy = _copyFor(portalId);
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor(portalId).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? copy.defaultHour,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          portalId,
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _copyFor(portalId);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text(copy.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(copy.intro, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        ChromeLabel(copy.timerLabel),
        const SizedBox(height: 10),
        Text(copy.timerIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        GuidedTimer(movements: copy.movements),
        const SizedBox(height: 28),
        ChromeLabel(copy.reminderLabel),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor(portalId),
          onChanged: (v) => ctrl.setCycleReminderEnabled(portalId, v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor(portalId)),
          enabled: settings.reminderEnabledFor(portalId),
          onTap: settings.reminderEnabledFor(portalId)
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
