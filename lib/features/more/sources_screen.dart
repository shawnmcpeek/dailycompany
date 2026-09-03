import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portalId = ref.watch(currentPortalIdProvider);
    return switch (portalId) {
      'desales' => const _DesalesSources(),
      'kempis' => const _KempisSources(),
      'liguori' => const _LiguoriSources(),
      'francis' => const _FrancisSources(),
      _ => const _BenedictSources(),
    };
  }
}

class _BenedictSources extends StatelessWidget {
  const _BenedictSources();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional, '
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
              'Public domain. Butler’s 1912 edition is the scholarly base often '
              'behind such texts. Obvious scanning errors in that scrape '
              '(missing words, split letters, site footer) were corrected '
              'against published witnesses; the English is still Verheyen.',
        ),
        const _SourceBlock(
          title: 'Reading calendar (dates only)',
          body:
              'Portion breakpoints for the thrice-yearly cycle were taken from the date table in '
              'Doyle’s English Rule (Collegeville; Gutenberg #50040). Only the dates were used — '
              'Doyle’s wording is not displayed. The Jan / May / Sept division is a long monastic custom.',
        ),
        _SourceBlock(
          title: PortalRegistry.benedict.provenanceTitle,
          body: PortalRegistry.benedict.provenanceParagraphs.join('\n\n'),
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
              'The seventy-two instruments as transmitted in Verheyen’s English Rule. '
              'When Benedict is quoting or clearly echoing Scripture, the verse is '
              'Douay-Rheims (Challoner). Short glosses were written from Delatte/McCann; '
              'they are not verbatim Delatte. Public domain.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('The Medal'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'Drawings',
          body:
              'Obverse woodcut: Wikimedia Commons, File:Medalla San Benito.PNG. '
              'Public domain. Reverse letter diagram: Openclipart / Justin Ternet, '
              'Médaille de St Benoit. Public domain.',
        ),
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
          PortalRegistry.benedict.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _DesalesSources extends StatelessWidget {
  const _DesalesSources();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('Introduction to the Devout Life'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'Library of Spiritual Works for English Catholics '
              '(Rivingtons, London / Oxford / Cambridge, 1876), '
              'titled “A New Translation.” The title page names no '
              'translator. Hosted by the Christian Classics Ethereal '
              'Library. Not Dom Henry Benedict Mackey (he translated '
              'the Treatise and the Letters for Burns & Oates). '
              'Not John K. Ryan (1950). 1876 — public domain.',
        ),
        _SourceBlock(
          title: PortalRegistry.desales.provenanceTitle,
          body: PortalRegistry.desales.provenanceParagraphs.join('\n\n'),
        ),
        const _SourceBlock(
          title: 'Letters',
          body:
              'Letters to Persons in the World, from the public-domain English '
              'text used in this house. Selections, not the complete correspondence.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'John K. Ryan (1950, Image/Doubleday), Michael Day (1956), '
          'Armind Nazareth, and any TAN or Sophia Institute edition’s '
          'apparatus, notes, or chapter titles.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.desales.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _KempisSources extends StatelessWidget {
  const _KempisSources();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('The Imitation of Christ'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Imitation of Christ, translated by Rev. William Benham (1886). '
              'Project Gutenberg #1653. Benham died 1910 — public domain. '
              'All four books, including Book IV on the Sacrament.',
        ),
        const _SourceBlock(
          title: 'Authorship',
          body:
              'The work is traditionally attributed to Thomas à Kempis. '
              'He was never canonized. Authorship has been debated '
              '(Gerson, Gersen, Hilton); this house follows the received '
              'attribution.',
        ),
        _SourceBlock(
          title: PortalRegistry.kempis.provenanceTitle,
          body: PortalRegistry.kempis.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Aloysius Croft and Harold Bolton (1940, Image), Ronald Knox, '
          'William Creasy, Joseph Tylenda SJ, and any TAN or Sophia Institute '
          'edition’s apparatus, notes, or chapter titles.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.kempis.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LiguoriSources extends StatelessWidget {
  const _LiguoriSources();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('Visits to the Blessed Sacrament'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'Visits to the Blessed Sacrament and to the Blessed Virgin, '
              'translated by Eugene Grimm, CSsR, in the Centenary Edition '
              '(Benziger Brothers, New York, 1887) — The Holy Eucharist, '
              'Volume VI of the Complete Ascetical Works. Confirmed against '
              'the 1887 printing (archive.org alphonsusworks06alfouoft). '
              'Grimm died 1891 — public domain. Not a Liguori Publications '
              'edition.',
        ),
        _SourceBlock(
          title: PortalRegistry.liguori.provenanceTitle,
          body: PortalRegistry.liguori.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Any Liguori Publications, TAN, or Sophia Institute edition’s '
          'apparatus, notes, or chapter titles. The 1949 Catholic Book '
          'Publishing Co. Visits (Spellman imprimatur) is in copyright.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.liguori.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _FrancisSources extends StatelessWidget {
  const _FrancisSources();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('Writings'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Writings of St. Francis of Assisi, translated by Paschal '
              'Robinson, OFM (The Dolphin Press, Philadelphia, 1905). '
              'Robinson died 1948; the 1905 printing is public domain in '
              'the United States. Authentic writings only — Admonitions, '
              'Rules, Testament, letters, prayers, the Canticle. Not a '
              'modern Franciscan or ICS edition.',
        ),
        const _SourceBlock(
          title: 'Stories told about him',
          body:
              'The Little Flowers of St. Francis, translated by W. Heywood '
              '(Methuen, London, 1906), with an introduction by '
              'A. G. Ferrers Howell. A second shelf — never interleaved '
              'with the daily writings.',
        ),
        _SourceBlock(
          title: PortalRegistry.francis.provenanceTitle,
          body: PortalRegistry.francis.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Any post-1928 Franciscan, OFM, Capuchin, or ICS edition’s '
          'apparatus, notes, or chapter titles. The Fioretti are not '
          'used as daily readings.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.francis.disclaimer,
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
