// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_spot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadingSpotCollection on Isar {
  IsarCollection<ReadingSpot> get readingSpots => this.collection();
}

const ReadingSpotSchema = CollectionSchema(
  name: r'ReadingSpot',
  id: -5388888209110963615,
  properties: {
    r'module': PropertySchema(id: 0, name: r'module', type: IsarType.string),
    r'portalId': PropertySchema(
      id: 1,
      name: r'portalId',
      type: IsarType.string,
    ),
    r'route': PropertySchema(id: 2, name: r'route', type: IsarType.string),
    r'scrollOffset': PropertySchema(
      id: 3,
      name: r'scrollOffset',
      type: IsarType.double,
    ),
    r'snippet': PropertySchema(id: 4, name: r'snippet', type: IsarType.string),
    r'title': PropertySchema(id: 5, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _readingSpotEstimateSize,
  serialize: _readingSpotSerialize,
  deserialize: _readingSpotDeserialize,
  deserializeProp: _readingSpotDeserializeProp,
  idName: r'id',
  indexes: {
    r'route': IndexSchema(
      id: 8686557153332962867,
      name: r'route',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'route',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'portalId': IndexSchema(
      id: 6254812357132493007,
      name: r'portalId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'portalId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _readingSpotGetId,
  getLinks: _readingSpotGetLinks,
  attach: _readingSpotAttach,
  version: '3.3.2',
);

int _readingSpotEstimateSize(
  ReadingSpot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.module.length * 3;
  bytesCount += 3 + object.portalId.length * 3;
  bytesCount += 3 + object.route.length * 3;
  bytesCount += 3 + object.snippet.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _readingSpotSerialize(
  ReadingSpot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.module);
  writer.writeString(offsets[1], object.portalId);
  writer.writeString(offsets[2], object.route);
  writer.writeDouble(offsets[3], object.scrollOffset);
  writer.writeString(offsets[4], object.snippet);
  writer.writeString(offsets[5], object.title);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

ReadingSpot _readingSpotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadingSpot();
  object.id = id;
  object.module = reader.readString(offsets[0]);
  object.portalId = reader.readString(offsets[1]);
  object.route = reader.readString(offsets[2]);
  object.scrollOffset = reader.readDouble(offsets[3]);
  object.snippet = reader.readString(offsets[4]);
  object.title = reader.readString(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _readingSpotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readingSpotGetId(ReadingSpot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readingSpotGetLinks(ReadingSpot object) {
  return [];
}

void _readingSpotAttach(
  IsarCollection<dynamic> col,
  Id id,
  ReadingSpot object,
) {
  object.id = id;
}

extension ReadingSpotByIndex on IsarCollection<ReadingSpot> {
  Future<ReadingSpot?> getByRoute(String route) {
    return getByIndex(r'route', [route]);
  }

  ReadingSpot? getByRouteSync(String route) {
    return getByIndexSync(r'route', [route]);
  }

  Future<bool> deleteByRoute(String route) {
    return deleteByIndex(r'route', [route]);
  }

  bool deleteByRouteSync(String route) {
    return deleteByIndexSync(r'route', [route]);
  }

  Future<List<ReadingSpot?>> getAllByRoute(List<String> routeValues) {
    final values = routeValues.map((e) => [e]).toList();
    return getAllByIndex(r'route', values);
  }

  List<ReadingSpot?> getAllByRouteSync(List<String> routeValues) {
    final values = routeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'route', values);
  }

  Future<int> deleteAllByRoute(List<String> routeValues) {
    final values = routeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'route', values);
  }

  int deleteAllByRouteSync(List<String> routeValues) {
    final values = routeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'route', values);
  }

  Future<Id> putByRoute(ReadingSpot object) {
    return putByIndex(r'route', object);
  }

  Id putByRouteSync(ReadingSpot object, {bool saveLinks = true}) {
    return putByIndexSync(r'route', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRoute(List<ReadingSpot> objects) {
    return putAllByIndex(r'route', objects);
  }

  List<Id> putAllByRouteSync(
    List<ReadingSpot> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'route', objects, saveLinks: saveLinks);
  }
}

extension ReadingSpotQueryWhereSort
    on QueryBuilder<ReadingSpot, ReadingSpot, QWhere> {
  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension ReadingSpotQueryWhere
    on QueryBuilder<ReadingSpot, ReadingSpot, QWhereClause> {
  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> idBetween(
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> routeEqualTo(
    String route,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'route', value: [route]),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> routeNotEqualTo(
    String route,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'route',
                lower: [],
                upper: [route],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'route',
                lower: [route],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'route',
                lower: [route],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'route',
                lower: [],
                upper: [route],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> portalIdEqualTo(
    String portalId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'portalId', value: [portalId]),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> portalIdNotEqualTo(
    String portalId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId',
                lower: [portalId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'portalId',
                lower: [],
                upper: [portalId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> updatedAtEqualTo(
    DateTime updatedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> updatedAtNotEqualTo(
    DateTime updatedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause>
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ReadingSpotQueryFilter
    on QueryBuilder<ReadingSpot, ReadingSpot, QFilterCondition> {
  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  moduleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'module',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  moduleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'module',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> moduleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'module',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  moduleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'module', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  moduleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'module', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> portalIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> portalIdBetween(
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> portalIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  portalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  portalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'portalId', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  routeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'route',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'route',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'route',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> routeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'route', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  routeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'route', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  scrollOffsetEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scrollOffset',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  scrollOffsetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scrollOffset',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  scrollOffsetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scrollOffset',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  scrollOffsetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scrollOffset',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  snippetGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snippet',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  snippetStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'snippet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> snippetMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'snippet',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  snippetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snippet', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  snippetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'snippet', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ReadingSpotQueryObject
    on QueryBuilder<ReadingSpot, ReadingSpot, QFilterCondition> {}

extension ReadingSpotQueryLinks
    on QueryBuilder<ReadingSpot, ReadingSpot, QFilterCondition> {}

extension ReadingSpotQuerySortBy
    on QueryBuilder<ReadingSpot, ReadingSpot, QSortBy> {
  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByModule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'module', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByModuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'module', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByRoute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'route', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByRouteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'route', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByScrollOffset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollOffset', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy>
  sortByScrollOffsetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollOffset', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortBySnippet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snippet', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortBySnippetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snippet', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ReadingSpotQuerySortThenBy
    on QueryBuilder<ReadingSpot, ReadingSpot, QSortThenBy> {
  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByModule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'module', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByModuleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'module', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByPortalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByPortalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'portalId', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByRoute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'route', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByRouteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'route', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByScrollOffset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollOffset', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy>
  thenByScrollOffsetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollOffset', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenBySnippet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snippet', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenBySnippetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snippet', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ReadingSpotQueryWhereDistinct
    on QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> {
  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByModule({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'module', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByPortalId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'portalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByRoute({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'route', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByScrollOffset() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scrollOffset');
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctBySnippet({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snippet', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadingSpot, ReadingSpot, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ReadingSpotQueryProperty
    on QueryBuilder<ReadingSpot, ReadingSpot, QQueryProperty> {
  QueryBuilder<ReadingSpot, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadingSpot, String, QQueryOperations> moduleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'module');
    });
  }

  QueryBuilder<ReadingSpot, String, QQueryOperations> portalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'portalId');
    });
  }

  QueryBuilder<ReadingSpot, String, QQueryOperations> routeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'route');
    });
  }

  QueryBuilder<ReadingSpot, double, QQueryOperations> scrollOffsetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scrollOffset');
    });
  }

  QueryBuilder<ReadingSpot, String, QQueryOperations> snippetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snippet');
    });
  }

  QueryBuilder<ReadingSpot, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ReadingSpot, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
