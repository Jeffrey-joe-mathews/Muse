// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_preset_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRadioPresetEntityCollection on Isar {
  IsarCollection<RadioPresetEntity> get radioPresetEntitys => this.collection();
}

const RadioPresetEntitySchema = CollectionSchema(
  name: r'RadioPresetEntity',
  id: -2176314192428478923,
  properties: {
    r'albumArt': PropertySchema(
      id: 0,
      name: r'albumArt',
      type: IsarType.string,
    ),
    r'artist': PropertySchema(
      id: 1,
      name: r'artist',
      type: IsarType.string,
    ),
    r'audioURL': PropertySchema(
      id: 2,
      name: r'audioURL',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 3,
      name: r'source',
      type: IsarType.string,
    ),
    r'stationId': PropertySchema(
      id: 4,
      name: r'stationId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 5,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _radioPresetEntityEstimateSize,
  serialize: _radioPresetEntitySerialize,
  deserialize: _radioPresetEntityDeserialize,
  deserializeProp: _radioPresetEntityDeserializeProp,
  idName: r'slotIndex',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _radioPresetEntityGetId,
  getLinks: _radioPresetEntityGetLinks,
  attach: _radioPresetEntityAttach,
  version: '3.1.0+1',
);

int _radioPresetEntityEstimateSize(
  RadioPresetEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.albumArt.length * 3;
  bytesCount += 3 + object.artist.length * 3;
  bytesCount += 3 + object.audioURL.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.stationId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _radioPresetEntitySerialize(
  RadioPresetEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.albumArt);
  writer.writeString(offsets[1], object.artist);
  writer.writeString(offsets[2], object.audioURL);
  writer.writeString(offsets[3], object.source);
  writer.writeString(offsets[4], object.stationId);
  writer.writeString(offsets[5], object.title);
}

RadioPresetEntity _radioPresetEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RadioPresetEntity();
  object.albumArt = reader.readString(offsets[0]);
  object.artist = reader.readString(offsets[1]);
  object.audioURL = reader.readString(offsets[2]);
  object.slotIndex = id;
  object.source = reader.readString(offsets[3]);
  object.stationId = reader.readString(offsets[4]);
  object.title = reader.readString(offsets[5]);
  return object;
}

P _radioPresetEntityDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _radioPresetEntityGetId(RadioPresetEntity object) {
  return object.slotIndex;
}

List<IsarLinkBase<dynamic>> _radioPresetEntityGetLinks(
    RadioPresetEntity object) {
  return [];
}

void _radioPresetEntityAttach(
    IsarCollection<dynamic> col, Id id, RadioPresetEntity object) {
  object.slotIndex = id;
}

extension RadioPresetEntityQueryWhereSort
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QWhere> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhere>
      anySlotIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RadioPresetEntityQueryWhere
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QWhereClause> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhereClause>
      slotIndexEqualTo(Id slotIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: slotIndex,
        upper: slotIndex,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhereClause>
      slotIndexNotEqualTo(Id slotIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: slotIndex, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: slotIndex, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: slotIndex, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: slotIndex, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhereClause>
      slotIndexGreaterThan(Id slotIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: slotIndex, includeLower: include),
      );
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhereClause>
      slotIndexLessThan(Id slotIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: slotIndex, includeUpper: include),
      );
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterWhereClause>
      slotIndexBetween(
    Id lowerSlotIndex,
    Id upperSlotIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerSlotIndex,
        includeLower: includeLower,
        upper: upperSlotIndex,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RadioPresetEntityQueryFilter
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QFilterCondition> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'albumArt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'albumArt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'albumArt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'albumArt',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      albumArtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'albumArt',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'artist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'artist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'artist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      artistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'artist',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioURL',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioURL',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioURL',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioURL',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      audioURLIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioURL',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      slotIndexEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      slotIndexGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      slotIndexLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      slotIndexBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slotIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      stationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension RadioPresetEntityQueryObject
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QFilterCondition> {}

extension RadioPresetEntityQueryLinks
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QFilterCondition> {}

extension RadioPresetEntityQuerySortBy
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QSortBy> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByAlbumArt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArt', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByAlbumArtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArt', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByAudioURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioURL', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByAudioURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioURL', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByStationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByStationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension RadioPresetEntityQuerySortThenBy
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QSortThenBy> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByAlbumArt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArt', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByAlbumArtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'albumArt', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artist', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByAudioURL() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioURL', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByAudioURLDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioURL', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenBySlotIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotIndex', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenBySlotIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotIndex', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByStationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByStationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.desc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension RadioPresetEntityQueryWhereDistinct
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct> {
  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct>
      distinctByAlbumArt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'albumArt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct>
      distinctByArtist({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artist', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct>
      distinctByAudioURL({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioURL', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct>
      distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct>
      distinctByStationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stationId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RadioPresetEntity, RadioPresetEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension RadioPresetEntityQueryProperty
    on QueryBuilder<RadioPresetEntity, RadioPresetEntity, QQueryProperty> {
  QueryBuilder<RadioPresetEntity, int, QQueryOperations> slotIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slotIndex');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations> albumArtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'albumArt');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations> artistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artist');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations> audioURLProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioURL');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations>
      stationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stationId');
    });
  }

  QueryBuilder<RadioPresetEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
