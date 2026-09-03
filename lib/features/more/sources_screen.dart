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
      'john-cross' => const _JohnCrossSources(),
      'gregory' => const _GregorySources(),
      'augustine' => const _AugustineSources(),
      'teresa-avila' => const _TeresaSources(),
      'ignatius' => const _IgnatiusSources(),
      'therese' => const _ThereseSources(),
      'catherine' => const _NamedSources(portalId: 'catherine'),
      'montfort' => const _NamedSources(portalId: 'montfort'),
      'scupoli' => const _NamedSources(portalId: 'scupoli'),
      'lawrence' => const _NamedSources(portalId: 'lawrence'),
      'cassian' => const _NamedSources(portalId: 'cassian'),
      'serra' => const _SerraSources(),
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

class _JohnCrossSources extends StatelessWidget {
  const _JohnCrossSources();

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
        ChromeLabel('Sayings'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Complete Works of Saint John of the Cross, translated by '
              'David Lewis, volume 2 (Longman, Green, Longman, Roberts & Green, '
              '1864): the Instructions and Cautions, and the Spiritual Maxims. '
              'One saying a day. The treatises are not this year.',
        ),
        _SourceBlock(
          title: PortalRegistry.johnCross.provenanceTitle,
          body: PortalRegistry.johnCross.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Kavanaugh–Rodriguez (ICS, 1964–). Any Carmelite or OCD apparatus, '
          'notes, or chapter titles. The Ascent, Dark Night, Spiritual Canticle, '
          'and Living Flame are a later shelf.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.johnCross.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _GregorySources extends StatelessWidget {
  const _GregorySources();

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
        ChromeLabel('The Pastoral Rule'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Book of Pastoral Rule, translated by James Barmby, in '
              'Nicene and Post-Nicene Fathers, Second Series, Volume 12, '
              'edited by Philip Schaff and Henry Wace (Christian Literature '
              'Publishing Co., 1895). Dialogues Book II already ships as '
              'Benedict’s Life and is not recut here.',
        ),
        _SourceBlock(
          title: PortalRegistry.gregory.provenanceTitle,
          body: PortalRegistry.gregory.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Any modern papal, diocesan, or Newman-press apparatus. Dialogues '
          'Book II is not duplicated.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.gregory.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _AugustineSources extends StatelessWidget {
  const _AugustineSources();

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
        ChromeLabel('The Confessions'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Confessions of Saint Augustine, translated by E. B. Pusey '
              '(1838). The daily year is Books I–X. Books XI–XIII remain as '
              'an appendix, reachable from the index and Read Through. '
              'Not City of God.',
        ),
        _SourceBlock(
          title: PortalRegistry.augustine.provenanceTitle,
          body: PortalRegistry.augustine.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Any Augustinian or OSA apparatus. City of God is not the daily book.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.augustine.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _TeresaSources extends StatelessWidget {
  const _TeresaSources();

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
        ChromeLabel('Way and Castle'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'The Way of Perfection and The Interior Castle, translated from '
              'the autograph by the Benedictines of Stanbrook, revised with '
              'notes by Benedict Zimmerman (Thomas Baker, 1911–12; the 1921 '
              'Baker impression of the same translation). Not Peers. Not ICS.',
        ),
        _SourceBlock(
          title: PortalRegistry.teresaAvila.provenanceTitle,
          body: PortalRegistry.teresaAvila.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'E. Allison Peers (1946–). Kavanaugh–Rodriguez ICS. Any Carmelite '
          'or OCD apparatus, notes, or chapter titles.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.teresaAvila.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _IgnatiusSources extends StatelessWidget {
  const _IgnatiusSources();

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
        ChromeLabel('Autobiography and Exercises'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'Autobiography of St. Ignatius, translated by J. F. X. O’Conor, '
              'S.J. (Benziger, 1900). Spiritual Exercises, translated from '
              'the Autograph by Elder Mullan, S.J. (Kenedy, 1914). Anima '
              'Christi is the traditional public-domain English; Mullan only '
              'names it as a rubric. The Prayer for Generosity is not in the '
              'Autograph or in Mullan and is not included. Not Puhl, Ganss, '
              'or Fleming.',
        ),
        _SourceBlock(
          title: PortalRegistry.ignatius.provenanceTitle,
          body: PortalRegistry.ignatius.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Puhl (1951). Ganss. Fleming. Loyola Press or IJS apparatus. The '
          'Prayer for Generosity, which is not in the Autograph or in Mullan. '
          'The IHS emblem as ornament. “Company” as an Ignatian wink.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.ignatius.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ThereseSources extends StatelessWidget {
  const _ThereseSources();

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
        ChromeLabel('Story of a Soul'),
        const SizedBox(height: 10),
        const _SourceBlock(
          title: 'English display text',
          body:
              'Story of a Soul, translated by Thomas N. Taylor (Burns, Oates '
              '& Washbourne, 1912). Taylor of the 1898 Pauline edited '
              'Histoire d’une Âme — the historically famous edited Thérèse, '
              'not the 1956 manuscript restoration, not Clarke ICS, and not '
              'Knox. Poems in the Gutenberg file are Susan L. Emery’s and '
              'are not shipped.',
        ),
        _SourceBlock(
          title: PortalRegistry.therese.provenanceTitle,
          body: PortalRegistry.therese.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'The 1956 Manuscrits autobiographiques. Clarke ICS (1975). Knox '
          '(1958). Any translation of the critical edition. Susan L. Emery’s '
          'poems in the Gutenberg file. Lisieux shrine photography and Office '
          'Central de Lisieux imagery.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          PortalRegistry.therese.disclaimer,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _NamedSources extends StatelessWidget {
  const _NamedSources({required this.portalId});

  final String portalId;

  @override
  Widget build(BuildContext context) {
    final portal = PortalRegistry.byId(portalId)!;
    final daily = switch (portalId) {
      'catherine' => (
          'The Dialogue',
          'The Dialogue of Saint Catherine of Siena, translated by Algar '
              'Thorold (Kegan Paul, Trench, Trubner & Co., 1907).',
          'Modern critical translations. Dominican or OP apparatus, notes, '
              'or chapter titles.',
        ),
      'montfort' => (
          'True Devotion',
          'A Treatise on the True Devotion to the Blessed Virgin, '
              'translated by Frederick William Faber (Burns & Lambert, 1863). '
              'Not a modern Montfort translation, and not a thirty-three-day '
              'program.',
          'Company of Mary, Montfort Missionaries, or Daughters of Wisdom '
              'apparatus. A 33-day consecration program built from this book.',
        ),
      'scupoli' => (
          'The Spiritual Combat',
          'The Spiritual Combat, together with the Supplement, anonymous '
              'new translation (Rivingtons, 1875), Library of Spiritual Works '
              'for English Catholics. The Path of Paradise in that scan is '
              'not shipped. Not a modern edition.',
          'Theatines. “St.” or “Saint” on this name. The Path of Paradise '
              'from this scan.',
        ),
      'lawrence' => (
          'The Practice of the Presence of God',
          'Conversations and Letters of Brother Lawrence, translated from '
              'the French (Fleming H. Revell). Anonymous nineteenth-century '
              'English. Project Gutenberg #13871.',
          'Carmelite or OCD apparatus. “St.” or “Saint” on this name.',
        ),
      'cassian' => (
          'The Conferences',
          'The Conferences of John Cassian, translated by Edgar C. S. Gibson, '
              'Nicene and Post-Nicene Fathers, Second Series, Volume 11 (1894). '
              'Conferences I–XI, XIII–XXI, XXIII–XXIV. Gibson did not translate '
              'XII and XXII; they are not invented here. Not the Institutes, '
              'not On the Incarnation.',
          'The Institutes. On the Incarnation against Nestorius. Invented '
              'English for the two conferences Gibson left untranslated.',
        ),
      _ => ('Daily text', '', ''),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel(daily.$1),
        const SizedBox(height: 10),
        _SourceBlock(title: 'English display text', body: daily.$2),
        _SourceBlock(
          title: portal.provenanceTitle,
          body: portal.provenanceParagraphs.join('\n\n'),
        ),
        if (daily.$3.isNotEmpty) ...[
          const SizedBox(height: 20),
          ChromeLabel('Not used'),
          const SizedBox(height: 10),
          Text(daily.$3, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 28),
        Text(portal.disclaimer, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SerraSources extends StatelessWidget {
  const _SerraSources();

  @override
  Widget build(BuildContext context) {
    final portal = PortalRegistry.byId('serra')!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        Text(
          'Every text in Daily Company is public-domain or traditional.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        ChromeLabel('The 1769 journey'),
        const SizedBox(height: 10),
        _SourceBlock(
          title: 'English display text',
          body:
              'Francisco Palóu, Relación Histórica de la Vida y Apostólicas '
              'Tareas del Venerable Padre Fray Junípero Serra, translated by '
              'C. Scott Williams (George W. James, 1913). Diary of Gaspar de '
              'Portolá during the California expedition of 1769–1770, edited '
              'by Donald Eugene Smith and Frederick J. Teggart, Publications '
              'of the Academy of Pacific Coast History, vol. 1 no. 3 (1909).',
        ),
        _SourceBlock(
          title: portal.provenanceTitle,
          body: portal.provenanceParagraphs.join('\n\n'),
        ),
        const SizedBox(height: 20),
        ChromeLabel('The twenty-one missions'),
        const SizedBox(height: 10),
        _SourceBlock(
          title: 'Research',
          body:
              'Zephyrin Engelhardt, O.F.M., The Missions and Missionaries of '
              'California (1912–15). Engelhardt is a Franciscan partisan; the '
              'gallery uses him as the primary research voice and names that '
              'standpoint here, not as a disclaimer, as scholarship. Palóu/'
              'Williams and the Catholic Encyclopedia (1913) supply founding '
              'dates. Santa Cruz follows Engelhardt (25 September 1791), not '
              'the Encyclopedia’s 29 September. San Luis Rey follows '
              'Engelhardt (13 June 1798), not the Encyclopedia’s 13 July.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Prayers'),
        const SizedBox(height: 10),
        _SourceBlock(
          title: 'Alabado, Angelus, Crown',
          body:
              'The Alabado Spanish is the acclamation Engelhardt prints. The '
              'Angelus and the Franciscan Crown are traditional public-domain '
              'English. Nothing devotional was written for this house.',
        ),
        const SizedBox(height: 20),
        ChromeLabel('Not used'),
        const SizedBox(height: 10),
        Text(
          'Tibesar, Writings of Junípero Serra (1955–66). Geiger’s Palóu '
          '(1955). Hackel. Modern mission guidebooks. Contemporary photographs '
          'of the missions — these are active parishes.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(portal.disclaimer, style: Theme.of(context).textTheme.bodyMedium),
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
