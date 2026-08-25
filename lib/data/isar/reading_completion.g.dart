// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_completion.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadingCompletionCollection on Isar {
  IsarCollection<ReadingCompletion> get readingCompletions => this.collection();
}

const ReadingCompletionSchema = CollectionSchema(
  name: r'ReadingCompletion',
  id: -3760610252540621580,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'dateKey': PropertySchema(id: 1, name: r'dateKey', type: IsarType.string),
    r'portalId': PropertySchema(
      id: 2,
      name: r'portalId',
      type: IsarType.string,
    ),
    r'readingId': PropertySchema(
      id: 3,
      name: r'readingId',
      type: IsarType.long,
    ),
  },

  estimateSize: _readingCompletionEstimateSize,
  serialize: _readingCompletionSerialize,
  deserialize: _readingCompletionDeserialize,
  deserializeProp: _readingCompletionDeserializeProp,
  idName: r'id',
  indexes: {
    r'portalId_dateKey': IndexSchema(
      id: -2874239340639068280,
      name: r'portalId_dateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'portalId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _readingCompletionGetId,
  getLinks: _readingCompletionGetLinks,
  attach: _readingCompletionAttach,
  version: '3.3.2',
);

int _readingCompletionEstimateSize(
  ReadingCompletion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.portalId.length * 3;
  return bytesCount;
}

void _readingCompletionSerialize(
  ReadingCompletion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeString(offsets[2], object.portalId);
  writer.writeLong(offsets[3], object.readingId);
}

ReadingCompletion _readingCompletionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadingCompletion();
  object.completedAt = reader.readDateTime(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.id = id;
  object.portalId = reader.readString(offsets[2]);
  object.readingId = reader.readLongOrNull(offsets[3]);
  return object;
}

P _readingCompletionDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readingCompletionGetId(ReadingCompletion object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readingCompletionGetLinks(
  ReadingCompletion object,
) {
  return [];
}

void _readingCompletionAttach(
  IsarCollection<dynamic> col,
  Id id,
  ReadingCompletion object,
) {
  object.id = id;
}

extension ReadingCompletionQueryWhereSort
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QWhere> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReadingCompletionQueryWhere
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QWhereClause> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  portalIdEqualToAnyDateKey(String portalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'portalId_dateKey',
          value: [portalId],
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  portalIdNotEqualToAnyDateKey(String portalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  portalIdDateKeyEqualTo(String portalId, String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'portalId_dateKey',
          value: [portalId, dateKey],
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  portalIdEqualToDateKeyNotEqualTo(String portalId, String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId],
                upper: [portalId, dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId, dateKey],
                includeLower: false,
                upper: [portalId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId, dateKey],
                includeLower: false,
                upper: [portalId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId_dateKey',
                lower: [portalId],
                upper: [portalId, dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateKey', value: [dateKey]),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterWhereClause>
  dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ReadingCompletionQueryFilter
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QFilterCondition> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  completedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAt', value: value),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  completedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  completedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  completedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  portalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  portalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'readingId'),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'readingId'),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'readingId', value: value),
      );
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdGreaterThan(int? value, {bool include = false}) {
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdLessThan(int? value, {bool include = false}) {
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

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterFilterCondition>
  readingIdBetween(
    int? lower,
    int? upper, {
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
}

extension ReadingCompletionQueryObject
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QFilterCondition> {}

extension ReadingCompletionQueryLinks
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QFilterCondition> {}

extension ReadingCompletionQuerySortBy
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QSortBy> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  sortByReadingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.desc);
    });
  }
}

extension ReadingCompletionQuerySortThenBy
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QSortThenBy> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.asc);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QAfterSortBy>
  thenByReadingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingId', Sort.desc);
    });
  }
}

extension ReadingCompletionQueryWhereDistinct
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QDistinct> {
  QueryBuilder<ReadingCompletion, ReadingCompletion, QDistinct>
  distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QDistinct>
  distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QDistinct>
  distinctByPortalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingCompletion, ReadingCompletion, QDistinct>
  distinctByReadingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readingId');
    });
  }
}

extension ReadingCompletionQueryProperty
    on QueryBuilder<ReadingCompletion, ReadingCompletion, QQueryProperty> {
  QueryBuilder<ReadingCompletion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadingCompletion, DateTime, QQueryOperations>
  completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<ReadingCompletion, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<ReadingCompletion, String, QQueryOperations> portalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portalId');
    });
  }

  QueryBuilder<ReadingCompletion, int?, QQueryOperations> readingIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readingId');
    });
  }
}
