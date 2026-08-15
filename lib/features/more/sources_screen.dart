import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Benedict Daily is public-domain or traditional, '
          'chosen so the app can ship globally without a monastery’s imprimatur.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('The Rule'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Holy Rule of St. Benedict, translated by Boniface Verheyen, O.S.B. '
              '(1902 / 1906; 1949 reprint). Verheyen died 1925 — public domain.',
        ),
        const _SourceBlock(
          title: 'Latin side-by-side',
          body:
              'Regula Sancti Benedicti, from The Latin Library text of the Rule. '
              'Public domain. (Butler’s 1912 Latin edition is the scholarly base often behind such texts.)',
        ),
        const _SourceBlock(
          title: 'Reading calendar (dates only)',
          body:
              'Portion breakpoints for the thrice-yearly cycle were taken from the date table in '
              'Doyle’s English Rule (Collegeville; Gutenberg #50040). Only the dates were used — '
              'Doyle’s wording is not displayed. The Jan / May / Sept division is a long monastic custom.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Commentary'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Research source',
          body:
              'Paul Delatte, O.S.B., The Rule of St. Benedict: A Commentary, '
              'translated by Justin McCann (1921). Public domain. Short in-app glosses '
              'were written from that research; they are not verbatim Delatte.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Hours'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Psalter',
          body:
              'Douay-Rheims Bible, Challoner revision (1899). Public domain. '
              'Psalm numbers follow the Vulgate (so RB’s “Psalm 90” is modern Psalm 91).',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Life of Benedict'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Dialogues, Book II',
          body:
              'Gregory the Great, Dialogues Book II, English from Edmund G. Gardner’s edition (1911). '
              'Public domain.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Tools of Good Works'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Rule, chapter 4',
          body:
              'The seventy-two instruments as transmitted in Verheyen’s English Rule. Public domain.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('The Medal'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Traditional texts',
          body:
              'Letter expansions, the Jubilee Medal blessing (noted as reserved to a priest), '
              'the Litany of St. Benedict, and a short history of the medal form. '
              'Traditional / public-domain formulations.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'RB 1980 (Liturgical Press), Kardong, McCann’s 1952 translation, '
          'Zimmerman’s 1959 Dialogues, the Grail Psalter, the Abbey Psalms and Canticles, '
          'Solesmes modern chant editions, and commercial chant recordings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          'An independent app from Daddoo Dev. Not affiliated with, endorsed by, '
          'or produced by any Benedictine monastery, abbey, congregation, or '
          'the Order of Saint Benedict.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
