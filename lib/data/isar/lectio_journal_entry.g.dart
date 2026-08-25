// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lectio_journal_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLectioJournalEntryCollection on Isar {
  IsarCollection<LectioJournalEntry> get lectioJournalEntrys =>
      this.collection();
}

const LectioJournalEntrySchema = CollectionSchema(
  name: r'LectioJournalEntry',
  id: -5787718491058744202,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'portalId': PropertySchema(
      id: 1,
      name: r'portalId',
      type: IsarType.string,
    ),
    r'readingId': PropertySchema(
      id: 2,
      name: r'readingId',
      type: IsarType.long,
    ),
    r'text': PropertySchema(id: 3, name: r'text', type: IsarType.string),
  },

  estimateSize: _lectioJournalEntryEstimateSize,
  serialize: _lectioJournalEntrySerialize,
  deserialize: _lectioJournalEntryDeserialize,
  deserializeProp: _lectioJournalEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'portalId_readingId': IndexSchema(
      id: -6960062007533392109,
      name: r'portalId_readingId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'portalId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'readingId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'readingId': IndexSchema(
      id: -8529686247939572077,
      name: r'readingId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'readingId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _lectioJournalEntryGetId,
  getLinks: _lectioJournalEntryGetLinks,
  attach: _lectioJournalEntryAttach,
  version: '3.3.2',
);

int _lectioJournalEntryEstimateSize(
  LectioJournalEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.portalId.length * 3;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _lectioJournalEntrySerialize(
  LectioJournalEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.portalId);
  writer.writeLong(offsets[2], object.readingId);
  writer.writeString(offsets[3], object.text);
}

LectioJournalEntry _lectioJournalEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LectioJournalEntry();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.portalId = reader.readString(offsets[1]);
  object.readingId = reader.readLong(offsets[2]);
  object.text = reader.readString(offsets[3]);
  return object;
}

P _lectioJournalEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _lectioJournalEntryGetId(LectioJournalEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _lectioJournalEntryGetLinks(
  LectioJournalEntry object,
) {
  return [];
}

void _lectioJournalEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  LectioJournalEntry object,
) {
  object.id = id;
}

extension LectioJournalEntryQueryWhereSort
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QWhere> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhere>
  anyReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'readingId'),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhere>
  anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension LectioJournalEntryQueryWhere
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QWhereClause> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdEqualToAnyReadingId(String portalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'portalId_readingId',
          value: [portalId],
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdNotEqualToAnyReadingId(String portalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdReadingIdEqualTo(String portalId, int readingId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'portalId_readingId',
          value: [portalId, readingId],
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdEqualToReadingIdNotEqualTo(String portalId, int readingId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId],
                upper: [portalId, readingId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId, readingId],
                includeLower: false,
                upper: [portalId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId, readingId],
                includeLower: false,
                upper: [portalId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_readingId',
                lower: [portalId],
                upper: [portalId, readingId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdEqualToReadingIdGreaterThan(
    String portalId,
    int readingId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'portalId_readingId',
          lower: [portalId, readingId],
          includeLower: include,
          upper: [portalId],
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdEqualToReadingIdLessThan(
    String portalId,
    int readingId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'portalId_readingId',
          lower: [portalId],
          upper: [portalId, readingId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  portalIdEqualToReadingIdBetween(
    String portalId,
    int lowerReadingId,
    int upperReadingId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'portalId_readingId',
          lower: [portalId, lowerReadingId],
          includeLower: includeLower,
          upper: [portalId, upperReadingId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  readingIdEqualTo(int readingId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'readingId', value: [readingId]),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  readingIdNotEqualTo(int readingId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'readingId',
                lower: [],
                upper: [readingId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'readingId',
                lower: [readingId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'readingId',
                lower: [readingId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'readingId',
                lower: [],
                upper: [readingId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  readingIdGreaterThan(int readingId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'readingId',
          lower: [readingId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  readingIdLessThan(int readingId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'readingId',
          lower: [],
          upper: [readingId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  readingIdBetween(
    int lowerReadingId,
    int upperReadingId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'readingId',
          lower: [lowerReadingId],
          includeLower: includeLower,
          upper: [upperReadingId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  createdAtLessThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterWhereClause>
  createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LectioJournalEntryQueryFilter
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QFilterCondition> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'portalId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'portalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'portalId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  portalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  readingIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'readingId', value: value),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  readingIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'readingId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  readingIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'readingId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  readingIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'readingId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension LectioJournalEntryQueryObject
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QFilterCondition> {}

extension LectioJournalEntryQueryLinks
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QFilterCondition> {}

extension LectioJournalEntryQuerySortBy
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QSortBy> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByReadingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension LectioJournalEntryQuerySortThenBy
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QSortThenBy> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByReadingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.desc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }
}

extension LectioJournalEntryQueryWhereDistinct
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QDistinct> {
  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QDistinct>
  distinctByPortalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QDistinct>
  distinctByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readingId');
    });
  }

  QueryBuilder<LectioJournalEntry, LectioJournalEntry, QDistinct>
  distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }
}

extension LectioJournalEntryQueryProperty
    on QueryBuilder<LectioJournalEntry, LectioJournalEntry, QQueryProperty> {
  QueryBuilder<LectioJournalEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LectioJournalEntry, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LectioJournalEntry, String, QQueryOperations>
  portalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portalId');
    });
  }

  QueryBuilder<LectioJournalEntry, int, QQueryOperations> readingIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readingId');
    });
  }

  QueryBuilder<LectioJournalEntry, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }
}
