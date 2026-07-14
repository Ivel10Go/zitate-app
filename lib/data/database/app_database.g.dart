// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $QuoteEntriesTable extends QuoteEntries
    with TableInfo<$QuoteEntriesTable, QuoteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuoteEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textDeMeta = const VerificationMeta('textDe');
  @override
  late final GeneratedColumn<String> textDe = GeneratedColumn<String>(
    'text_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textOriginalMeta = const VerificationMeta(
    'textOriginal',
  );
  @override
  late final GeneratedColumn<String> textOriginal = GeneratedColumn<String>(
    'text_original',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryCsvMeta = const VerificationMeta(
    'categoryCsv',
  );
  @override
  late final GeneratedColumn<String> categoryCsv = GeneratedColumn<String>(
    'category_csv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationShortMeta = const VerificationMeta(
    'explanationShort',
  );
  @override
  late final GeneratedColumn<String> explanationShort = GeneratedColumn<String>(
    'explanation_short',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationLongMeta = const VerificationMeta(
    'explanationLong',
  );
  @override
  late final GeneratedColumn<String> explanationLong = GeneratedColumn<String>(
    'explanation_long',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedIdsCsvMeta = const VerificationMeta(
    'relatedIdsCsv',
  );
  @override
  late final GeneratedColumn<String> relatedIdsCsv = GeneratedColumn<String>(
    'related_ids_csv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _funFactMeta = const VerificationMeta(
    'funFact',
  );
  @override
  late final GeneratedColumn<String> funFact = GeneratedColumn<String>(
    'fun_fact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    textDe,
    textOriginal,
    author,
    source,
    year,
    chapter,
    categoryCsv,
    difficulty,
    series,
    explanationShort,
    explanationLong,
    relatedIdsCsv,
    funFact,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuoteEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_de')) {
      context.handle(
        _textDeMeta,
        textDe.isAcceptableOrUnknown(data['text_de']!, _textDeMeta),
      );
    } else if (isInserting) {
      context.missing(_textDeMeta);
    }
    if (data.containsKey('text_original')) {
      context.handle(
        _textOriginalMeta,
        textOriginal.isAcceptableOrUnknown(
          data['text_original']!,
          _textOriginalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textOriginalMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('category_csv')) {
      context.handle(
        _categoryCsvMeta,
        categoryCsv.isAcceptableOrUnknown(
          data['category_csv']!,
          _categoryCsvMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryCsvMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesMeta);
    }
    if (data.containsKey('explanation_short')) {
      context.handle(
        _explanationShortMeta,
        explanationShort.isAcceptableOrUnknown(
          data['explanation_short']!,
          _explanationShortMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationShortMeta);
    }
    if (data.containsKey('explanation_long')) {
      context.handle(
        _explanationLongMeta,
        explanationLong.isAcceptableOrUnknown(
          data['explanation_long']!,
          _explanationLongMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationLongMeta);
    }
    if (data.containsKey('related_ids_csv')) {
      context.handle(
        _relatedIdsCsvMeta,
        relatedIdsCsv.isAcceptableOrUnknown(
          data['related_ids_csv']!,
          _relatedIdsCsvMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedIdsCsvMeta);
    }
    if (data.containsKey('fun_fact')) {
      context.handle(
        _funFactMeta,
        funFact.isAcceptableOrUnknown(data['fun_fact']!, _funFactMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuoteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      textDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_de'],
      )!,
      textOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_original'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter'],
      )!,
      categoryCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_csv'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      )!,
      explanationShort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_short'],
      )!,
      explanationLong: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_long'],
      )!,
      relatedIdsCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_ids_csv'],
      )!,
      funFact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fun_fact'],
      ),
    );
  }

  @override
  $QuoteEntriesTable createAlias(String alias) {
    return $QuoteEntriesTable(attachedDatabase, alias);
  }
}

class QuoteEntry extends DataClass implements Insertable<QuoteEntry> {
  final String id;
  final String textDe;
  final String textOriginal;

  /// The person a quote is attributed to. Distinct from [source], which is the
  /// work it appears in ("Das Kapital Band 1", "Menon"). Defaults to empty so
  /// rows written before schema v6 stay readable until the seed backfills them;
  /// use `quoteAuthorLabel()` rather than reading this directly.
  final String author;
  final String source;
  final int year;
  final String chapter;
  final String categoryCsv;
  final String difficulty;
  final String series;
  final String explanationShort;
  final String explanationLong;
  final String relatedIdsCsv;
  final String? funFact;
  const QuoteEntry({
    required this.id,
    required this.textDe,
    required this.textOriginal,
    required this.author,
    required this.source,
    required this.year,
    required this.chapter,
    required this.categoryCsv,
    required this.difficulty,
    required this.series,
    required this.explanationShort,
    required this.explanationLong,
    required this.relatedIdsCsv,
    this.funFact,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_de'] = Variable<String>(textDe);
    map['text_original'] = Variable<String>(textOriginal);
    map['author'] = Variable<String>(author);
    map['source'] = Variable<String>(source);
    map['year'] = Variable<int>(year);
    map['chapter'] = Variable<String>(chapter);
    map['category_csv'] = Variable<String>(categoryCsv);
    map['difficulty'] = Variable<String>(difficulty);
    map['series'] = Variable<String>(series);
    map['explanation_short'] = Variable<String>(explanationShort);
    map['explanation_long'] = Variable<String>(explanationLong);
    map['related_ids_csv'] = Variable<String>(relatedIdsCsv);
    if (!nullToAbsent || funFact != null) {
      map['fun_fact'] = Variable<String>(funFact);
    }
    return map;
  }

  QuoteEntriesCompanion toCompanion(bool nullToAbsent) {
    return QuoteEntriesCompanion(
      id: Value(id),
      textDe: Value(textDe),
      textOriginal: Value(textOriginal),
      author: Value(author),
      source: Value(source),
      year: Value(year),
      chapter: Value(chapter),
      categoryCsv: Value(categoryCsv),
      difficulty: Value(difficulty),
      series: Value(series),
      explanationShort: Value(explanationShort),
      explanationLong: Value(explanationLong),
      relatedIdsCsv: Value(relatedIdsCsv),
      funFact: funFact == null && nullToAbsent
          ? const Value.absent()
          : Value(funFact),
    );
  }

  factory QuoteEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteEntry(
      id: serializer.fromJson<String>(json['id']),
      textDe: serializer.fromJson<String>(json['textDe']),
      textOriginal: serializer.fromJson<String>(json['textOriginal']),
      author: serializer.fromJson<String>(json['author']),
      source: serializer.fromJson<String>(json['source']),
      year: serializer.fromJson<int>(json['year']),
      chapter: serializer.fromJson<String>(json['chapter']),
      categoryCsv: serializer.fromJson<String>(json['categoryCsv']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      series: serializer.fromJson<String>(json['series']),
      explanationShort: serializer.fromJson<String>(json['explanationShort']),
      explanationLong: serializer.fromJson<String>(json['explanationLong']),
      relatedIdsCsv: serializer.fromJson<String>(json['relatedIdsCsv']),
      funFact: serializer.fromJson<String?>(json['funFact']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textDe': serializer.toJson<String>(textDe),
      'textOriginal': serializer.toJson<String>(textOriginal),
      'author': serializer.toJson<String>(author),
      'source': serializer.toJson<String>(source),
      'year': serializer.toJson<int>(year),
      'chapter': serializer.toJson<String>(chapter),
      'categoryCsv': serializer.toJson<String>(categoryCsv),
      'difficulty': serializer.toJson<String>(difficulty),
      'series': serializer.toJson<String>(series),
      'explanationShort': serializer.toJson<String>(explanationShort),
      'explanationLong': serializer.toJson<String>(explanationLong),
      'relatedIdsCsv': serializer.toJson<String>(relatedIdsCsv),
      'funFact': serializer.toJson<String?>(funFact),
    };
  }

  QuoteEntry copyWith({
    String? id,
    String? textDe,
    String? textOriginal,
    String? author,
    String? source,
    int? year,
    String? chapter,
    String? categoryCsv,
    String? difficulty,
    String? series,
    String? explanationShort,
    String? explanationLong,
    String? relatedIdsCsv,
    Value<String?> funFact = const Value.absent(),
  }) => QuoteEntry(
    id: id ?? this.id,
    textDe: textDe ?? this.textDe,
    textOriginal: textOriginal ?? this.textOriginal,
    author: author ?? this.author,
    source: source ?? this.source,
    year: year ?? this.year,
    chapter: chapter ?? this.chapter,
    categoryCsv: categoryCsv ?? this.categoryCsv,
    difficulty: difficulty ?? this.difficulty,
    series: series ?? this.series,
    explanationShort: explanationShort ?? this.explanationShort,
    explanationLong: explanationLong ?? this.explanationLong,
    relatedIdsCsv: relatedIdsCsv ?? this.relatedIdsCsv,
    funFact: funFact.present ? funFact.value : this.funFact,
  );
  QuoteEntry copyWithCompanion(QuoteEntriesCompanion data) {
    return QuoteEntry(
      id: data.id.present ? data.id.value : this.id,
      textDe: data.textDe.present ? data.textDe.value : this.textDe,
      textOriginal: data.textOriginal.present
          ? data.textOriginal.value
          : this.textOriginal,
      author: data.author.present ? data.author.value : this.author,
      source: data.source.present ? data.source.value : this.source,
      year: data.year.present ? data.year.value : this.year,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      categoryCsv: data.categoryCsv.present
          ? data.categoryCsv.value
          : this.categoryCsv,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      series: data.series.present ? data.series.value : this.series,
      explanationShort: data.explanationShort.present
          ? data.explanationShort.value
          : this.explanationShort,
      explanationLong: data.explanationLong.present
          ? data.explanationLong.value
          : this.explanationLong,
      relatedIdsCsv: data.relatedIdsCsv.present
          ? data.relatedIdsCsv.value
          : this.relatedIdsCsv,
      funFact: data.funFact.present ? data.funFact.value : this.funFact,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteEntry(')
          ..write('id: $id, ')
          ..write('textDe: $textDe, ')
          ..write('textOriginal: $textOriginal, ')
          ..write('author: $author, ')
          ..write('source: $source, ')
          ..write('year: $year, ')
          ..write('chapter: $chapter, ')
          ..write('categoryCsv: $categoryCsv, ')
          ..write('difficulty: $difficulty, ')
          ..write('series: $series, ')
          ..write('explanationShort: $explanationShort, ')
          ..write('explanationLong: $explanationLong, ')
          ..write('relatedIdsCsv: $relatedIdsCsv, ')
          ..write('funFact: $funFact')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    textDe,
    textOriginal,
    author,
    source,
    year,
    chapter,
    categoryCsv,
    difficulty,
    series,
    explanationShort,
    explanationLong,
    relatedIdsCsv,
    funFact,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteEntry &&
          other.id == this.id &&
          other.textDe == this.textDe &&
          other.textOriginal == this.textOriginal &&
          other.author == this.author &&
          other.source == this.source &&
          other.year == this.year &&
          other.chapter == this.chapter &&
          other.categoryCsv == this.categoryCsv &&
          other.difficulty == this.difficulty &&
          other.series == this.series &&
          other.explanationShort == this.explanationShort &&
          other.explanationLong == this.explanationLong &&
          other.relatedIdsCsv == this.relatedIdsCsv &&
          other.funFact == this.funFact);
}

class QuoteEntriesCompanion extends UpdateCompanion<QuoteEntry> {
  final Value<String> id;
  final Value<String> textDe;
  final Value<String> textOriginal;
  final Value<String> author;
  final Value<String> source;
  final Value<int> year;
  final Value<String> chapter;
  final Value<String> categoryCsv;
  final Value<String> difficulty;
  final Value<String> series;
  final Value<String> explanationShort;
  final Value<String> explanationLong;
  final Value<String> relatedIdsCsv;
  final Value<String?> funFact;
  final Value<int> rowid;
  const QuoteEntriesCompanion({
    this.id = const Value.absent(),
    this.textDe = const Value.absent(),
    this.textOriginal = const Value.absent(),
    this.author = const Value.absent(),
    this.source = const Value.absent(),
    this.year = const Value.absent(),
    this.chapter = const Value.absent(),
    this.categoryCsv = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.series = const Value.absent(),
    this.explanationShort = const Value.absent(),
    this.explanationLong = const Value.absent(),
    this.relatedIdsCsv = const Value.absent(),
    this.funFact = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuoteEntriesCompanion.insert({
    required String id,
    required String textDe,
    required String textOriginal,
    this.author = const Value.absent(),
    required String source,
    required int year,
    required String chapter,
    required String categoryCsv,
    required String difficulty,
    required String series,
    required String explanationShort,
    required String explanationLong,
    required String relatedIdsCsv,
    this.funFact = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textDe = Value(textDe),
       textOriginal = Value(textOriginal),
       source = Value(source),
       year = Value(year),
       chapter = Value(chapter),
       categoryCsv = Value(categoryCsv),
       difficulty = Value(difficulty),
       series = Value(series),
       explanationShort = Value(explanationShort),
       explanationLong = Value(explanationLong),
       relatedIdsCsv = Value(relatedIdsCsv);
  static Insertable<QuoteEntry> custom({
    Expression<String>? id,
    Expression<String>? textDe,
    Expression<String>? textOriginal,
    Expression<String>? author,
    Expression<String>? source,
    Expression<int>? year,
    Expression<String>? chapter,
    Expression<String>? categoryCsv,
    Expression<String>? difficulty,
    Expression<String>? series,
    Expression<String>? explanationShort,
    Expression<String>? explanationLong,
    Expression<String>? relatedIdsCsv,
    Expression<String>? funFact,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textDe != null) 'text_de': textDe,
      if (textOriginal != null) 'text_original': textOriginal,
      if (author != null) 'author': author,
      if (source != null) 'source': source,
      if (year != null) 'year': year,
      if (chapter != null) 'chapter': chapter,
      if (categoryCsv != null) 'category_csv': categoryCsv,
      if (difficulty != null) 'difficulty': difficulty,
      if (series != null) 'series': series,
      if (explanationShort != null) 'explanation_short': explanationShort,
      if (explanationLong != null) 'explanation_long': explanationLong,
      if (relatedIdsCsv != null) 'related_ids_csv': relatedIdsCsv,
      if (funFact != null) 'fun_fact': funFact,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuoteEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? textDe,
    Value<String>? textOriginal,
    Value<String>? author,
    Value<String>? source,
    Value<int>? year,
    Value<String>? chapter,
    Value<String>? categoryCsv,
    Value<String>? difficulty,
    Value<String>? series,
    Value<String>? explanationShort,
    Value<String>? explanationLong,
    Value<String>? relatedIdsCsv,
    Value<String?>? funFact,
    Value<int>? rowid,
  }) {
    return QuoteEntriesCompanion(
      id: id ?? this.id,
      textDe: textDe ?? this.textDe,
      textOriginal: textOriginal ?? this.textOriginal,
      author: author ?? this.author,
      source: source ?? this.source,
      year: year ?? this.year,
      chapter: chapter ?? this.chapter,
      categoryCsv: categoryCsv ?? this.categoryCsv,
      difficulty: difficulty ?? this.difficulty,
      series: series ?? this.series,
      explanationShort: explanationShort ?? this.explanationShort,
      explanationLong: explanationLong ?? this.explanationLong,
      relatedIdsCsv: relatedIdsCsv ?? this.relatedIdsCsv,
      funFact: funFact ?? this.funFact,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textDe.present) {
      map['text_de'] = Variable<String>(textDe.value);
    }
    if (textOriginal.present) {
      map['text_original'] = Variable<String>(textOriginal.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (categoryCsv.present) {
      map['category_csv'] = Variable<String>(categoryCsv.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (explanationShort.present) {
      map['explanation_short'] = Variable<String>(explanationShort.value);
    }
    if (explanationLong.present) {
      map['explanation_long'] = Variable<String>(explanationLong.value);
    }
    if (relatedIdsCsv.present) {
      map['related_ids_csv'] = Variable<String>(relatedIdsCsv.value);
    }
    if (funFact.present) {
      map['fun_fact'] = Variable<String>(funFact.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuoteEntriesCompanion(')
          ..write('id: $id, ')
          ..write('textDe: $textDe, ')
          ..write('textOriginal: $textOriginal, ')
          ..write('author: $author, ')
          ..write('source: $source, ')
          ..write('year: $year, ')
          ..write('chapter: $chapter, ')
          ..write('categoryCsv: $categoryCsv, ')
          ..write('difficulty: $difficulty, ')
          ..write('series: $series, ')
          ..write('explanationShort: $explanationShort, ')
          ..write('explanationLong: $explanationLong, ')
          ..write('relatedIdsCsv: $relatedIdsCsv, ')
          ..write('funFact: $funFact, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _quoteIdMeta = const VerificationMeta(
    'quoteId',
  );
  @override
  late final GeneratedColumn<String> quoteId = GeneratedColumn<String>(
    'quote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, quoteId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('quote_id')) {
      context.handle(
        _quoteIdMeta,
        quoteId.isAcceptableOrUnknown(data['quote_id']!, _quoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      quoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String quoteId;
  final DateTime createdAt;
  const Favorite({
    required this.id,
    required this.quoteId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['quote_id'] = Variable<String>(quoteId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      quoteId: Value(quoteId),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      quoteId: serializer.fromJson<String>(json['quoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'quoteId': serializer.toJson<String>(quoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({int? id, String? quoteId, DateTime? createdAt}) =>
      Favorite(
        id: id ?? this.id,
        quoteId: quoteId ?? this.quoteId,
        createdAt: createdAt ?? this.createdAt,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      quoteId: data.quoteId.present ? data.quoteId.value : this.quoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('quoteId: $quoteId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, quoteId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.quoteId == this.quoteId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> quoteId;
  final Value<DateTime> createdAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.quoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String quoteId,
    this.createdAt = const Value.absent(),
  }) : quoteId = Value(quoteId);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? quoteId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (quoteId != null) 'quote_id': quoteId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? quoteId,
    Value<DateTime>? createdAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (quoteId.present) {
      map['quote_id'] = Variable<String>(quoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('quoteId: $quoteId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SeenQuotesTable extends SeenQuotes
    with TableInfo<$SeenQuotesTable, SeenQuote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeenQuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _quoteIdMeta = const VerificationMeta(
    'quoteId',
  );
  @override
  late final GeneratedColumn<String> quoteId = GeneratedColumn<String>(
    'quote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<DateTime> seenAt = GeneratedColumn<DateTime>(
    'seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, quoteId, seenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen_quotes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeenQuote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('quote_id')) {
      context.handle(
        _quoteIdMeta,
        quoteId.isAcceptableOrUnknown(data['quote_id']!, _quoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteIdMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeenQuote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenQuote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      quoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_id'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}seen_at'],
      )!,
    );
  }

  @override
  $SeenQuotesTable createAlias(String alias) {
    return $SeenQuotesTable(attachedDatabase, alias);
  }
}

class SeenQuote extends DataClass implements Insertable<SeenQuote> {
  final int id;
  final String quoteId;
  final DateTime seenAt;
  const SeenQuote({
    required this.id,
    required this.quoteId,
    required this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['quote_id'] = Variable<String>(quoteId);
    map['seen_at'] = Variable<DateTime>(seenAt);
    return map;
  }

  SeenQuotesCompanion toCompanion(bool nullToAbsent) {
    return SeenQuotesCompanion(
      id: Value(id),
      quoteId: Value(quoteId),
      seenAt: Value(seenAt),
    );
  }

  factory SeenQuote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenQuote(
      id: serializer.fromJson<int>(json['id']),
      quoteId: serializer.fromJson<String>(json['quoteId']),
      seenAt: serializer.fromJson<DateTime>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'quoteId': serializer.toJson<String>(quoteId),
      'seenAt': serializer.toJson<DateTime>(seenAt),
    };
  }

  SeenQuote copyWith({int? id, String? quoteId, DateTime? seenAt}) => SeenQuote(
    id: id ?? this.id,
    quoteId: quoteId ?? this.quoteId,
    seenAt: seenAt ?? this.seenAt,
  );
  SeenQuote copyWithCompanion(SeenQuotesCompanion data) {
    return SeenQuote(
      id: data.id.present ? data.id.value : this.id,
      quoteId: data.quoteId.present ? data.quoteId.value : this.quoteId,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenQuote(')
          ..write('id: $id, ')
          ..write('quoteId: $quoteId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, quoteId, seenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenQuote &&
          other.id == this.id &&
          other.quoteId == this.quoteId &&
          other.seenAt == this.seenAt);
}

class SeenQuotesCompanion extends UpdateCompanion<SeenQuote> {
  final Value<int> id;
  final Value<String> quoteId;
  final Value<DateTime> seenAt;
  const SeenQuotesCompanion({
    this.id = const Value.absent(),
    this.quoteId = const Value.absent(),
    this.seenAt = const Value.absent(),
  });
  SeenQuotesCompanion.insert({
    this.id = const Value.absent(),
    required String quoteId,
    this.seenAt = const Value.absent(),
  }) : quoteId = Value(quoteId);
  static Insertable<SeenQuote> custom({
    Expression<int>? id,
    Expression<String>? quoteId,
    Expression<DateTime>? seenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (quoteId != null) 'quote_id': quoteId,
      if (seenAt != null) 'seen_at': seenAt,
    });
  }

  SeenQuotesCompanion copyWith({
    Value<int>? id,
    Value<String>? quoteId,
    Value<DateTime>? seenAt,
  }) {
    return SeenQuotesCompanion(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      seenAt: seenAt ?? this.seenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (quoteId.present) {
      map['quote_id'] = Variable<String>(quoteId.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<DateTime>(seenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeenQuotesCompanion(')
          ..write('id: $id, ')
          ..write('quoteId: $quoteId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }
}

class $AppOpenLogTable extends AppOpenLog
    with TableInfo<$AppOpenLogTable, AppOpenLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppOpenLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, openedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_open_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppOpenLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppOpenLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppOpenLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
    );
  }

  @override
  $AppOpenLogTable createAlias(String alias) {
    return $AppOpenLogTable(attachedDatabase, alias);
  }
}

class AppOpenLogData extends DataClass implements Insertable<AppOpenLogData> {
  final int id;
  final DateTime openedAt;
  const AppOpenLogData({required this.id, required this.openedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['opened_at'] = Variable<DateTime>(openedAt);
    return map;
  }

  AppOpenLogCompanion toCompanion(bool nullToAbsent) {
    return AppOpenLogCompanion(id: Value(id), openedAt: Value(openedAt));
  }

  factory AppOpenLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppOpenLogData(
      id: serializer.fromJson<int>(json['id']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'openedAt': serializer.toJson<DateTime>(openedAt),
    };
  }

  AppOpenLogData copyWith({int? id, DateTime? openedAt}) =>
      AppOpenLogData(id: id ?? this.id, openedAt: openedAt ?? this.openedAt);
  AppOpenLogData copyWithCompanion(AppOpenLogCompanion data) {
    return AppOpenLogData(
      id: data.id.present ? data.id.value : this.id,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppOpenLogData(')
          ..write('id: $id, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppOpenLogData &&
          other.id == this.id &&
          other.openedAt == this.openedAt);
}

class AppOpenLogCompanion extends UpdateCompanion<AppOpenLogData> {
  final Value<int> id;
  final Value<DateTime> openedAt;
  const AppOpenLogCompanion({
    this.id = const Value.absent(),
    this.openedAt = const Value.absent(),
  });
  AppOpenLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime openedAt,
  }) : openedAt = Value(openedAt);
  static Insertable<AppOpenLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? openedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (openedAt != null) 'opened_at': openedAt,
    });
  }

  AppOpenLogCompanion copyWith({Value<int>? id, Value<DateTime>? openedAt}) {
    return AppOpenLogCompanion(
      id: id ?? this.id,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppOpenLogCompanion(')
          ..write('id: $id, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuoteEntriesTable quoteEntries = $QuoteEntriesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $SeenQuotesTable seenQuotes = $SeenQuotesTable(this);
  late final $AppOpenLogTable appOpenLog = $AppOpenLogTable(this);
  late final QuoteDao quoteDao = QuoteDao(this as AppDatabase);
  late final AppOpenLogDao appOpenLogDao = AppOpenLogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    quoteEntries,
    favorites,
    seenQuotes,
    appOpenLog,
  ];
}

typedef $$QuoteEntriesTableCreateCompanionBuilder =
    QuoteEntriesCompanion Function({
      required String id,
      required String textDe,
      required String textOriginal,
      Value<String> author,
      required String source,
      required int year,
      required String chapter,
      required String categoryCsv,
      required String difficulty,
      required String series,
      required String explanationShort,
      required String explanationLong,
      required String relatedIdsCsv,
      Value<String?> funFact,
      Value<int> rowid,
    });
typedef $$QuoteEntriesTableUpdateCompanionBuilder =
    QuoteEntriesCompanion Function({
      Value<String> id,
      Value<String> textDe,
      Value<String> textOriginal,
      Value<String> author,
      Value<String> source,
      Value<int> year,
      Value<String> chapter,
      Value<String> categoryCsv,
      Value<String> difficulty,
      Value<String> series,
      Value<String> explanationShort,
      Value<String> explanationLong,
      Value<String> relatedIdsCsv,
      Value<String?> funFact,
      Value<int> rowid,
    });

class $$QuoteEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QuoteEntriesTable> {
  $$QuoteEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textDe => $composableBuilder(
    column: $table.textDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textOriginal => $composableBuilder(
    column: $table.textOriginal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryCsv => $composableBuilder(
    column: $table.categoryCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationShort => $composableBuilder(
    column: $table.explanationShort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationLong => $composableBuilder(
    column: $table.explanationLong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedIdsCsv => $composableBuilder(
    column: $table.relatedIdsCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get funFact => $composableBuilder(
    column: $table.funFact,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuoteEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuoteEntriesTable> {
  $$QuoteEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textDe => $composableBuilder(
    column: $table.textDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textOriginal => $composableBuilder(
    column: $table.textOriginal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryCsv => $composableBuilder(
    column: $table.categoryCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationShort => $composableBuilder(
    column: $table.explanationShort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationLong => $composableBuilder(
    column: $table.explanationLong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedIdsCsv => $composableBuilder(
    column: $table.relatedIdsCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get funFact => $composableBuilder(
    column: $table.funFact,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuoteEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuoteEntriesTable> {
  $$QuoteEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textDe =>
      $composableBuilder(column: $table.textDe, builder: (column) => column);

  GeneratedColumn<String> get textOriginal => $composableBuilder(
    column: $table.textOriginal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get categoryCsv => $composableBuilder(
    column: $table.categoryCsv,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get explanationShort => $composableBuilder(
    column: $table.explanationShort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationLong => $composableBuilder(
    column: $table.explanationLong,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedIdsCsv => $composableBuilder(
    column: $table.relatedIdsCsv,
    builder: (column) => column,
  );

  GeneratedColumn<String> get funFact =>
      $composableBuilder(column: $table.funFact, builder: (column) => column);
}

class $$QuoteEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuoteEntriesTable,
          QuoteEntry,
          $$QuoteEntriesTableFilterComposer,
          $$QuoteEntriesTableOrderingComposer,
          $$QuoteEntriesTableAnnotationComposer,
          $$QuoteEntriesTableCreateCompanionBuilder,
          $$QuoteEntriesTableUpdateCompanionBuilder,
          (
            QuoteEntry,
            BaseReferences<_$AppDatabase, $QuoteEntriesTable, QuoteEntry>,
          ),
          QuoteEntry,
          PrefetchHooks Function()
        > {
  $$QuoteEntriesTableTableManager(_$AppDatabase db, $QuoteEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuoteEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuoteEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuoteEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> textDe = const Value.absent(),
                Value<String> textOriginal = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> chapter = const Value.absent(),
                Value<String> categoryCsv = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> series = const Value.absent(),
                Value<String> explanationShort = const Value.absent(),
                Value<String> explanationLong = const Value.absent(),
                Value<String> relatedIdsCsv = const Value.absent(),
                Value<String?> funFact = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuoteEntriesCompanion(
                id: id,
                textDe: textDe,
                textOriginal: textOriginal,
                author: author,
                source: source,
                year: year,
                chapter: chapter,
                categoryCsv: categoryCsv,
                difficulty: difficulty,
                series: series,
                explanationShort: explanationShort,
                explanationLong: explanationLong,
                relatedIdsCsv: relatedIdsCsv,
                funFact: funFact,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String textDe,
                required String textOriginal,
                Value<String> author = const Value.absent(),
                required String source,
                required int year,
                required String chapter,
                required String categoryCsv,
                required String difficulty,
                required String series,
                required String explanationShort,
                required String explanationLong,
                required String relatedIdsCsv,
                Value<String?> funFact = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuoteEntriesCompanion.insert(
                id: id,
                textDe: textDe,
                textOriginal: textOriginal,
                author: author,
                source: source,
                year: year,
                chapter: chapter,
                categoryCsv: categoryCsv,
                difficulty: difficulty,
                series: series,
                explanationShort: explanationShort,
                explanationLong: explanationLong,
                relatedIdsCsv: relatedIdsCsv,
                funFact: funFact,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuoteEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuoteEntriesTable,
      QuoteEntry,
      $$QuoteEntriesTableFilterComposer,
      $$QuoteEntriesTableOrderingComposer,
      $$QuoteEntriesTableAnnotationComposer,
      $$QuoteEntriesTableCreateCompanionBuilder,
      $$QuoteEntriesTableUpdateCompanionBuilder,
      (
        QuoteEntry,
        BaseReferences<_$AppDatabase, $QuoteEntriesTable, QuoteEntry>,
      ),
      QuoteEntry,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required String quoteId,
      Value<DateTime> createdAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<String> quoteId,
      Value<DateTime> createdAt,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteId => $composableBuilder(
    column: $table.quoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteId => $composableBuilder(
    column: $table.quoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get quoteId =>
      $composableBuilder(column: $table.quoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> quoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                quoteId: quoteId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String quoteId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                quoteId: quoteId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$SeenQuotesTableCreateCompanionBuilder =
    SeenQuotesCompanion Function({
      Value<int> id,
      required String quoteId,
      Value<DateTime> seenAt,
    });
typedef $$SeenQuotesTableUpdateCompanionBuilder =
    SeenQuotesCompanion Function({
      Value<int> id,
      Value<String> quoteId,
      Value<DateTime> seenAt,
    });

class $$SeenQuotesTableFilterComposer
    extends Composer<_$AppDatabase, $SeenQuotesTable> {
  $$SeenQuotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteId => $composableBuilder(
    column: $table.quoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeenQuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $SeenQuotesTable> {
  $$SeenQuotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteId => $composableBuilder(
    column: $table.quoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeenQuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeenQuotesTable> {
  $$SeenQuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get quoteId =>
      $composableBuilder(column: $table.quoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);
}

class $$SeenQuotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeenQuotesTable,
          SeenQuote,
          $$SeenQuotesTableFilterComposer,
          $$SeenQuotesTableOrderingComposer,
          $$SeenQuotesTableAnnotationComposer,
          $$SeenQuotesTableCreateCompanionBuilder,
          $$SeenQuotesTableUpdateCompanionBuilder,
          (
            SeenQuote,
            BaseReferences<_$AppDatabase, $SeenQuotesTable, SeenQuote>,
          ),
          SeenQuote,
          PrefetchHooks Function()
        > {
  $$SeenQuotesTableTableManager(_$AppDatabase db, $SeenQuotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeenQuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeenQuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeenQuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> quoteId = const Value.absent(),
                Value<DateTime> seenAt = const Value.absent(),
              }) =>
                  SeenQuotesCompanion(id: id, quoteId: quoteId, seenAt: seenAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String quoteId,
                Value<DateTime> seenAt = const Value.absent(),
              }) => SeenQuotesCompanion.insert(
                id: id,
                quoteId: quoteId,
                seenAt: seenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeenQuotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeenQuotesTable,
      SeenQuote,
      $$SeenQuotesTableFilterComposer,
      $$SeenQuotesTableOrderingComposer,
      $$SeenQuotesTableAnnotationComposer,
      $$SeenQuotesTableCreateCompanionBuilder,
      $$SeenQuotesTableUpdateCompanionBuilder,
      (SeenQuote, BaseReferences<_$AppDatabase, $SeenQuotesTable, SeenQuote>),
      SeenQuote,
      PrefetchHooks Function()
    >;
typedef $$AppOpenLogTableCreateCompanionBuilder =
    AppOpenLogCompanion Function({Value<int> id, required DateTime openedAt});
typedef $$AppOpenLogTableUpdateCompanionBuilder =
    AppOpenLogCompanion Function({Value<int> id, Value<DateTime> openedAt});

class $$AppOpenLogTableFilterComposer
    extends Composer<_$AppDatabase, $AppOpenLogTable> {
  $$AppOpenLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppOpenLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AppOpenLogTable> {
  $$AppOpenLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppOpenLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppOpenLogTable> {
  $$AppOpenLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);
}

class $$AppOpenLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppOpenLogTable,
          AppOpenLogData,
          $$AppOpenLogTableFilterComposer,
          $$AppOpenLogTableOrderingComposer,
          $$AppOpenLogTableAnnotationComposer,
          $$AppOpenLogTableCreateCompanionBuilder,
          $$AppOpenLogTableUpdateCompanionBuilder,
          (
            AppOpenLogData,
            BaseReferences<_$AppDatabase, $AppOpenLogTable, AppOpenLogData>,
          ),
          AppOpenLogData,
          PrefetchHooks Function()
        > {
  $$AppOpenLogTableTableManager(_$AppDatabase db, $AppOpenLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppOpenLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppOpenLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppOpenLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
              }) => AppOpenLogCompanion(id: id, openedAt: openedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime openedAt,
              }) => AppOpenLogCompanion.insert(id: id, openedAt: openedAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppOpenLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppOpenLogTable,
      AppOpenLogData,
      $$AppOpenLogTableFilterComposer,
      $$AppOpenLogTableOrderingComposer,
      $$AppOpenLogTableAnnotationComposer,
      $$AppOpenLogTableCreateCompanionBuilder,
      $$AppOpenLogTableUpdateCompanionBuilder,
      (
        AppOpenLogData,
        BaseReferences<_$AppDatabase, $AppOpenLogTable, AppOpenLogData>,
      ),
      AppOpenLogData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuoteEntriesTableTableManager get quoteEntries =>
      $$QuoteEntriesTableTableManager(_db, _db.quoteEntries);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$SeenQuotesTableTableManager get seenQuotes =>
      $$SeenQuotesTableTableManager(_db, _db.seenQuotes);
  $$AppOpenLogTableTableManager get appOpenLog =>
      $$AppOpenLogTableTableManager(_db, _db.appOpenLog);
}

mixin _$QuoteDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuoteEntriesTable get quoteEntries => attachedDatabase.quoteEntries;
  $FavoritesTable get favorites => attachedDatabase.favorites;
  $SeenQuotesTable get seenQuotes => attachedDatabase.seenQuotes;
}
mixin _$AppOpenLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppOpenLogTable get appOpenLog => attachedDatabase.appOpenLog;
}
