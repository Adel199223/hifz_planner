// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AyahTable extends Ayah with TableInfo<$AyahTable, AyahData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
      'surah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
      'ayah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textUthmaniMeta =
      const VerificationMeta('textUthmani');
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
      'text_uthmani', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageMadinaMeta =
      const VerificationMeta('pageMadina');
  @override
  late final GeneratedColumn<int> pageMadina = GeneratedColumn<int>(
      'page_madina', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, surah, ayah, textUthmani, pageMadina];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah';
  @override
  VerificationContext validateIntegrity(Insertable<AyahData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
          _surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
          _ayahMeta, ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta));
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('text_uthmani')) {
      context.handle(
          _textUthmaniMeta,
          textUthmani.isAcceptableOrUnknown(
              data['text_uthmani']!, _textUthmaniMeta));
    } else if (isInserting) {
      context.missing(_textUthmaniMeta);
    }
    if (data.containsKey('page_madina')) {
      context.handle(
          _pageMadinaMeta,
          pageMadina.isAcceptableOrUnknown(
              data['page_madina']!, _pageMadinaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {surah, ayah},
      ];
  @override
  AyahData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      surah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah'])!,
      ayah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah'])!,
      textUthmani: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_uthmani'])!,
      pageMadina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_madina']),
    );
  }

  @override
  $AyahTable createAlias(String alias) {
    return $AyahTable(attachedDatabase, alias);
  }
}

class AyahData extends DataClass implements Insertable<AyahData> {
  final int id;
  final int surah;
  final int ayah;
  final String textUthmani;
  final int? pageMadina;
  const AyahData(
      {required this.id,
      required this.surah,
      required this.ayah,
      required this.textUthmani,
      this.pageMadina});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['text_uthmani'] = Variable<String>(textUthmani);
    if (!nullToAbsent || pageMadina != null) {
      map['page_madina'] = Variable<int>(pageMadina);
    }
    return map;
  }

  AyahCompanion toCompanion(bool nullToAbsent) {
    return AyahCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      textUthmani: Value(textUthmani),
      pageMadina: pageMadina == null && nullToAbsent
          ? const Value.absent()
          : Value(pageMadina),
    );
  }

  factory AyahData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahData(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      pageMadina: serializer.fromJson<int?>(json['pageMadina']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'pageMadina': serializer.toJson<int?>(pageMadina),
    };
  }

  AyahData copyWith(
          {int? id,
          int? surah,
          int? ayah,
          String? textUthmani,
          Value<int?> pageMadina = const Value.absent()}) =>
      AyahData(
        id: id ?? this.id,
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        textUthmani: textUthmani ?? this.textUthmani,
        pageMadina: pageMadina.present ? pageMadina.value : this.pageMadina,
      );
  AyahData copyWithCompanion(AyahCompanion data) {
    return AyahData(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      textUthmani:
          data.textUthmani.present ? data.textUthmani.value : this.textUthmani,
      pageMadina:
          data.pageMadina.present ? data.pageMadina.value : this.pageMadina,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahData(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('pageMadina: $pageMadina')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surah, ayah, textUthmani, pageMadina);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahData &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.textUthmani == this.textUthmani &&
          other.pageMadina == this.pageMadina);
}

class AyahCompanion extends UpdateCompanion<AyahData> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> textUthmani;
  final Value<int?> pageMadina;
  const AyahCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.pageMadina = const Value.absent(),
  });
  AyahCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required String textUthmani,
    this.pageMadina = const Value.absent(),
  })  : surah = Value(surah),
        ayah = Value(ayah),
        textUthmani = Value(textUthmani);
  static Insertable<AyahData> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? textUthmani,
    Expression<int>? pageMadina,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (pageMadina != null) 'page_madina': pageMadina,
    });
  }

  AyahCompanion copyWith(
      {Value<int>? id,
      Value<int>? surah,
      Value<int>? ayah,
      Value<String>? textUthmani,
      Value<int?>? pageMadina}) {
    return AyahCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      textUthmani: textUthmani ?? this.textUthmani,
      pageMadina: pageMadina ?? this.pageMadina,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (pageMadina.present) {
      map['page_madina'] = Variable<int>(pageMadina.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('pageMadina: $pageMadina')
          ..write(')'))
        .toString();
  }
}

class $BookmarkTable extends Bookmark
    with TableInfo<$BookmarkTable, BookmarkData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
      'surah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
      'ayah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, surah, ayah, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmark';
  @override
  VerificationContext validateIntegrity(Insertable<BookmarkData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
          _surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
          _ayahMeta, ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta));
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      surah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah'])!,
      ayah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarkTable createAlias(String alias) {
    return $BookmarkTable(attachedDatabase, alias);
  }
}

class BookmarkData extends DataClass implements Insertable<BookmarkData> {
  final int id;
  final int surah;
  final int ayah;
  final DateTime createdAt;
  const BookmarkData(
      {required this.id,
      required this.surah,
      required this.ayah,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarkCompanion toCompanion(bool nullToAbsent) {
    return BookmarkCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarkData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkData(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BookmarkData copyWith(
          {int? id, int? surah, int? ayah, DateTime? createdAt}) =>
      BookmarkData(
        id: id ?? this.id,
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        createdAt: createdAt ?? this.createdAt,
      );
  BookmarkData copyWithCompanion(BookmarkCompanion data) {
    return BookmarkData(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkData(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surah, ayah, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkData &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.createdAt == this.createdAt);
}

class BookmarkCompanion extends UpdateCompanion<BookmarkData> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<DateTime> createdAt;
  const BookmarkCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarkCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    this.createdAt = const Value.absent(),
  })  : surah = Value(surah),
        ayah = Value(ayah);
  static Insertable<BookmarkData> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarkCompanion copyWith(
      {Value<int>? id,
      Value<int>? surah,
      Value<int>? ayah,
      Value<DateTime>? createdAt}) {
    return BookmarkCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NoteTable extends Note with TableInfo<$NoteTable, NoteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
      'surah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
      'ayah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, surah, ayah, title, body, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note';
  @override
  VerificationContext validateIntegrity(Insertable<NoteData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
          _surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
          _ayahMeta, ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta));
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      surah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah'])!,
      ayah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NoteTable createAlias(String alias) {
    return $NoteTable(attachedDatabase, alias);
  }
}

class NoteData extends DataClass implements Insertable<NoteData> {
  final int id;
  final int surah;
  final int ayah;
  final String? title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteData(
      {required this.id,
      required this.surah,
      required this.ayah,
      this.title,
      required this.body,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NoteCompanion toCompanion(bool nullToAbsent) {
    return NoteCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteData(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteData copyWith(
          {int? id,
          int? surah,
          int? ayah,
          Value<String?> title = const Value.absent(),
          String? body,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      NoteData(
        id: id ?? this.id,
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        title: title.present ? title.value : this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  NoteData copyWithCompanion(NoteCompanion data) {
    return NoteData(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteData(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, surah, ayah, title, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteData &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NoteCompanion extends UpdateCompanion<NoteData> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String?> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NoteCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NoteCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    this.title = const Value.absent(),
    required String body,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : surah = Value(surah),
        ayah = Value(ayah),
        body = Value(body);
  static Insertable<NoteData> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NoteCompanion copyWith(
      {Value<int>? id,
      Value<int>? surah,
      Value<int>? ayah,
      Value<String?>? title,
      Value<String>? body,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return NoteCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MemUnitTable extends MemUnit with TableInfo<$MemUnitTable, MemUnitData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemUnitTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      check: () => kind.isIn(const ['ayah_range', 'page_segment', 'custom']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _pageMadinaMeta =
      const VerificationMeta('pageMadina');
  @override
  late final GeneratedColumn<int> pageMadina = GeneratedColumn<int>(
      'page_madina', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startSurahMeta =
      const VerificationMeta('startSurah');
  @override
  late final GeneratedColumn<int> startSurah = GeneratedColumn<int>(
      'start_surah', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startAyahMeta =
      const VerificationMeta('startAyah');
  @override
  late final GeneratedColumn<int> startAyah = GeneratedColumn<int>(
      'start_ayah', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endSurahMeta =
      const VerificationMeta('endSurah');
  @override
  late final GeneratedColumn<int> endSurah = GeneratedColumn<int>(
      'end_surah', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endAyahMeta =
      const VerificationMeta('endAyah');
  @override
  late final GeneratedColumn<int> endAyah = GeneratedColumn<int>(
      'end_ayah', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startWordMeta =
      const VerificationMeta('startWord');
  @override
  late final GeneratedColumn<int> startWord = GeneratedColumn<int>(
      'start_word', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endWordMeta =
      const VerificationMeta('endWord');
  @override
  late final GeneratedColumn<int> endWord = GeneratedColumn<int>(
      'end_word', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locatorJsonMeta =
      const VerificationMeta('locatorJson');
  @override
  late final GeneratedColumn<String> locatorJson = GeneratedColumn<String>(
      'locator_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitKeyMeta =
      const VerificationMeta('unitKey');
  @override
  late final GeneratedColumn<String> unitKey = GeneratedColumn<String>(
      'unit_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtDayMeta =
      const VerificationMeta('createdAtDay');
  @override
  late final GeneratedColumn<int> createdAtDay = GeneratedColumn<int>(
      'created_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtDayMeta =
      const VerificationMeta('updatedAtDay');
  @override
  late final GeneratedColumn<int> updatedAtDay = GeneratedColumn<int>(
      'updated_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        pageMadina,
        startSurah,
        startAyah,
        endSurah,
        endAyah,
        startWord,
        endWord,
        title,
        locatorJson,
        unitKey,
        createdAtDay,
        updatedAtDay
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mem_unit';
  @override
  VerificationContext validateIntegrity(Insertable<MemUnitData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('page_madina')) {
      context.handle(
          _pageMadinaMeta,
          pageMadina.isAcceptableOrUnknown(
              data['page_madina']!, _pageMadinaMeta));
    }
    if (data.containsKey('start_surah')) {
      context.handle(
          _startSurahMeta,
          startSurah.isAcceptableOrUnknown(
              data['start_surah']!, _startSurahMeta));
    }
    if (data.containsKey('start_ayah')) {
      context.handle(_startAyahMeta,
          startAyah.isAcceptableOrUnknown(data['start_ayah']!, _startAyahMeta));
    }
    if (data.containsKey('end_surah')) {
      context.handle(_endSurahMeta,
          endSurah.isAcceptableOrUnknown(data['end_surah']!, _endSurahMeta));
    }
    if (data.containsKey('end_ayah')) {
      context.handle(_endAyahMeta,
          endAyah.isAcceptableOrUnknown(data['end_ayah']!, _endAyahMeta));
    }
    if (data.containsKey('start_word')) {
      context.handle(_startWordMeta,
          startWord.isAcceptableOrUnknown(data['start_word']!, _startWordMeta));
    }
    if (data.containsKey('end_word')) {
      context.handle(_endWordMeta,
          endWord.isAcceptableOrUnknown(data['end_word']!, _endWordMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('locator_json')) {
      context.handle(
          _locatorJsonMeta,
          locatorJson.isAcceptableOrUnknown(
              data['locator_json']!, _locatorJsonMeta));
    }
    if (data.containsKey('unit_key')) {
      context.handle(_unitKeyMeta,
          unitKey.isAcceptableOrUnknown(data['unit_key']!, _unitKeyMeta));
    } else if (isInserting) {
      context.missing(_unitKeyMeta);
    }
    if (data.containsKey('created_at_day')) {
      context.handle(
          _createdAtDayMeta,
          createdAtDay.isAcceptableOrUnknown(
              data['created_at_day']!, _createdAtDayMeta));
    } else if (isInserting) {
      context.missing(_createdAtDayMeta);
    }
    if (data.containsKey('updated_at_day')) {
      context.handle(
          _updatedAtDayMeta,
          updatedAtDay.isAcceptableOrUnknown(
              data['updated_at_day']!, _updatedAtDayMeta));
    } else if (isInserting) {
      context.missing(_updatedAtDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {unitKey},
      ];
  @override
  MemUnitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemUnitData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      pageMadina: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_madina']),
      startSurah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_surah']),
      startAyah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ayah']),
      endSurah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_surah']),
      endAyah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_ayah']),
      startWord: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_word']),
      endWord: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_word']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      locatorJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locator_json']),
      unitKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_key'])!,
      createdAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_day'])!,
      updatedAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_day'])!,
    );
  }

  @override
  $MemUnitTable createAlias(String alias) {
    return $MemUnitTable(attachedDatabase, alias);
  }
}

class MemUnitData extends DataClass implements Insertable<MemUnitData> {
  final int id;
  final String kind;
  final int? pageMadina;
  final int? startSurah;
  final int? startAyah;
  final int? endSurah;
  final int? endAyah;
  final int? startWord;
  final int? endWord;
  final String? title;
  final String? locatorJson;
  final String unitKey;
  final int createdAtDay;
  final int updatedAtDay;
  const MemUnitData(
      {required this.id,
      required this.kind,
      this.pageMadina,
      this.startSurah,
      this.startAyah,
      this.endSurah,
      this.endAyah,
      this.startWord,
      this.endWord,
      this.title,
      this.locatorJson,
      required this.unitKey,
      required this.createdAtDay,
      required this.updatedAtDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || pageMadina != null) {
      map['page_madina'] = Variable<int>(pageMadina);
    }
    if (!nullToAbsent || startSurah != null) {
      map['start_surah'] = Variable<int>(startSurah);
    }
    if (!nullToAbsent || startAyah != null) {
      map['start_ayah'] = Variable<int>(startAyah);
    }
    if (!nullToAbsent || endSurah != null) {
      map['end_surah'] = Variable<int>(endSurah);
    }
    if (!nullToAbsent || endAyah != null) {
      map['end_ayah'] = Variable<int>(endAyah);
    }
    if (!nullToAbsent || startWord != null) {
      map['start_word'] = Variable<int>(startWord);
    }
    if (!nullToAbsent || endWord != null) {
      map['end_word'] = Variable<int>(endWord);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || locatorJson != null) {
      map['locator_json'] = Variable<String>(locatorJson);
    }
    map['unit_key'] = Variable<String>(unitKey);
    map['created_at_day'] = Variable<int>(createdAtDay);
    map['updated_at_day'] = Variable<int>(updatedAtDay);
    return map;
  }

  MemUnitCompanion toCompanion(bool nullToAbsent) {
    return MemUnitCompanion(
      id: Value(id),
      kind: Value(kind),
      pageMadina: pageMadina == null && nullToAbsent
          ? const Value.absent()
          : Value(pageMadina),
      startSurah: startSurah == null && nullToAbsent
          ? const Value.absent()
          : Value(startSurah),
      startAyah: startAyah == null && nullToAbsent
          ? const Value.absent()
          : Value(startAyah),
      endSurah: endSurah == null && nullToAbsent
          ? const Value.absent()
          : Value(endSurah),
      endAyah: endAyah == null && nullToAbsent
          ? const Value.absent()
          : Value(endAyah),
      startWord: startWord == null && nullToAbsent
          ? const Value.absent()
          : Value(startWord),
      endWord: endWord == null && nullToAbsent
          ? const Value.absent()
          : Value(endWord),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      locatorJson: locatorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(locatorJson),
      unitKey: Value(unitKey),
      createdAtDay: Value(createdAtDay),
      updatedAtDay: Value(updatedAtDay),
    );
  }

  factory MemUnitData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemUnitData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      pageMadina: serializer.fromJson<int?>(json['pageMadina']),
      startSurah: serializer.fromJson<int?>(json['startSurah']),
      startAyah: serializer.fromJson<int?>(json['startAyah']),
      endSurah: serializer.fromJson<int?>(json['endSurah']),
      endAyah: serializer.fromJson<int?>(json['endAyah']),
      startWord: serializer.fromJson<int?>(json['startWord']),
      endWord: serializer.fromJson<int?>(json['endWord']),
      title: serializer.fromJson<String?>(json['title']),
      locatorJson: serializer.fromJson<String?>(json['locatorJson']),
      unitKey: serializer.fromJson<String>(json['unitKey']),
      createdAtDay: serializer.fromJson<int>(json['createdAtDay']),
      updatedAtDay: serializer.fromJson<int>(json['updatedAtDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'pageMadina': serializer.toJson<int?>(pageMadina),
      'startSurah': serializer.toJson<int?>(startSurah),
      'startAyah': serializer.toJson<int?>(startAyah),
      'endSurah': serializer.toJson<int?>(endSurah),
      'endAyah': serializer.toJson<int?>(endAyah),
      'startWord': serializer.toJson<int?>(startWord),
      'endWord': serializer.toJson<int?>(endWord),
      'title': serializer.toJson<String?>(title),
      'locatorJson': serializer.toJson<String?>(locatorJson),
      'unitKey': serializer.toJson<String>(unitKey),
      'createdAtDay': serializer.toJson<int>(createdAtDay),
      'updatedAtDay': serializer.toJson<int>(updatedAtDay),
    };
  }

  MemUnitData copyWith(
          {int? id,
          String? kind,
          Value<int?> pageMadina = const Value.absent(),
          Value<int?> startSurah = const Value.absent(),
          Value<int?> startAyah = const Value.absent(),
          Value<int?> endSurah = const Value.absent(),
          Value<int?> endAyah = const Value.absent(),
          Value<int?> startWord = const Value.absent(),
          Value<int?> endWord = const Value.absent(),
          Value<String?> title = const Value.absent(),
          Value<String?> locatorJson = const Value.absent(),
          String? unitKey,
          int? createdAtDay,
          int? updatedAtDay}) =>
      MemUnitData(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        pageMadina: pageMadina.present ? pageMadina.value : this.pageMadina,
        startSurah: startSurah.present ? startSurah.value : this.startSurah,
        startAyah: startAyah.present ? startAyah.value : this.startAyah,
        endSurah: endSurah.present ? endSurah.value : this.endSurah,
        endAyah: endAyah.present ? endAyah.value : this.endAyah,
        startWord: startWord.present ? startWord.value : this.startWord,
        endWord: endWord.present ? endWord.value : this.endWord,
        title: title.present ? title.value : this.title,
        locatorJson: locatorJson.present ? locatorJson.value : this.locatorJson,
        unitKey: unitKey ?? this.unitKey,
        createdAtDay: createdAtDay ?? this.createdAtDay,
        updatedAtDay: updatedAtDay ?? this.updatedAtDay,
      );
  MemUnitData copyWithCompanion(MemUnitCompanion data) {
    return MemUnitData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      pageMadina:
          data.pageMadina.present ? data.pageMadina.value : this.pageMadina,
      startSurah:
          data.startSurah.present ? data.startSurah.value : this.startSurah,
      startAyah: data.startAyah.present ? data.startAyah.value : this.startAyah,
      endSurah: data.endSurah.present ? data.endSurah.value : this.endSurah,
      endAyah: data.endAyah.present ? data.endAyah.value : this.endAyah,
      startWord: data.startWord.present ? data.startWord.value : this.startWord,
      endWord: data.endWord.present ? data.endWord.value : this.endWord,
      title: data.title.present ? data.title.value : this.title,
      locatorJson:
          data.locatorJson.present ? data.locatorJson.value : this.locatorJson,
      unitKey: data.unitKey.present ? data.unitKey.value : this.unitKey,
      createdAtDay: data.createdAtDay.present
          ? data.createdAtDay.value
          : this.createdAtDay,
      updatedAtDay: data.updatedAtDay.present
          ? data.updatedAtDay.value
          : this.updatedAtDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemUnitData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('pageMadina: $pageMadina, ')
          ..write('startSurah: $startSurah, ')
          ..write('startAyah: $startAyah, ')
          ..write('endSurah: $endSurah, ')
          ..write('endAyah: $endAyah, ')
          ..write('startWord: $startWord, ')
          ..write('endWord: $endWord, ')
          ..write('title: $title, ')
          ..write('locatorJson: $locatorJson, ')
          ..write('unitKey: $unitKey, ')
          ..write('createdAtDay: $createdAtDay, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      pageMadina,
      startSurah,
      startAyah,
      endSurah,
      endAyah,
      startWord,
      endWord,
      title,
      locatorJson,
      unitKey,
      createdAtDay,
      updatedAtDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemUnitData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.pageMadina == this.pageMadina &&
          other.startSurah == this.startSurah &&
          other.startAyah == this.startAyah &&
          other.endSurah == this.endSurah &&
          other.endAyah == this.endAyah &&
          other.startWord == this.startWord &&
          other.endWord == this.endWord &&
          other.title == this.title &&
          other.locatorJson == this.locatorJson &&
          other.unitKey == this.unitKey &&
          other.createdAtDay == this.createdAtDay &&
          other.updatedAtDay == this.updatedAtDay);
}

class MemUnitCompanion extends UpdateCompanion<MemUnitData> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int?> pageMadina;
  final Value<int?> startSurah;
  final Value<int?> startAyah;
  final Value<int?> endSurah;
  final Value<int?> endAyah;
  final Value<int?> startWord;
  final Value<int?> endWord;
  final Value<String?> title;
  final Value<String?> locatorJson;
  final Value<String> unitKey;
  final Value<int> createdAtDay;
  final Value<int> updatedAtDay;
  const MemUnitCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.pageMadina = const Value.absent(),
    this.startSurah = const Value.absent(),
    this.startAyah = const Value.absent(),
    this.endSurah = const Value.absent(),
    this.endAyah = const Value.absent(),
    this.startWord = const Value.absent(),
    this.endWord = const Value.absent(),
    this.title = const Value.absent(),
    this.locatorJson = const Value.absent(),
    this.unitKey = const Value.absent(),
    this.createdAtDay = const Value.absent(),
    this.updatedAtDay = const Value.absent(),
  });
  MemUnitCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.pageMadina = const Value.absent(),
    this.startSurah = const Value.absent(),
    this.startAyah = const Value.absent(),
    this.endSurah = const Value.absent(),
    this.endAyah = const Value.absent(),
    this.startWord = const Value.absent(),
    this.endWord = const Value.absent(),
    this.title = const Value.absent(),
    this.locatorJson = const Value.absent(),
    required String unitKey,
    required int createdAtDay,
    required int updatedAtDay,
  })  : kind = Value(kind),
        unitKey = Value(unitKey),
        createdAtDay = Value(createdAtDay),
        updatedAtDay = Value(updatedAtDay);
  static Insertable<MemUnitData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? pageMadina,
    Expression<int>? startSurah,
    Expression<int>? startAyah,
    Expression<int>? endSurah,
    Expression<int>? endAyah,
    Expression<int>? startWord,
    Expression<int>? endWord,
    Expression<String>? title,
    Expression<String>? locatorJson,
    Expression<String>? unitKey,
    Expression<int>? createdAtDay,
    Expression<int>? updatedAtDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (pageMadina != null) 'page_madina': pageMadina,
      if (startSurah != null) 'start_surah': startSurah,
      if (startAyah != null) 'start_ayah': startAyah,
      if (endSurah != null) 'end_surah': endSurah,
      if (endAyah != null) 'end_ayah': endAyah,
      if (startWord != null) 'start_word': startWord,
      if (endWord != null) 'end_word': endWord,
      if (title != null) 'title': title,
      if (locatorJson != null) 'locator_json': locatorJson,
      if (unitKey != null) 'unit_key': unitKey,
      if (createdAtDay != null) 'created_at_day': createdAtDay,
      if (updatedAtDay != null) 'updated_at_day': updatedAtDay,
    });
  }

  MemUnitCompanion copyWith(
      {Value<int>? id,
      Value<String>? kind,
      Value<int?>? pageMadina,
      Value<int?>? startSurah,
      Value<int?>? startAyah,
      Value<int?>? endSurah,
      Value<int?>? endAyah,
      Value<int?>? startWord,
      Value<int?>? endWord,
      Value<String?>? title,
      Value<String?>? locatorJson,
      Value<String>? unitKey,
      Value<int>? createdAtDay,
      Value<int>? updatedAtDay}) {
    return MemUnitCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      pageMadina: pageMadina ?? this.pageMadina,
      startSurah: startSurah ?? this.startSurah,
      startAyah: startAyah ?? this.startAyah,
      endSurah: endSurah ?? this.endSurah,
      endAyah: endAyah ?? this.endAyah,
      startWord: startWord ?? this.startWord,
      endWord: endWord ?? this.endWord,
      title: title ?? this.title,
      locatorJson: locatorJson ?? this.locatorJson,
      unitKey: unitKey ?? this.unitKey,
      createdAtDay: createdAtDay ?? this.createdAtDay,
      updatedAtDay: updatedAtDay ?? this.updatedAtDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (pageMadina.present) {
      map['page_madina'] = Variable<int>(pageMadina.value);
    }
    if (startSurah.present) {
      map['start_surah'] = Variable<int>(startSurah.value);
    }
    if (startAyah.present) {
      map['start_ayah'] = Variable<int>(startAyah.value);
    }
    if (endSurah.present) {
      map['end_surah'] = Variable<int>(endSurah.value);
    }
    if (endAyah.present) {
      map['end_ayah'] = Variable<int>(endAyah.value);
    }
    if (startWord.present) {
      map['start_word'] = Variable<int>(startWord.value);
    }
    if (endWord.present) {
      map['end_word'] = Variable<int>(endWord.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (locatorJson.present) {
      map['locator_json'] = Variable<String>(locatorJson.value);
    }
    if (unitKey.present) {
      map['unit_key'] = Variable<String>(unitKey.value);
    }
    if (createdAtDay.present) {
      map['created_at_day'] = Variable<int>(createdAtDay.value);
    }
    if (updatedAtDay.present) {
      map['updated_at_day'] = Variable<int>(updatedAtDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemUnitCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('pageMadina: $pageMadina, ')
          ..write('startSurah: $startSurah, ')
          ..write('startAyah: $startAyah, ')
          ..write('endSurah: $endSurah, ')
          ..write('endAyah: $endAyah, ')
          ..write('startWord: $startWord, ')
          ..write('endWord: $endWord, ')
          ..write('title: $title, ')
          ..write('locatorJson: $locatorJson, ')
          ..write('unitKey: $unitKey, ')
          ..write('createdAtDay: $createdAtDay, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }
}

class $ScheduleStateTable extends ScheduleState
    with TableInfo<$ScheduleStateTable, ScheduleStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES mem_unit (id) ON DELETE CASCADE'));
  static const VerificationMeta _efMeta = const VerificationMeta('ef');
  @override
  late final GeneratedColumn<double> ef = GeneratedColumn<double>(
      'ef', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
      'due_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastReviewDayMeta =
      const VerificationMeta('lastReviewDay');
  @override
  late final GeneratedColumn<int> lastReviewDay = GeneratedColumn<int>(
      'last_review_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastGradeQMeta =
      const VerificationMeta('lastGradeQ');
  @override
  late final GeneratedColumn<int> lastGradeQ = GeneratedColumn<int>(
      'last_grade_q', aliasedName, true,
      check: () => lastGradeQ.isIn(const [5, 4, 3, 2, 0]),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _lapseCountMeta =
      const VerificationMeta('lapseCount');
  @override
  late final GeneratedColumn<int> lapseCount = GeneratedColumn<int>(
      'lapse_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isSuspendedMeta =
      const VerificationMeta('isSuspended');
  @override
  late final GeneratedColumn<int> isSuspended = GeneratedColumn<int>(
      'is_suspended', aliasedName, false,
      check: () => isSuspended.isIn(const [0, 1]),
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _suspendedAtDayMeta =
      const VerificationMeta('suspendedAtDay');
  @override
  late final GeneratedColumn<int> suspendedAtDay = GeneratedColumn<int>(
      'suspended_at_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        unitId,
        ef,
        reps,
        intervalDays,
        dueDay,
        lastReviewDay,
        lastGradeQ,
        lapseCount,
        isSuspended,
        suspendedAtDay
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_state';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduleStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('ef')) {
      context.handle(_efMeta, ef.isAcceptableOrUnknown(data['ef']!, _efMeta));
    } else if (isInserting) {
      context.missing(_efMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('due_day')) {
      context.handle(_dueDayMeta,
          dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta));
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('last_review_day')) {
      context.handle(
          _lastReviewDayMeta,
          lastReviewDay.isAcceptableOrUnknown(
              data['last_review_day']!, _lastReviewDayMeta));
    }
    if (data.containsKey('last_grade_q')) {
      context.handle(
          _lastGradeQMeta,
          lastGradeQ.isAcceptableOrUnknown(
              data['last_grade_q']!, _lastGradeQMeta));
    }
    if (data.containsKey('lapse_count')) {
      context.handle(
          _lapseCountMeta,
          lapseCount.isAcceptableOrUnknown(
              data['lapse_count']!, _lapseCountMeta));
    } else if (isInserting) {
      context.missing(_lapseCountMeta);
    }
    if (data.containsKey('is_suspended')) {
      context.handle(
          _isSuspendedMeta,
          isSuspended.isAcceptableOrUnknown(
              data['is_suspended']!, _isSuspendedMeta));
    }
    if (data.containsKey('suspended_at_day')) {
      context.handle(
          _suspendedAtDayMeta,
          suspendedAtDay.isAcceptableOrUnknown(
              data['suspended_at_day']!, _suspendedAtDayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {unitId};
  @override
  ScheduleStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleStateData(
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id'])!,
      ef: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ef'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days'])!,
      dueDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_day'])!,
      lastReviewDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_review_day']),
      lastGradeQ: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_grade_q']),
      lapseCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapse_count'])!,
      isSuspended: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_suspended'])!,
      suspendedAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}suspended_at_day']),
    );
  }

  @override
  $ScheduleStateTable createAlias(String alias) {
    return $ScheduleStateTable(attachedDatabase, alias);
  }
}

class ScheduleStateData extends DataClass
    implements Insertable<ScheduleStateData> {
  final int unitId;
  final double ef;
  final int reps;
  final int intervalDays;
  final int dueDay;
  final int? lastReviewDay;
  final int? lastGradeQ;
  final int lapseCount;
  final int isSuspended;
  final int? suspendedAtDay;
  const ScheduleStateData(
      {required this.unitId,
      required this.ef,
      required this.reps,
      required this.intervalDays,
      required this.dueDay,
      this.lastReviewDay,
      this.lastGradeQ,
      required this.lapseCount,
      required this.isSuspended,
      this.suspendedAtDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['unit_id'] = Variable<int>(unitId);
    map['ef'] = Variable<double>(ef);
    map['reps'] = Variable<int>(reps);
    map['interval_days'] = Variable<int>(intervalDays);
    map['due_day'] = Variable<int>(dueDay);
    if (!nullToAbsent || lastReviewDay != null) {
      map['last_review_day'] = Variable<int>(lastReviewDay);
    }
    if (!nullToAbsent || lastGradeQ != null) {
      map['last_grade_q'] = Variable<int>(lastGradeQ);
    }
    map['lapse_count'] = Variable<int>(lapseCount);
    map['is_suspended'] = Variable<int>(isSuspended);
    if (!nullToAbsent || suspendedAtDay != null) {
      map['suspended_at_day'] = Variable<int>(suspendedAtDay);
    }
    return map;
  }

  ScheduleStateCompanion toCompanion(bool nullToAbsent) {
    return ScheduleStateCompanion(
      unitId: Value(unitId),
      ef: Value(ef),
      reps: Value(reps),
      intervalDays: Value(intervalDays),
      dueDay: Value(dueDay),
      lastReviewDay: lastReviewDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewDay),
      lastGradeQ: lastGradeQ == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGradeQ),
      lapseCount: Value(lapseCount),
      isSuspended: Value(isSuspended),
      suspendedAtDay: suspendedAtDay == null && nullToAbsent
          ? const Value.absent()
          : Value(suspendedAtDay),
    );
  }

  factory ScheduleStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleStateData(
      unitId: serializer.fromJson<int>(json['unitId']),
      ef: serializer.fromJson<double>(json['ef']),
      reps: serializer.fromJson<int>(json['reps']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      lastReviewDay: serializer.fromJson<int?>(json['lastReviewDay']),
      lastGradeQ: serializer.fromJson<int?>(json['lastGradeQ']),
      lapseCount: serializer.fromJson<int>(json['lapseCount']),
      isSuspended: serializer.fromJson<int>(json['isSuspended']),
      suspendedAtDay: serializer.fromJson<int?>(json['suspendedAtDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'unitId': serializer.toJson<int>(unitId),
      'ef': serializer.toJson<double>(ef),
      'reps': serializer.toJson<int>(reps),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'dueDay': serializer.toJson<int>(dueDay),
      'lastReviewDay': serializer.toJson<int?>(lastReviewDay),
      'lastGradeQ': serializer.toJson<int?>(lastGradeQ),
      'lapseCount': serializer.toJson<int>(lapseCount),
      'isSuspended': serializer.toJson<int>(isSuspended),
      'suspendedAtDay': serializer.toJson<int?>(suspendedAtDay),
    };
  }

  ScheduleStateData copyWith(
          {int? unitId,
          double? ef,
          int? reps,
          int? intervalDays,
          int? dueDay,
          Value<int?> lastReviewDay = const Value.absent(),
          Value<int?> lastGradeQ = const Value.absent(),
          int? lapseCount,
          int? isSuspended,
          Value<int?> suspendedAtDay = const Value.absent()}) =>
      ScheduleStateData(
        unitId: unitId ?? this.unitId,
        ef: ef ?? this.ef,
        reps: reps ?? this.reps,
        intervalDays: intervalDays ?? this.intervalDays,
        dueDay: dueDay ?? this.dueDay,
        lastReviewDay:
            lastReviewDay.present ? lastReviewDay.value : this.lastReviewDay,
        lastGradeQ: lastGradeQ.present ? lastGradeQ.value : this.lastGradeQ,
        lapseCount: lapseCount ?? this.lapseCount,
        isSuspended: isSuspended ?? this.isSuspended,
        suspendedAtDay:
            suspendedAtDay.present ? suspendedAtDay.value : this.suspendedAtDay,
      );
  ScheduleStateData copyWithCompanion(ScheduleStateCompanion data) {
    return ScheduleStateData(
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      ef: data.ef.present ? data.ef.value : this.ef,
      reps: data.reps.present ? data.reps.value : this.reps,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      lastReviewDay: data.lastReviewDay.present
          ? data.lastReviewDay.value
          : this.lastReviewDay,
      lastGradeQ:
          data.lastGradeQ.present ? data.lastGradeQ.value : this.lastGradeQ,
      lapseCount:
          data.lapseCount.present ? data.lapseCount.value : this.lapseCount,
      isSuspended:
          data.isSuspended.present ? data.isSuspended.value : this.isSuspended,
      suspendedAtDay: data.suspendedAtDay.present
          ? data.suspendedAtDay.value
          : this.suspendedAtDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleStateData(')
          ..write('unitId: $unitId, ')
          ..write('ef: $ef, ')
          ..write('reps: $reps, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastReviewDay: $lastReviewDay, ')
          ..write('lastGradeQ: $lastGradeQ, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('isSuspended: $isSuspended, ')
          ..write('suspendedAtDay: $suspendedAtDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(unitId, ef, reps, intervalDays, dueDay,
      lastReviewDay, lastGradeQ, lapseCount, isSuspended, suspendedAtDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleStateData &&
          other.unitId == this.unitId &&
          other.ef == this.ef &&
          other.reps == this.reps &&
          other.intervalDays == this.intervalDays &&
          other.dueDay == this.dueDay &&
          other.lastReviewDay == this.lastReviewDay &&
          other.lastGradeQ == this.lastGradeQ &&
          other.lapseCount == this.lapseCount &&
          other.isSuspended == this.isSuspended &&
          other.suspendedAtDay == this.suspendedAtDay);
}

class ScheduleStateCompanion extends UpdateCompanion<ScheduleStateData> {
  final Value<int> unitId;
  final Value<double> ef;
  final Value<int> reps;
  final Value<int> intervalDays;
  final Value<int> dueDay;
  final Value<int?> lastReviewDay;
  final Value<int?> lastGradeQ;
  final Value<int> lapseCount;
  final Value<int> isSuspended;
  final Value<int?> suspendedAtDay;
  const ScheduleStateCompanion({
    this.unitId = const Value.absent(),
    this.ef = const Value.absent(),
    this.reps = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.lastReviewDay = const Value.absent(),
    this.lastGradeQ = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.isSuspended = const Value.absent(),
    this.suspendedAtDay = const Value.absent(),
  });
  ScheduleStateCompanion.insert({
    this.unitId = const Value.absent(),
    required double ef,
    required int reps,
    required int intervalDays,
    required int dueDay,
    this.lastReviewDay = const Value.absent(),
    this.lastGradeQ = const Value.absent(),
    required int lapseCount,
    this.isSuspended = const Value.absent(),
    this.suspendedAtDay = const Value.absent(),
  })  : ef = Value(ef),
        reps = Value(reps),
        intervalDays = Value(intervalDays),
        dueDay = Value(dueDay),
        lapseCount = Value(lapseCount);
  static Insertable<ScheduleStateData> custom({
    Expression<int>? unitId,
    Expression<double>? ef,
    Expression<int>? reps,
    Expression<int>? intervalDays,
    Expression<int>? dueDay,
    Expression<int>? lastReviewDay,
    Expression<int>? lastGradeQ,
    Expression<int>? lapseCount,
    Expression<int>? isSuspended,
    Expression<int>? suspendedAtDay,
  }) {
    return RawValuesInsertable({
      if (unitId != null) 'unit_id': unitId,
      if (ef != null) 'ef': ef,
      if (reps != null) 'reps': reps,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (dueDay != null) 'due_day': dueDay,
      if (lastReviewDay != null) 'last_review_day': lastReviewDay,
      if (lastGradeQ != null) 'last_grade_q': lastGradeQ,
      if (lapseCount != null) 'lapse_count': lapseCount,
      if (isSuspended != null) 'is_suspended': isSuspended,
      if (suspendedAtDay != null) 'suspended_at_day': suspendedAtDay,
    });
  }

  ScheduleStateCompanion copyWith(
      {Value<int>? unitId,
      Value<double>? ef,
      Value<int>? reps,
      Value<int>? intervalDays,
      Value<int>? dueDay,
      Value<int?>? lastReviewDay,
      Value<int?>? lastGradeQ,
      Value<int>? lapseCount,
      Value<int>? isSuspended,
      Value<int?>? suspendedAtDay}) {
    return ScheduleStateCompanion(
      unitId: unitId ?? this.unitId,
      ef: ef ?? this.ef,
      reps: reps ?? this.reps,
      intervalDays: intervalDays ?? this.intervalDays,
      dueDay: dueDay ?? this.dueDay,
      lastReviewDay: lastReviewDay ?? this.lastReviewDay,
      lastGradeQ: lastGradeQ ?? this.lastGradeQ,
      lapseCount: lapseCount ?? this.lapseCount,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedAtDay: suspendedAtDay ?? this.suspendedAtDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (ef.present) {
      map['ef'] = Variable<double>(ef.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (lastReviewDay.present) {
      map['last_review_day'] = Variable<int>(lastReviewDay.value);
    }
    if (lastGradeQ.present) {
      map['last_grade_q'] = Variable<int>(lastGradeQ.value);
    }
    if (lapseCount.present) {
      map['lapse_count'] = Variable<int>(lapseCount.value);
    }
    if (isSuspended.present) {
      map['is_suspended'] = Variable<int>(isSuspended.value);
    }
    if (suspendedAtDay.present) {
      map['suspended_at_day'] = Variable<int>(suspendedAtDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleStateCompanion(')
          ..write('unitId: $unitId, ')
          ..write('ef: $ef, ')
          ..write('reps: $reps, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastReviewDay: $lastReviewDay, ')
          ..write('lastGradeQ: $lastGradeQ, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('isSuspended: $isSuspended, ')
          ..write('suspendedAtDay: $suspendedAtDay')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogTable extends ReviewLog
    with TableInfo<$ReviewLogTable, ReviewLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES mem_unit (id) ON DELETE CASCADE'));
  static const VerificationMeta _tsDayMeta = const VerificationMeta('tsDay');
  @override
  late final GeneratedColumn<int> tsDay = GeneratedColumn<int>(
      'ts_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tsSecondsMeta =
      const VerificationMeta('tsSeconds');
  @override
  late final GeneratedColumn<int> tsSeconds = GeneratedColumn<int>(
      'ts_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _gradeQMeta = const VerificationMeta('gradeQ');
  @override
  late final GeneratedColumn<int> gradeQ = GeneratedColumn<int>(
      'grade_q', aliasedName, false,
      check: () => gradeQ.isIn(const [5, 4, 3, 2, 0]),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mistakesCountMeta =
      const VerificationMeta('mistakesCount');
  @override
  late final GeneratedColumn<int> mistakesCount = GeneratedColumn<int>(
      'mistakes_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, unitId, tsDay, tsSeconds, gradeQ, durationSeconds, mistakesCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('ts_day')) {
      context.handle(
          _tsDayMeta, tsDay.isAcceptableOrUnknown(data['ts_day']!, _tsDayMeta));
    } else if (isInserting) {
      context.missing(_tsDayMeta);
    }
    if (data.containsKey('ts_seconds')) {
      context.handle(_tsSecondsMeta,
          tsSeconds.isAcceptableOrUnknown(data['ts_seconds']!, _tsSecondsMeta));
    }
    if (data.containsKey('grade_q')) {
      context.handle(_gradeQMeta,
          gradeQ.isAcceptableOrUnknown(data['grade_q']!, _gradeQMeta));
    } else if (isInserting) {
      context.missing(_gradeQMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('mistakes_count')) {
      context.handle(
          _mistakesCountMeta,
          mistakesCount.isAcceptableOrUnknown(
              data['mistakes_count']!, _mistakesCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id'])!,
      tsDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ts_day'])!,
      tsSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ts_seconds']),
      gradeQ: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grade_q'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      mistakesCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mistakes_count']),
    );
  }

  @override
  $ReviewLogTable createAlias(String alias) {
    return $ReviewLogTable(attachedDatabase, alias);
  }
}

class ReviewLogData extends DataClass implements Insertable<ReviewLogData> {
  final int id;
  final int unitId;
  final int tsDay;
  final int? tsSeconds;
  final int gradeQ;
  final int? durationSeconds;
  final int? mistakesCount;
  const ReviewLogData(
      {required this.id,
      required this.unitId,
      required this.tsDay,
      this.tsSeconds,
      required this.gradeQ,
      this.durationSeconds,
      this.mistakesCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['unit_id'] = Variable<int>(unitId);
    map['ts_day'] = Variable<int>(tsDay);
    if (!nullToAbsent || tsSeconds != null) {
      map['ts_seconds'] = Variable<int>(tsSeconds);
    }
    map['grade_q'] = Variable<int>(gradeQ);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || mistakesCount != null) {
      map['mistakes_count'] = Variable<int>(mistakesCount);
    }
    return map;
  }

  ReviewLogCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogCompanion(
      id: Value(id),
      unitId: Value(unitId),
      tsDay: Value(tsDay),
      tsSeconds: tsSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(tsSeconds),
      gradeQ: Value(gradeQ),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      mistakesCount: mistakesCount == null && nullToAbsent
          ? const Value.absent()
          : Value(mistakesCount),
    );
  }

  factory ReviewLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogData(
      id: serializer.fromJson<int>(json['id']),
      unitId: serializer.fromJson<int>(json['unitId']),
      tsDay: serializer.fromJson<int>(json['tsDay']),
      tsSeconds: serializer.fromJson<int?>(json['tsSeconds']),
      gradeQ: serializer.fromJson<int>(json['gradeQ']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      mistakesCount: serializer.fromJson<int?>(json['mistakesCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'unitId': serializer.toJson<int>(unitId),
      'tsDay': serializer.toJson<int>(tsDay),
      'tsSeconds': serializer.toJson<int?>(tsSeconds),
      'gradeQ': serializer.toJson<int>(gradeQ),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'mistakesCount': serializer.toJson<int?>(mistakesCount),
    };
  }

  ReviewLogData copyWith(
          {int? id,
          int? unitId,
          int? tsDay,
          Value<int?> tsSeconds = const Value.absent(),
          int? gradeQ,
          Value<int?> durationSeconds = const Value.absent(),
          Value<int?> mistakesCount = const Value.absent()}) =>
      ReviewLogData(
        id: id ?? this.id,
        unitId: unitId ?? this.unitId,
        tsDay: tsDay ?? this.tsDay,
        tsSeconds: tsSeconds.present ? tsSeconds.value : this.tsSeconds,
        gradeQ: gradeQ ?? this.gradeQ,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        mistakesCount:
            mistakesCount.present ? mistakesCount.value : this.mistakesCount,
      );
  ReviewLogData copyWithCompanion(ReviewLogCompanion data) {
    return ReviewLogData(
      id: data.id.present ? data.id.value : this.id,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      tsDay: data.tsDay.present ? data.tsDay.value : this.tsDay,
      tsSeconds: data.tsSeconds.present ? data.tsSeconds.value : this.tsSeconds,
      gradeQ: data.gradeQ.present ? data.gradeQ.value : this.gradeQ,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      mistakesCount: data.mistakesCount.present
          ? data.mistakesCount.value
          : this.mistakesCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogData(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('tsDay: $tsDay, ')
          ..write('tsSeconds: $tsSeconds, ')
          ..write('gradeQ: $gradeQ, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('mistakesCount: $mistakesCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, unitId, tsDay, tsSeconds, gradeQ, durationSeconds, mistakesCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogData &&
          other.id == this.id &&
          other.unitId == this.unitId &&
          other.tsDay == this.tsDay &&
          other.tsSeconds == this.tsSeconds &&
          other.gradeQ == this.gradeQ &&
          other.durationSeconds == this.durationSeconds &&
          other.mistakesCount == this.mistakesCount);
}

class ReviewLogCompanion extends UpdateCompanion<ReviewLogData> {
  final Value<int> id;
  final Value<int> unitId;
  final Value<int> tsDay;
  final Value<int?> tsSeconds;
  final Value<int> gradeQ;
  final Value<int?> durationSeconds;
  final Value<int?> mistakesCount;
  const ReviewLogCompanion({
    this.id = const Value.absent(),
    this.unitId = const Value.absent(),
    this.tsDay = const Value.absent(),
    this.tsSeconds = const Value.absent(),
    this.gradeQ = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.mistakesCount = const Value.absent(),
  });
  ReviewLogCompanion.insert({
    this.id = const Value.absent(),
    required int unitId,
    required int tsDay,
    this.tsSeconds = const Value.absent(),
    required int gradeQ,
    this.durationSeconds = const Value.absent(),
    this.mistakesCount = const Value.absent(),
  })  : unitId = Value(unitId),
        tsDay = Value(tsDay),
        gradeQ = Value(gradeQ);
  static Insertable<ReviewLogData> custom({
    Expression<int>? id,
    Expression<int>? unitId,
    Expression<int>? tsDay,
    Expression<int>? tsSeconds,
    Expression<int>? gradeQ,
    Expression<int>? durationSeconds,
    Expression<int>? mistakesCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unitId != null) 'unit_id': unitId,
      if (tsDay != null) 'ts_day': tsDay,
      if (tsSeconds != null) 'ts_seconds': tsSeconds,
      if (gradeQ != null) 'grade_q': gradeQ,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (mistakesCount != null) 'mistakes_count': mistakesCount,
    });
  }

  ReviewLogCompanion copyWith(
      {Value<int>? id,
      Value<int>? unitId,
      Value<int>? tsDay,
      Value<int?>? tsSeconds,
      Value<int>? gradeQ,
      Value<int?>? durationSeconds,
      Value<int?>? mistakesCount}) {
    return ReviewLogCompanion(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tsDay: tsDay ?? this.tsDay,
      tsSeconds: tsSeconds ?? this.tsSeconds,
      gradeQ: gradeQ ?? this.gradeQ,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mistakesCount: mistakesCount ?? this.mistakesCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (tsDay.present) {
      map['ts_day'] = Variable<int>(tsDay.value);
    }
    if (tsSeconds.present) {
      map['ts_seconds'] = Variable<int>(tsSeconds.value);
    }
    if (gradeQ.present) {
      map['grade_q'] = Variable<int>(gradeQ.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (mistakesCount.present) {
      map['mistakes_count'] = Variable<int>(mistakesCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogCompanion(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('tsDay: $tsDay, ')
          ..write('tsSeconds: $tsSeconds, ')
          ..write('gradeQ: $gradeQ, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('mistakesCount: $mistakesCount')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      check: () => id.equals(1),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _profileMeta =
      const VerificationMeta('profile');
  @override
  late final GeneratedColumn<String> profile = GeneratedColumn<String>(
      'profile', aliasedName, false,
      check: () => profile.isIn(const ['support', 'standard', 'accelerated']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _forceRevisionOnlyMeta =
      const VerificationMeta('forceRevisionOnly');
  @override
  late final GeneratedColumn<int> forceRevisionOnly = GeneratedColumn<int>(
      'force_revision_only', aliasedName, false,
      check: () => forceRevisionOnly.isIn(const [0, 1]),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _dailyMinutesDefaultMeta =
      const VerificationMeta('dailyMinutesDefault');
  @override
  late final GeneratedColumn<int> dailyMinutesDefault = GeneratedColumn<int>(
      'daily_minutes_default', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minutesByWeekdayJsonMeta =
      const VerificationMeta('minutesByWeekdayJson');
  @override
  late final GeneratedColumn<String> minutesByWeekdayJson =
      GeneratedColumn<String>('minutes_by_weekday_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _maxNewPagesPerDayMeta =
      const VerificationMeta('maxNewPagesPerDay');
  @override
  late final GeneratedColumn<int> maxNewPagesPerDay = GeneratedColumn<int>(
      'max_new_pages_per_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxNewUnitsPerDayMeta =
      const VerificationMeta('maxNewUnitsPerDay');
  @override
  late final GeneratedColumn<int> maxNewUnitsPerDay = GeneratedColumn<int>(
      'max_new_units_per_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _avgNewMinutesPerAyahMeta =
      const VerificationMeta('avgNewMinutesPerAyah');
  @override
  late final GeneratedColumn<double> avgNewMinutesPerAyah =
      GeneratedColumn<double>('avg_new_minutes_per_ayah', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgReviewMinutesPerAyahMeta =
      const VerificationMeta('avgReviewMinutesPerAyah');
  @override
  late final GeneratedColumn<double> avgReviewMinutesPerAyah =
      GeneratedColumn<double>('avg_review_minutes_per_ayah', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _requirePageMetadataMeta =
      const VerificationMeta('requirePageMetadata');
  @override
  late final GeneratedColumn<int> requirePageMetadata = GeneratedColumn<int>(
      'require_page_metadata', aliasedName, false,
      check: () => requirePageMetadata.isIn(const [0, 1]),
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _typicalGradeDistributionJsonMeta =
      const VerificationMeta('typicalGradeDistributionJson');
  @override
  late final GeneratedColumn<String> typicalGradeDistributionJson =
      GeneratedColumn<String>(
          'typical_grade_distribution_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtDayMeta =
      const VerificationMeta('updatedAtDay');
  @override
  late final GeneratedColumn<int> updatedAtDay = GeneratedColumn<int>(
      'updated_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profile,
        forceRevisionOnly,
        dailyMinutesDefault,
        minutesByWeekdayJson,
        maxNewPagesPerDay,
        maxNewUnitsPerDay,
        avgNewMinutesPerAyah,
        avgReviewMinutesPerAyah,
        requirePageMetadata,
        typicalGradeDistributionJson,
        updatedAtDay
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile')) {
      context.handle(_profileMeta,
          profile.isAcceptableOrUnknown(data['profile']!, _profileMeta));
    } else if (isInserting) {
      context.missing(_profileMeta);
    }
    if (data.containsKey('force_revision_only')) {
      context.handle(
          _forceRevisionOnlyMeta,
          forceRevisionOnly.isAcceptableOrUnknown(
              data['force_revision_only']!, _forceRevisionOnlyMeta));
    } else if (isInserting) {
      context.missing(_forceRevisionOnlyMeta);
    }
    if (data.containsKey('daily_minutes_default')) {
      context.handle(
          _dailyMinutesDefaultMeta,
          dailyMinutesDefault.isAcceptableOrUnknown(
              data['daily_minutes_default']!, _dailyMinutesDefaultMeta));
    } else if (isInserting) {
      context.missing(_dailyMinutesDefaultMeta);
    }
    if (data.containsKey('minutes_by_weekday_json')) {
      context.handle(
          _minutesByWeekdayJsonMeta,
          minutesByWeekdayJson.isAcceptableOrUnknown(
              data['minutes_by_weekday_json']!, _minutesByWeekdayJsonMeta));
    }
    if (data.containsKey('max_new_pages_per_day')) {
      context.handle(
          _maxNewPagesPerDayMeta,
          maxNewPagesPerDay.isAcceptableOrUnknown(
              data['max_new_pages_per_day']!, _maxNewPagesPerDayMeta));
    } else if (isInserting) {
      context.missing(_maxNewPagesPerDayMeta);
    }
    if (data.containsKey('max_new_units_per_day')) {
      context.handle(
          _maxNewUnitsPerDayMeta,
          maxNewUnitsPerDay.isAcceptableOrUnknown(
              data['max_new_units_per_day']!, _maxNewUnitsPerDayMeta));
    } else if (isInserting) {
      context.missing(_maxNewUnitsPerDayMeta);
    }
    if (data.containsKey('avg_new_minutes_per_ayah')) {
      context.handle(
          _avgNewMinutesPerAyahMeta,
          avgNewMinutesPerAyah.isAcceptableOrUnknown(
              data['avg_new_minutes_per_ayah']!, _avgNewMinutesPerAyahMeta));
    } else if (isInserting) {
      context.missing(_avgNewMinutesPerAyahMeta);
    }
    if (data.containsKey('avg_review_minutes_per_ayah')) {
      context.handle(
          _avgReviewMinutesPerAyahMeta,
          avgReviewMinutesPerAyah.isAcceptableOrUnknown(
              data['avg_review_minutes_per_ayah']!,
              _avgReviewMinutesPerAyahMeta));
    } else if (isInserting) {
      context.missing(_avgReviewMinutesPerAyahMeta);
    }
    if (data.containsKey('require_page_metadata')) {
      context.handle(
          _requirePageMetadataMeta,
          requirePageMetadata.isAcceptableOrUnknown(
              data['require_page_metadata']!, _requirePageMetadataMeta));
    }
    if (data.containsKey('typical_grade_distribution_json')) {
      context.handle(
          _typicalGradeDistributionJsonMeta,
          typicalGradeDistributionJson.isAcceptableOrUnknown(
              data['typical_grade_distribution_json']!,
              _typicalGradeDistributionJsonMeta));
    }
    if (data.containsKey('updated_at_day')) {
      context.handle(
          _updatedAtDayMeta,
          updatedAtDay.isAcceptableOrUnknown(
              data['updated_at_day']!, _updatedAtDayMeta));
    } else if (isInserting) {
      context.missing(_updatedAtDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile'])!,
      forceRevisionOnly: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}force_revision_only'])!,
      dailyMinutesDefault: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_minutes_default'])!,
      minutesByWeekdayJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}minutes_by_weekday_json']),
      maxNewPagesPerDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_new_pages_per_day'])!,
      maxNewUnitsPerDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_new_units_per_day'])!,
      avgNewMinutesPerAyah: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_new_minutes_per_ayah'])!,
      avgReviewMinutesPerAyah: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_review_minutes_per_ayah'])!,
      requirePageMetadata: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}require_page_metadata'])!,
      typicalGradeDistributionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}typical_grade_distribution_json']),
      updatedAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_day'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String profile;
  final int forceRevisionOnly;
  final int dailyMinutesDefault;
  final String? minutesByWeekdayJson;
  final int maxNewPagesPerDay;
  final int maxNewUnitsPerDay;
  final double avgNewMinutesPerAyah;
  final double avgReviewMinutesPerAyah;
  final int requirePageMetadata;
  final String? typicalGradeDistributionJson;
  final int updatedAtDay;
  const AppSetting(
      {required this.id,
      required this.profile,
      required this.forceRevisionOnly,
      required this.dailyMinutesDefault,
      this.minutesByWeekdayJson,
      required this.maxNewPagesPerDay,
      required this.maxNewUnitsPerDay,
      required this.avgNewMinutesPerAyah,
      required this.avgReviewMinutesPerAyah,
      required this.requirePageMetadata,
      this.typicalGradeDistributionJson,
      required this.updatedAtDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile'] = Variable<String>(profile);
    map['force_revision_only'] = Variable<int>(forceRevisionOnly);
    map['daily_minutes_default'] = Variable<int>(dailyMinutesDefault);
    if (!nullToAbsent || minutesByWeekdayJson != null) {
      map['minutes_by_weekday_json'] = Variable<String>(minutesByWeekdayJson);
    }
    map['max_new_pages_per_day'] = Variable<int>(maxNewPagesPerDay);
    map['max_new_units_per_day'] = Variable<int>(maxNewUnitsPerDay);
    map['avg_new_minutes_per_ayah'] = Variable<double>(avgNewMinutesPerAyah);
    map['avg_review_minutes_per_ayah'] =
        Variable<double>(avgReviewMinutesPerAyah);
    map['require_page_metadata'] = Variable<int>(requirePageMetadata);
    if (!nullToAbsent || typicalGradeDistributionJson != null) {
      map['typical_grade_distribution_json'] =
          Variable<String>(typicalGradeDistributionJson);
    }
    map['updated_at_day'] = Variable<int>(updatedAtDay);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      profile: Value(profile),
      forceRevisionOnly: Value(forceRevisionOnly),
      dailyMinutesDefault: Value(dailyMinutesDefault),
      minutesByWeekdayJson: minutesByWeekdayJson == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesByWeekdayJson),
      maxNewPagesPerDay: Value(maxNewPagesPerDay),
      maxNewUnitsPerDay: Value(maxNewUnitsPerDay),
      avgNewMinutesPerAyah: Value(avgNewMinutesPerAyah),
      avgReviewMinutesPerAyah: Value(avgReviewMinutesPerAyah),
      requirePageMetadata: Value(requirePageMetadata),
      typicalGradeDistributionJson:
          typicalGradeDistributionJson == null && nullToAbsent
              ? const Value.absent()
              : Value(typicalGradeDistributionJson),
      updatedAtDay: Value(updatedAtDay),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      profile: serializer.fromJson<String>(json['profile']),
      forceRevisionOnly: serializer.fromJson<int>(json['forceRevisionOnly']),
      dailyMinutesDefault:
          serializer.fromJson<int>(json['dailyMinutesDefault']),
      minutesByWeekdayJson:
          serializer.fromJson<String?>(json['minutesByWeekdayJson']),
      maxNewPagesPerDay: serializer.fromJson<int>(json['maxNewPagesPerDay']),
      maxNewUnitsPerDay: serializer.fromJson<int>(json['maxNewUnitsPerDay']),
      avgNewMinutesPerAyah:
          serializer.fromJson<double>(json['avgNewMinutesPerAyah']),
      avgReviewMinutesPerAyah:
          serializer.fromJson<double>(json['avgReviewMinutesPerAyah']),
      requirePageMetadata:
          serializer.fromJson<int>(json['requirePageMetadata']),
      typicalGradeDistributionJson:
          serializer.fromJson<String?>(json['typicalGradeDistributionJson']),
      updatedAtDay: serializer.fromJson<int>(json['updatedAtDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profile': serializer.toJson<String>(profile),
      'forceRevisionOnly': serializer.toJson<int>(forceRevisionOnly),
      'dailyMinutesDefault': serializer.toJson<int>(dailyMinutesDefault),
      'minutesByWeekdayJson': serializer.toJson<String?>(minutesByWeekdayJson),
      'maxNewPagesPerDay': serializer.toJson<int>(maxNewPagesPerDay),
      'maxNewUnitsPerDay': serializer.toJson<int>(maxNewUnitsPerDay),
      'avgNewMinutesPerAyah': serializer.toJson<double>(avgNewMinutesPerAyah),
      'avgReviewMinutesPerAyah':
          serializer.toJson<double>(avgReviewMinutesPerAyah),
      'requirePageMetadata': serializer.toJson<int>(requirePageMetadata),
      'typicalGradeDistributionJson':
          serializer.toJson<String?>(typicalGradeDistributionJson),
      'updatedAtDay': serializer.toJson<int>(updatedAtDay),
    };
  }

  AppSetting copyWith(
          {int? id,
          String? profile,
          int? forceRevisionOnly,
          int? dailyMinutesDefault,
          Value<String?> minutesByWeekdayJson = const Value.absent(),
          int? maxNewPagesPerDay,
          int? maxNewUnitsPerDay,
          double? avgNewMinutesPerAyah,
          double? avgReviewMinutesPerAyah,
          int? requirePageMetadata,
          Value<String?> typicalGradeDistributionJson = const Value.absent(),
          int? updatedAtDay}) =>
      AppSetting(
        id: id ?? this.id,
        profile: profile ?? this.profile,
        forceRevisionOnly: forceRevisionOnly ?? this.forceRevisionOnly,
        dailyMinutesDefault: dailyMinutesDefault ?? this.dailyMinutesDefault,
        minutesByWeekdayJson: minutesByWeekdayJson.present
            ? minutesByWeekdayJson.value
            : this.minutesByWeekdayJson,
        maxNewPagesPerDay: maxNewPagesPerDay ?? this.maxNewPagesPerDay,
        maxNewUnitsPerDay: maxNewUnitsPerDay ?? this.maxNewUnitsPerDay,
        avgNewMinutesPerAyah: avgNewMinutesPerAyah ?? this.avgNewMinutesPerAyah,
        avgReviewMinutesPerAyah:
            avgReviewMinutesPerAyah ?? this.avgReviewMinutesPerAyah,
        requirePageMetadata: requirePageMetadata ?? this.requirePageMetadata,
        typicalGradeDistributionJson: typicalGradeDistributionJson.present
            ? typicalGradeDistributionJson.value
            : this.typicalGradeDistributionJson,
        updatedAtDay: updatedAtDay ?? this.updatedAtDay,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      profile: data.profile.present ? data.profile.value : this.profile,
      forceRevisionOnly: data.forceRevisionOnly.present
          ? data.forceRevisionOnly.value
          : this.forceRevisionOnly,
      dailyMinutesDefault: data.dailyMinutesDefault.present
          ? data.dailyMinutesDefault.value
          : this.dailyMinutesDefault,
      minutesByWeekdayJson: data.minutesByWeekdayJson.present
          ? data.minutesByWeekdayJson.value
          : this.minutesByWeekdayJson,
      maxNewPagesPerDay: data.maxNewPagesPerDay.present
          ? data.maxNewPagesPerDay.value
          : this.maxNewPagesPerDay,
      maxNewUnitsPerDay: data.maxNewUnitsPerDay.present
          ? data.maxNewUnitsPerDay.value
          : this.maxNewUnitsPerDay,
      avgNewMinutesPerAyah: data.avgNewMinutesPerAyah.present
          ? data.avgNewMinutesPerAyah.value
          : this.avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah: data.avgReviewMinutesPerAyah.present
          ? data.avgReviewMinutesPerAyah.value
          : this.avgReviewMinutesPerAyah,
      requirePageMetadata: data.requirePageMetadata.present
          ? data.requirePageMetadata.value
          : this.requirePageMetadata,
      typicalGradeDistributionJson: data.typicalGradeDistributionJson.present
          ? data.typicalGradeDistributionJson.value
          : this.typicalGradeDistributionJson,
      updatedAtDay: data.updatedAtDay.present
          ? data.updatedAtDay.value
          : this.updatedAtDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('profile: $profile, ')
          ..write('forceRevisionOnly: $forceRevisionOnly, ')
          ..write('dailyMinutesDefault: $dailyMinutesDefault, ')
          ..write('minutesByWeekdayJson: $minutesByWeekdayJson, ')
          ..write('maxNewPagesPerDay: $maxNewPagesPerDay, ')
          ..write('maxNewUnitsPerDay: $maxNewUnitsPerDay, ')
          ..write('avgNewMinutesPerAyah: $avgNewMinutesPerAyah, ')
          ..write('avgReviewMinutesPerAyah: $avgReviewMinutesPerAyah, ')
          ..write('requirePageMetadata: $requirePageMetadata, ')
          ..write(
              'typicalGradeDistributionJson: $typicalGradeDistributionJson, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profile,
      forceRevisionOnly,
      dailyMinutesDefault,
      minutesByWeekdayJson,
      maxNewPagesPerDay,
      maxNewUnitsPerDay,
      avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah,
      requirePageMetadata,
      typicalGradeDistributionJson,
      updatedAtDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.profile == this.profile &&
          other.forceRevisionOnly == this.forceRevisionOnly &&
          other.dailyMinutesDefault == this.dailyMinutesDefault &&
          other.minutesByWeekdayJson == this.minutesByWeekdayJson &&
          other.maxNewPagesPerDay == this.maxNewPagesPerDay &&
          other.maxNewUnitsPerDay == this.maxNewUnitsPerDay &&
          other.avgNewMinutesPerAyah == this.avgNewMinutesPerAyah &&
          other.avgReviewMinutesPerAyah == this.avgReviewMinutesPerAyah &&
          other.requirePageMetadata == this.requirePageMetadata &&
          other.typicalGradeDistributionJson ==
              this.typicalGradeDistributionJson &&
          other.updatedAtDay == this.updatedAtDay);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> profile;
  final Value<int> forceRevisionOnly;
  final Value<int> dailyMinutesDefault;
  final Value<String?> minutesByWeekdayJson;
  final Value<int> maxNewPagesPerDay;
  final Value<int> maxNewUnitsPerDay;
  final Value<double> avgNewMinutesPerAyah;
  final Value<double> avgReviewMinutesPerAyah;
  final Value<int> requirePageMetadata;
  final Value<String?> typicalGradeDistributionJson;
  final Value<int> updatedAtDay;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.profile = const Value.absent(),
    this.forceRevisionOnly = const Value.absent(),
    this.dailyMinutesDefault = const Value.absent(),
    this.minutesByWeekdayJson = const Value.absent(),
    this.maxNewPagesPerDay = const Value.absent(),
    this.maxNewUnitsPerDay = const Value.absent(),
    this.avgNewMinutesPerAyah = const Value.absent(),
    this.avgReviewMinutesPerAyah = const Value.absent(),
    this.requirePageMetadata = const Value.absent(),
    this.typicalGradeDistributionJson = const Value.absent(),
    this.updatedAtDay = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String profile,
    required int forceRevisionOnly,
    required int dailyMinutesDefault,
    this.minutesByWeekdayJson = const Value.absent(),
    required int maxNewPagesPerDay,
    required int maxNewUnitsPerDay,
    required double avgNewMinutesPerAyah,
    required double avgReviewMinutesPerAyah,
    this.requirePageMetadata = const Value.absent(),
    this.typicalGradeDistributionJson = const Value.absent(),
    required int updatedAtDay,
  })  : profile = Value(profile),
        forceRevisionOnly = Value(forceRevisionOnly),
        dailyMinutesDefault = Value(dailyMinutesDefault),
        maxNewPagesPerDay = Value(maxNewPagesPerDay),
        maxNewUnitsPerDay = Value(maxNewUnitsPerDay),
        avgNewMinutesPerAyah = Value(avgNewMinutesPerAyah),
        avgReviewMinutesPerAyah = Value(avgReviewMinutesPerAyah),
        updatedAtDay = Value(updatedAtDay);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? profile,
    Expression<int>? forceRevisionOnly,
    Expression<int>? dailyMinutesDefault,
    Expression<String>? minutesByWeekdayJson,
    Expression<int>? maxNewPagesPerDay,
    Expression<int>? maxNewUnitsPerDay,
    Expression<double>? avgNewMinutesPerAyah,
    Expression<double>? avgReviewMinutesPerAyah,
    Expression<int>? requirePageMetadata,
    Expression<String>? typicalGradeDistributionJson,
    Expression<int>? updatedAtDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profile != null) 'profile': profile,
      if (forceRevisionOnly != null) 'force_revision_only': forceRevisionOnly,
      if (dailyMinutesDefault != null)
        'daily_minutes_default': dailyMinutesDefault,
      if (minutesByWeekdayJson != null)
        'minutes_by_weekday_json': minutesByWeekdayJson,
      if (maxNewPagesPerDay != null) 'max_new_pages_per_day': maxNewPagesPerDay,
      if (maxNewUnitsPerDay != null) 'max_new_units_per_day': maxNewUnitsPerDay,
      if (avgNewMinutesPerAyah != null)
        'avg_new_minutes_per_ayah': avgNewMinutesPerAyah,
      if (avgReviewMinutesPerAyah != null)
        'avg_review_minutes_per_ayah': avgReviewMinutesPerAyah,
      if (requirePageMetadata != null)
        'require_page_metadata': requirePageMetadata,
      if (typicalGradeDistributionJson != null)
        'typical_grade_distribution_json': typicalGradeDistributionJson,
      if (updatedAtDay != null) 'updated_at_day': updatedAtDay,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? profile,
      Value<int>? forceRevisionOnly,
      Value<int>? dailyMinutesDefault,
      Value<String?>? minutesByWeekdayJson,
      Value<int>? maxNewPagesPerDay,
      Value<int>? maxNewUnitsPerDay,
      Value<double>? avgNewMinutesPerAyah,
      Value<double>? avgReviewMinutesPerAyah,
      Value<int>? requirePageMetadata,
      Value<String?>? typicalGradeDistributionJson,
      Value<int>? updatedAtDay}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      profile: profile ?? this.profile,
      forceRevisionOnly: forceRevisionOnly ?? this.forceRevisionOnly,
      dailyMinutesDefault: dailyMinutesDefault ?? this.dailyMinutesDefault,
      minutesByWeekdayJson: minutesByWeekdayJson ?? this.minutesByWeekdayJson,
      maxNewPagesPerDay: maxNewPagesPerDay ?? this.maxNewPagesPerDay,
      maxNewUnitsPerDay: maxNewUnitsPerDay ?? this.maxNewUnitsPerDay,
      avgNewMinutesPerAyah: avgNewMinutesPerAyah ?? this.avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah:
          avgReviewMinutesPerAyah ?? this.avgReviewMinutesPerAyah,
      requirePageMetadata: requirePageMetadata ?? this.requirePageMetadata,
      typicalGradeDistributionJson:
          typicalGradeDistributionJson ?? this.typicalGradeDistributionJson,
      updatedAtDay: updatedAtDay ?? this.updatedAtDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profile.present) {
      map['profile'] = Variable<String>(profile.value);
    }
    if (forceRevisionOnly.present) {
      map['force_revision_only'] = Variable<int>(forceRevisionOnly.value);
    }
    if (dailyMinutesDefault.present) {
      map['daily_minutes_default'] = Variable<int>(dailyMinutesDefault.value);
    }
    if (minutesByWeekdayJson.present) {
      map['minutes_by_weekday_json'] =
          Variable<String>(minutesByWeekdayJson.value);
    }
    if (maxNewPagesPerDay.present) {
      map['max_new_pages_per_day'] = Variable<int>(maxNewPagesPerDay.value);
    }
    if (maxNewUnitsPerDay.present) {
      map['max_new_units_per_day'] = Variable<int>(maxNewUnitsPerDay.value);
    }
    if (avgNewMinutesPerAyah.present) {
      map['avg_new_minutes_per_ayah'] =
          Variable<double>(avgNewMinutesPerAyah.value);
    }
    if (avgReviewMinutesPerAyah.present) {
      map['avg_review_minutes_per_ayah'] =
          Variable<double>(avgReviewMinutesPerAyah.value);
    }
    if (requirePageMetadata.present) {
      map['require_page_metadata'] = Variable<int>(requirePageMetadata.value);
    }
    if (typicalGradeDistributionJson.present) {
      map['typical_grade_distribution_json'] =
          Variable<String>(typicalGradeDistributionJson.value);
    }
    if (updatedAtDay.present) {
      map['updated_at_day'] = Variable<int>(updatedAtDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('profile: $profile, ')
          ..write('forceRevisionOnly: $forceRevisionOnly, ')
          ..write('dailyMinutesDefault: $dailyMinutesDefault, ')
          ..write('minutesByWeekdayJson: $minutesByWeekdayJson, ')
          ..write('maxNewPagesPerDay: $maxNewPagesPerDay, ')
          ..write('maxNewUnitsPerDay: $maxNewUnitsPerDay, ')
          ..write('avgNewMinutesPerAyah: $avgNewMinutesPerAyah, ')
          ..write('avgReviewMinutesPerAyah: $avgReviewMinutesPerAyah, ')
          ..write('requirePageMetadata: $requirePageMetadata, ')
          ..write(
              'typicalGradeDistributionJson: $typicalGradeDistributionJson, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }
}

class $MemProgressTable extends MemProgress
    with TableInfo<$MemProgressTable, MemProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      check: () => id.equals(1),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _nextSurahMeta =
      const VerificationMeta('nextSurah');
  @override
  late final GeneratedColumn<int> nextSurah = GeneratedColumn<int>(
      'next_surah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nextAyahMeta =
      const VerificationMeta('nextAyah');
  @override
  late final GeneratedColumn<int> nextAyah = GeneratedColumn<int>(
      'next_ayah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtDayMeta =
      const VerificationMeta('updatedAtDay');
  @override
  late final GeneratedColumn<int> updatedAtDay = GeneratedColumn<int>(
      'updated_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, nextSurah, nextAyah, updatedAtDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mem_progress';
  @override
  VerificationContext validateIntegrity(Insertable<MemProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('next_surah')) {
      context.handle(_nextSurahMeta,
          nextSurah.isAcceptableOrUnknown(data['next_surah']!, _nextSurahMeta));
    } else if (isInserting) {
      context.missing(_nextSurahMeta);
    }
    if (data.containsKey('next_ayah')) {
      context.handle(_nextAyahMeta,
          nextAyah.isAcceptableOrUnknown(data['next_ayah']!, _nextAyahMeta));
    } else if (isInserting) {
      context.missing(_nextAyahMeta);
    }
    if (data.containsKey('updated_at_day')) {
      context.handle(
          _updatedAtDayMeta,
          updatedAtDay.isAcceptableOrUnknown(
              data['updated_at_day']!, _updatedAtDayMeta));
    } else if (isInserting) {
      context.missing(_updatedAtDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nextSurah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_surah'])!,
      nextAyah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_ayah'])!,
      updatedAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_day'])!,
    );
  }

  @override
  $MemProgressTable createAlias(String alias) {
    return $MemProgressTable(attachedDatabase, alias);
  }
}

class MemProgressData extends DataClass implements Insertable<MemProgressData> {
  final int id;
  final int nextSurah;
  final int nextAyah;
  final int updatedAtDay;
  const MemProgressData(
      {required this.id,
      required this.nextSurah,
      required this.nextAyah,
      required this.updatedAtDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_surah'] = Variable<int>(nextSurah);
    map['next_ayah'] = Variable<int>(nextAyah);
    map['updated_at_day'] = Variable<int>(updatedAtDay);
    return map;
  }

  MemProgressCompanion toCompanion(bool nullToAbsent) {
    return MemProgressCompanion(
      id: Value(id),
      nextSurah: Value(nextSurah),
      nextAyah: Value(nextAyah),
      updatedAtDay: Value(updatedAtDay),
    );
  }

  factory MemProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemProgressData(
      id: serializer.fromJson<int>(json['id']),
      nextSurah: serializer.fromJson<int>(json['nextSurah']),
      nextAyah: serializer.fromJson<int>(json['nextAyah']),
      updatedAtDay: serializer.fromJson<int>(json['updatedAtDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextSurah': serializer.toJson<int>(nextSurah),
      'nextAyah': serializer.toJson<int>(nextAyah),
      'updatedAtDay': serializer.toJson<int>(updatedAtDay),
    };
  }

  MemProgressData copyWith(
          {int? id, int? nextSurah, int? nextAyah, int? updatedAtDay}) =>
      MemProgressData(
        id: id ?? this.id,
        nextSurah: nextSurah ?? this.nextSurah,
        nextAyah: nextAyah ?? this.nextAyah,
        updatedAtDay: updatedAtDay ?? this.updatedAtDay,
      );
  MemProgressData copyWithCompanion(MemProgressCompanion data) {
    return MemProgressData(
      id: data.id.present ? data.id.value : this.id,
      nextSurah: data.nextSurah.present ? data.nextSurah.value : this.nextSurah,
      nextAyah: data.nextAyah.present ? data.nextAyah.value : this.nextAyah,
      updatedAtDay: data.updatedAtDay.present
          ? data.updatedAtDay.value
          : this.updatedAtDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemProgressData(')
          ..write('id: $id, ')
          ..write('nextSurah: $nextSurah, ')
          ..write('nextAyah: $nextAyah, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nextSurah, nextAyah, updatedAtDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemProgressData &&
          other.id == this.id &&
          other.nextSurah == this.nextSurah &&
          other.nextAyah == this.nextAyah &&
          other.updatedAtDay == this.updatedAtDay);
}

class MemProgressCompanion extends UpdateCompanion<MemProgressData> {
  final Value<int> id;
  final Value<int> nextSurah;
  final Value<int> nextAyah;
  final Value<int> updatedAtDay;
  const MemProgressCompanion({
    this.id = const Value.absent(),
    this.nextSurah = const Value.absent(),
    this.nextAyah = const Value.absent(),
    this.updatedAtDay = const Value.absent(),
  });
  MemProgressCompanion.insert({
    this.id = const Value.absent(),
    required int nextSurah,
    required int nextAyah,
    required int updatedAtDay,
  })  : nextSurah = Value(nextSurah),
        nextAyah = Value(nextAyah),
        updatedAtDay = Value(updatedAtDay);
  static Insertable<MemProgressData> custom({
    Expression<int>? id,
    Expression<int>? nextSurah,
    Expression<int>? nextAyah,
    Expression<int>? updatedAtDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextSurah != null) 'next_surah': nextSurah,
      if (nextAyah != null) 'next_ayah': nextAyah,
      if (updatedAtDay != null) 'updated_at_day': updatedAtDay,
    });
  }

  MemProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? nextSurah,
      Value<int>? nextAyah,
      Value<int>? updatedAtDay}) {
    return MemProgressCompanion(
      id: id ?? this.id,
      nextSurah: nextSurah ?? this.nextSurah,
      nextAyah: nextAyah ?? this.nextAyah,
      updatedAtDay: updatedAtDay ?? this.updatedAtDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nextSurah.present) {
      map['next_surah'] = Variable<int>(nextSurah.value);
    }
    if (nextAyah.present) {
      map['next_ayah'] = Variable<int>(nextAyah.value);
    }
    if (updatedAtDay.present) {
      map['updated_at_day'] = Variable<int>(updatedAtDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemProgressCompanion(')
          ..write('id: $id, ')
          ..write('nextSurah: $nextSurah, ')
          ..write('nextAyah: $nextAyah, ')
          ..write('updatedAtDay: $updatedAtDay')
          ..write(')'))
        .toString();
  }
}

class $CalibrationSampleTable extends CalibrationSample
    with TableInfo<$CalibrationSampleTable, CalibrationSampleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalibrationSampleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sampleKindMeta =
      const VerificationMeta('sampleKind');
  @override
  late final GeneratedColumn<String> sampleKind = GeneratedColumn<String>(
      'sample_kind', aliasedName, false,
      check: () => sampleKind.isIn(const ['new_memorization', 'review']),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      check: () => ComparableExpr(durationSeconds).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _ayahCountMeta =
      const VerificationMeta('ayahCount');
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
      'ayah_count', aliasedName, false,
      check: () => ComparableExpr(ayahCount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtDayMeta =
      const VerificationMeta('createdAtDay');
  @override
  late final GeneratedColumn<int> createdAtDay = GeneratedColumn<int>(
      'created_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtSecondsMeta =
      const VerificationMeta('createdAtSeconds');
  @override
  late final GeneratedColumn<int> createdAtSeconds = GeneratedColumn<int>(
      'created_at_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sampleKind,
        durationSeconds,
        ayahCount,
        createdAtDay,
        createdAtSeconds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calibration_sample';
  @override
  VerificationContext validateIntegrity(
      Insertable<CalibrationSampleData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sample_kind')) {
      context.handle(
          _sampleKindMeta,
          sampleKind.isAcceptableOrUnknown(
              data['sample_kind']!, _sampleKindMeta));
    } else if (isInserting) {
      context.missing(_sampleKindMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(_ayahCountMeta,
          ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta));
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('created_at_day')) {
      context.handle(
          _createdAtDayMeta,
          createdAtDay.isAcceptableOrUnknown(
              data['created_at_day']!, _createdAtDayMeta));
    } else if (isInserting) {
      context.missing(_createdAtDayMeta);
    }
    if (data.containsKey('created_at_seconds')) {
      context.handle(
          _createdAtSecondsMeta,
          createdAtSeconds.isAcceptableOrUnknown(
              data['created_at_seconds']!, _createdAtSecondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalibrationSampleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalibrationSampleData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sampleKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sample_kind'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      ayahCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_count'])!,
      createdAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_day'])!,
      createdAtSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_seconds']),
    );
  }

  @override
  $CalibrationSampleTable createAlias(String alias) {
    return $CalibrationSampleTable(attachedDatabase, alias);
  }
}

class CalibrationSampleData extends DataClass
    implements Insertable<CalibrationSampleData> {
  final int id;
  final String sampleKind;
  final int durationSeconds;
  final int ayahCount;
  final int createdAtDay;
  final int? createdAtSeconds;
  const CalibrationSampleData(
      {required this.id,
      required this.sampleKind,
      required this.durationSeconds,
      required this.ayahCount,
      required this.createdAtDay,
      this.createdAtSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sample_kind'] = Variable<String>(sampleKind);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['created_at_day'] = Variable<int>(createdAtDay);
    if (!nullToAbsent || createdAtSeconds != null) {
      map['created_at_seconds'] = Variable<int>(createdAtSeconds);
    }
    return map;
  }

  CalibrationSampleCompanion toCompanion(bool nullToAbsent) {
    return CalibrationSampleCompanion(
      id: Value(id),
      sampleKind: Value(sampleKind),
      durationSeconds: Value(durationSeconds),
      ayahCount: Value(ayahCount),
      createdAtDay: Value(createdAtDay),
      createdAtSeconds: createdAtSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAtSeconds),
    );
  }

  factory CalibrationSampleData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalibrationSampleData(
      id: serializer.fromJson<int>(json['id']),
      sampleKind: serializer.fromJson<String>(json['sampleKind']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      createdAtDay: serializer.fromJson<int>(json['createdAtDay']),
      createdAtSeconds: serializer.fromJson<int?>(json['createdAtSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sampleKind': serializer.toJson<String>(sampleKind),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'createdAtDay': serializer.toJson<int>(createdAtDay),
      'createdAtSeconds': serializer.toJson<int?>(createdAtSeconds),
    };
  }

  CalibrationSampleData copyWith(
          {int? id,
          String? sampleKind,
          int? durationSeconds,
          int? ayahCount,
          int? createdAtDay,
          Value<int?> createdAtSeconds = const Value.absent()}) =>
      CalibrationSampleData(
        id: id ?? this.id,
        sampleKind: sampleKind ?? this.sampleKind,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        ayahCount: ayahCount ?? this.ayahCount,
        createdAtDay: createdAtDay ?? this.createdAtDay,
        createdAtSeconds: createdAtSeconds.present
            ? createdAtSeconds.value
            : this.createdAtSeconds,
      );
  CalibrationSampleData copyWithCompanion(CalibrationSampleCompanion data) {
    return CalibrationSampleData(
      id: data.id.present ? data.id.value : this.id,
      sampleKind:
          data.sampleKind.present ? data.sampleKind.value : this.sampleKind,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      createdAtDay: data.createdAtDay.present
          ? data.createdAtDay.value
          : this.createdAtDay,
      createdAtSeconds: data.createdAtSeconds.present
          ? data.createdAtSeconds.value
          : this.createdAtSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationSampleData(')
          ..write('id: $id, ')
          ..write('sampleKind: $sampleKind, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('createdAtDay: $createdAtDay, ')
          ..write('createdAtSeconds: $createdAtSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sampleKind, durationSeconds, ayahCount,
      createdAtDay, createdAtSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalibrationSampleData &&
          other.id == this.id &&
          other.sampleKind == this.sampleKind &&
          other.durationSeconds == this.durationSeconds &&
          other.ayahCount == this.ayahCount &&
          other.createdAtDay == this.createdAtDay &&
          other.createdAtSeconds == this.createdAtSeconds);
}

class CalibrationSampleCompanion
    extends UpdateCompanion<CalibrationSampleData> {
  final Value<int> id;
  final Value<String> sampleKind;
  final Value<int> durationSeconds;
  final Value<int> ayahCount;
  final Value<int> createdAtDay;
  final Value<int?> createdAtSeconds;
  const CalibrationSampleCompanion({
    this.id = const Value.absent(),
    this.sampleKind = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.createdAtDay = const Value.absent(),
    this.createdAtSeconds = const Value.absent(),
  });
  CalibrationSampleCompanion.insert({
    this.id = const Value.absent(),
    required String sampleKind,
    required int durationSeconds,
    required int ayahCount,
    required int createdAtDay,
    this.createdAtSeconds = const Value.absent(),
  })  : sampleKind = Value(sampleKind),
        durationSeconds = Value(durationSeconds),
        ayahCount = Value(ayahCount),
        createdAtDay = Value(createdAtDay);
  static Insertable<CalibrationSampleData> custom({
    Expression<int>? id,
    Expression<String>? sampleKind,
    Expression<int>? durationSeconds,
    Expression<int>? ayahCount,
    Expression<int>? createdAtDay,
    Expression<int>? createdAtSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sampleKind != null) 'sample_kind': sampleKind,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (createdAtDay != null) 'created_at_day': createdAtDay,
      if (createdAtSeconds != null) 'created_at_seconds': createdAtSeconds,
    });
  }

  CalibrationSampleCompanion copyWith(
      {Value<int>? id,
      Value<String>? sampleKind,
      Value<int>? durationSeconds,
      Value<int>? ayahCount,
      Value<int>? createdAtDay,
      Value<int?>? createdAtSeconds}) {
    return CalibrationSampleCompanion(
      id: id ?? this.id,
      sampleKind: sampleKind ?? this.sampleKind,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      ayahCount: ayahCount ?? this.ayahCount,
      createdAtDay: createdAtDay ?? this.createdAtDay,
      createdAtSeconds: createdAtSeconds ?? this.createdAtSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sampleKind.present) {
      map['sample_kind'] = Variable<String>(sampleKind.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (createdAtDay.present) {
      map['created_at_day'] = Variable<int>(createdAtDay.value);
    }
    if (createdAtSeconds.present) {
      map['created_at_seconds'] = Variable<int>(createdAtSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalibrationSampleCompanion(')
          ..write('id: $id, ')
          ..write('sampleKind: $sampleKind, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('createdAtDay: $createdAtDay, ')
          ..write('createdAtSeconds: $createdAtSeconds')
          ..write(')'))
        .toString();
  }
}

class $PendingCalibrationUpdateTable extends PendingCalibrationUpdate
    with
        TableInfo<$PendingCalibrationUpdateTable,
            PendingCalibrationUpdateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingCalibrationUpdateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      check: () => id.equals(1),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _avgNewMinutesPerAyahMeta =
      const VerificationMeta('avgNewMinutesPerAyah');
  @override
  late final GeneratedColumn<double> avgNewMinutesPerAyah =
      GeneratedColumn<double>('avg_new_minutes_per_ayah', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgReviewMinutesPerAyahMeta =
      const VerificationMeta('avgReviewMinutesPerAyah');
  @override
  late final GeneratedColumn<double> avgReviewMinutesPerAyah =
      GeneratedColumn<double>('avg_review_minutes_per_ayah', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _typicalGradeDistributionJsonMeta =
      const VerificationMeta('typicalGradeDistributionJson');
  @override
  late final GeneratedColumn<String> typicalGradeDistributionJson =
      GeneratedColumn<String>(
          'typical_grade_distribution_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effectiveDayMeta =
      const VerificationMeta('effectiveDay');
  @override
  late final GeneratedColumn<int> effectiveDay = GeneratedColumn<int>(
      'effective_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtDayMeta =
      const VerificationMeta('createdAtDay');
  @override
  late final GeneratedColumn<int> createdAtDay = GeneratedColumn<int>(
      'created_at_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        avgNewMinutesPerAyah,
        avgReviewMinutesPerAyah,
        typicalGradeDistributionJson,
        effectiveDay,
        createdAtDay
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_calibration_update';
  @override
  VerificationContext validateIntegrity(
      Insertable<PendingCalibrationUpdateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('avg_new_minutes_per_ayah')) {
      context.handle(
          _avgNewMinutesPerAyahMeta,
          avgNewMinutesPerAyah.isAcceptableOrUnknown(
              data['avg_new_minutes_per_ayah']!, _avgNewMinutesPerAyahMeta));
    }
    if (data.containsKey('avg_review_minutes_per_ayah')) {
      context.handle(
          _avgReviewMinutesPerAyahMeta,
          avgReviewMinutesPerAyah.isAcceptableOrUnknown(
              data['avg_review_minutes_per_ayah']!,
              _avgReviewMinutesPerAyahMeta));
    }
    if (data.containsKey('typical_grade_distribution_json')) {
      context.handle(
          _typicalGradeDistributionJsonMeta,
          typicalGradeDistributionJson.isAcceptableOrUnknown(
              data['typical_grade_distribution_json']!,
              _typicalGradeDistributionJsonMeta));
    }
    if (data.containsKey('effective_day')) {
      context.handle(
          _effectiveDayMeta,
          effectiveDay.isAcceptableOrUnknown(
              data['effective_day']!, _effectiveDayMeta));
    } else if (isInserting) {
      context.missing(_effectiveDayMeta);
    }
    if (data.containsKey('created_at_day')) {
      context.handle(
          _createdAtDayMeta,
          createdAtDay.isAcceptableOrUnknown(
              data['created_at_day']!, _createdAtDayMeta));
    } else if (isInserting) {
      context.missing(_createdAtDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingCalibrationUpdateData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingCalibrationUpdateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      avgNewMinutesPerAyah: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_new_minutes_per_ayah']),
      avgReviewMinutesPerAyah: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}avg_review_minutes_per_ayah']),
      typicalGradeDistributionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}typical_grade_distribution_json']),
      effectiveDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}effective_day'])!,
      createdAtDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_day'])!,
    );
  }

  @override
  $PendingCalibrationUpdateTable createAlias(String alias) {
    return $PendingCalibrationUpdateTable(attachedDatabase, alias);
  }
}

class PendingCalibrationUpdateData extends DataClass
    implements Insertable<PendingCalibrationUpdateData> {
  final int id;
  final double? avgNewMinutesPerAyah;
  final double? avgReviewMinutesPerAyah;
  final String? typicalGradeDistributionJson;
  final int effectiveDay;
  final int createdAtDay;
  const PendingCalibrationUpdateData(
      {required this.id,
      this.avgNewMinutesPerAyah,
      this.avgReviewMinutesPerAyah,
      this.typicalGradeDistributionJson,
      required this.effectiveDay,
      required this.createdAtDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || avgNewMinutesPerAyah != null) {
      map['avg_new_minutes_per_ayah'] = Variable<double>(avgNewMinutesPerAyah);
    }
    if (!nullToAbsent || avgReviewMinutesPerAyah != null) {
      map['avg_review_minutes_per_ayah'] =
          Variable<double>(avgReviewMinutesPerAyah);
    }
    if (!nullToAbsent || typicalGradeDistributionJson != null) {
      map['typical_grade_distribution_json'] =
          Variable<String>(typicalGradeDistributionJson);
    }
    map['effective_day'] = Variable<int>(effectiveDay);
    map['created_at_day'] = Variable<int>(createdAtDay);
    return map;
  }

  PendingCalibrationUpdateCompanion toCompanion(bool nullToAbsent) {
    return PendingCalibrationUpdateCompanion(
      id: Value(id),
      avgNewMinutesPerAyah: avgNewMinutesPerAyah == null && nullToAbsent
          ? const Value.absent()
          : Value(avgNewMinutesPerAyah),
      avgReviewMinutesPerAyah: avgReviewMinutesPerAyah == null && nullToAbsent
          ? const Value.absent()
          : Value(avgReviewMinutesPerAyah),
      typicalGradeDistributionJson:
          typicalGradeDistributionJson == null && nullToAbsent
              ? const Value.absent()
              : Value(typicalGradeDistributionJson),
      effectiveDay: Value(effectiveDay),
      createdAtDay: Value(createdAtDay),
    );
  }

  factory PendingCalibrationUpdateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingCalibrationUpdateData(
      id: serializer.fromJson<int>(json['id']),
      avgNewMinutesPerAyah:
          serializer.fromJson<double?>(json['avgNewMinutesPerAyah']),
      avgReviewMinutesPerAyah:
          serializer.fromJson<double?>(json['avgReviewMinutesPerAyah']),
      typicalGradeDistributionJson:
          serializer.fromJson<String?>(json['typicalGradeDistributionJson']),
      effectiveDay: serializer.fromJson<int>(json['effectiveDay']),
      createdAtDay: serializer.fromJson<int>(json['createdAtDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'avgNewMinutesPerAyah': serializer.toJson<double?>(avgNewMinutesPerAyah),
      'avgReviewMinutesPerAyah':
          serializer.toJson<double?>(avgReviewMinutesPerAyah),
      'typicalGradeDistributionJson':
          serializer.toJson<String?>(typicalGradeDistributionJson),
      'effectiveDay': serializer.toJson<int>(effectiveDay),
      'createdAtDay': serializer.toJson<int>(createdAtDay),
    };
  }

  PendingCalibrationUpdateData copyWith(
          {int? id,
          Value<double?> avgNewMinutesPerAyah = const Value.absent(),
          Value<double?> avgReviewMinutesPerAyah = const Value.absent(),
          Value<String?> typicalGradeDistributionJson = const Value.absent(),
          int? effectiveDay,
          int? createdAtDay}) =>
      PendingCalibrationUpdateData(
        id: id ?? this.id,
        avgNewMinutesPerAyah: avgNewMinutesPerAyah.present
            ? avgNewMinutesPerAyah.value
            : this.avgNewMinutesPerAyah,
        avgReviewMinutesPerAyah: avgReviewMinutesPerAyah.present
            ? avgReviewMinutesPerAyah.value
            : this.avgReviewMinutesPerAyah,
        typicalGradeDistributionJson: typicalGradeDistributionJson.present
            ? typicalGradeDistributionJson.value
            : this.typicalGradeDistributionJson,
        effectiveDay: effectiveDay ?? this.effectiveDay,
        createdAtDay: createdAtDay ?? this.createdAtDay,
      );
  PendingCalibrationUpdateData copyWithCompanion(
      PendingCalibrationUpdateCompanion data) {
    return PendingCalibrationUpdateData(
      id: data.id.present ? data.id.value : this.id,
      avgNewMinutesPerAyah: data.avgNewMinutesPerAyah.present
          ? data.avgNewMinutesPerAyah.value
          : this.avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah: data.avgReviewMinutesPerAyah.present
          ? data.avgReviewMinutesPerAyah.value
          : this.avgReviewMinutesPerAyah,
      typicalGradeDistributionJson: data.typicalGradeDistributionJson.present
          ? data.typicalGradeDistributionJson.value
          : this.typicalGradeDistributionJson,
      effectiveDay: data.effectiveDay.present
          ? data.effectiveDay.value
          : this.effectiveDay,
      createdAtDay: data.createdAtDay.present
          ? data.createdAtDay.value
          : this.createdAtDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCalibrationUpdateData(')
          ..write('id: $id, ')
          ..write('avgNewMinutesPerAyah: $avgNewMinutesPerAyah, ')
          ..write('avgReviewMinutesPerAyah: $avgReviewMinutesPerAyah, ')
          ..write(
              'typicalGradeDistributionJson: $typicalGradeDistributionJson, ')
          ..write('effectiveDay: $effectiveDay, ')
          ..write('createdAtDay: $createdAtDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah,
      typicalGradeDistributionJson,
      effectiveDay,
      createdAtDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCalibrationUpdateData &&
          other.id == this.id &&
          other.avgNewMinutesPerAyah == this.avgNewMinutesPerAyah &&
          other.avgReviewMinutesPerAyah == this.avgReviewMinutesPerAyah &&
          other.typicalGradeDistributionJson ==
              this.typicalGradeDistributionJson &&
          other.effectiveDay == this.effectiveDay &&
          other.createdAtDay == this.createdAtDay);
}

class PendingCalibrationUpdateCompanion
    extends UpdateCompanion<PendingCalibrationUpdateData> {
  final Value<int> id;
  final Value<double?> avgNewMinutesPerAyah;
  final Value<double?> avgReviewMinutesPerAyah;
  final Value<String?> typicalGradeDistributionJson;
  final Value<int> effectiveDay;
  final Value<int> createdAtDay;
  const PendingCalibrationUpdateCompanion({
    this.id = const Value.absent(),
    this.avgNewMinutesPerAyah = const Value.absent(),
    this.avgReviewMinutesPerAyah = const Value.absent(),
    this.typicalGradeDistributionJson = const Value.absent(),
    this.effectiveDay = const Value.absent(),
    this.createdAtDay = const Value.absent(),
  });
  PendingCalibrationUpdateCompanion.insert({
    this.id = const Value.absent(),
    this.avgNewMinutesPerAyah = const Value.absent(),
    this.avgReviewMinutesPerAyah = const Value.absent(),
    this.typicalGradeDistributionJson = const Value.absent(),
    required int effectiveDay,
    required int createdAtDay,
  })  : effectiveDay = Value(effectiveDay),
        createdAtDay = Value(createdAtDay);
  static Insertable<PendingCalibrationUpdateData> custom({
    Expression<int>? id,
    Expression<double>? avgNewMinutesPerAyah,
    Expression<double>? avgReviewMinutesPerAyah,
    Expression<String>? typicalGradeDistributionJson,
    Expression<int>? effectiveDay,
    Expression<int>? createdAtDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (avgNewMinutesPerAyah != null)
        'avg_new_minutes_per_ayah': avgNewMinutesPerAyah,
      if (avgReviewMinutesPerAyah != null)
        'avg_review_minutes_per_ayah': avgReviewMinutesPerAyah,
      if (typicalGradeDistributionJson != null)
        'typical_grade_distribution_json': typicalGradeDistributionJson,
      if (effectiveDay != null) 'effective_day': effectiveDay,
      if (createdAtDay != null) 'created_at_day': createdAtDay,
    });
  }

  PendingCalibrationUpdateCompanion copyWith(
      {Value<int>? id,
      Value<double?>? avgNewMinutesPerAyah,
      Value<double?>? avgReviewMinutesPerAyah,
      Value<String?>? typicalGradeDistributionJson,
      Value<int>? effectiveDay,
      Value<int>? createdAtDay}) {
    return PendingCalibrationUpdateCompanion(
      id: id ?? this.id,
      avgNewMinutesPerAyah: avgNewMinutesPerAyah ?? this.avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah:
          avgReviewMinutesPerAyah ?? this.avgReviewMinutesPerAyah,
      typicalGradeDistributionJson:
          typicalGradeDistributionJson ?? this.typicalGradeDistributionJson,
      effectiveDay: effectiveDay ?? this.effectiveDay,
      createdAtDay: createdAtDay ?? this.createdAtDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (avgNewMinutesPerAyah.present) {
      map['avg_new_minutes_per_ayah'] =
          Variable<double>(avgNewMinutesPerAyah.value);
    }
    if (avgReviewMinutesPerAyah.present) {
      map['avg_review_minutes_per_ayah'] =
          Variable<double>(avgReviewMinutesPerAyah.value);
    }
    if (typicalGradeDistributionJson.present) {
      map['typical_grade_distribution_json'] =
          Variable<String>(typicalGradeDistributionJson.value);
    }
    if (effectiveDay.present) {
      map['effective_day'] = Variable<int>(effectiveDay.value);
    }
    if (createdAtDay.present) {
      map['created_at_day'] = Variable<int>(createdAtDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingCalibrationUpdateCompanion(')
          ..write('id: $id, ')
          ..write('avgNewMinutesPerAyah: $avgNewMinutesPerAyah, ')
          ..write('avgReviewMinutesPerAyah: $avgReviewMinutesPerAyah, ')
          ..write(
              'typicalGradeDistributionJson: $typicalGradeDistributionJson, ')
          ..write('effectiveDay: $effectiveDay, ')
          ..write('createdAtDay: $createdAtDay')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AyahTable ayah = $AyahTable(this);
  late final $BookmarkTable bookmark = $BookmarkTable(this);
  late final $NoteTable note = $NoteTable(this);
  late final $MemUnitTable memUnit = $MemUnitTable(this);
  late final $ScheduleStateTable scheduleState = $ScheduleStateTable(this);
  late final $ReviewLogTable reviewLog = $ReviewLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MemProgressTable memProgress = $MemProgressTable(this);
  late final $CalibrationSampleTable calibrationSample =
      $CalibrationSampleTable(this);
  late final $PendingCalibrationUpdateTable pendingCalibrationUpdate =
      $PendingCalibrationUpdateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        ayah,
        bookmark,
        note,
        memUnit,
        scheduleState,
        reviewLog,
        appSettings,
        memProgress,
        calibrationSample,
        pendingCalibrationUpdate
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('mem_unit',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('schedule_state', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('mem_unit',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('review_log', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$AyahTableCreateCompanionBuilder = AyahCompanion Function({
  Value<int> id,
  required int surah,
  required int ayah,
  required String textUthmani,
  Value<int?> pageMadina,
});
typedef $$AyahTableUpdateCompanionBuilder = AyahCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> ayah,
  Value<String> textUthmani,
  Value<int?> pageMadina,
});

class $$AyahTableFilterComposer extends Composer<_$AppDatabase, $AyahTable> {
  $$AyahTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => ColumnFilters(column));
}

class $$AyahTableOrderingComposer extends Composer<_$AppDatabase, $AyahTable> {
  $$AyahTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => ColumnOrderings(column));
}

class $$AyahTableAnnotationComposer
    extends Composer<_$AppDatabase, $AyahTable> {
  $$AyahTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => column);

  GeneratedColumn<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => column);
}

class $$AyahTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AyahTable,
    AyahData,
    $$AyahTableFilterComposer,
    $$AyahTableOrderingComposer,
    $$AyahTableAnnotationComposer,
    $$AyahTableCreateCompanionBuilder,
    $$AyahTableUpdateCompanionBuilder,
    (AyahData, BaseReferences<_$AppDatabase, $AyahTable, AyahData>),
    AyahData,
    PrefetchHooks Function()> {
  $$AyahTableTableManager(_$AppDatabase db, $AyahTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> surah = const Value.absent(),
            Value<int> ayah = const Value.absent(),
            Value<String> textUthmani = const Value.absent(),
            Value<int?> pageMadina = const Value.absent(),
          }) =>
              AyahCompanion(
            id: id,
            surah: surah,
            ayah: ayah,
            textUthmani: textUthmani,
            pageMadina: pageMadina,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int surah,
            required int ayah,
            required String textUthmani,
            Value<int?> pageMadina = const Value.absent(),
          }) =>
              AyahCompanion.insert(
            id: id,
            surah: surah,
            ayah: ayah,
            textUthmani: textUthmani,
            pageMadina: pageMadina,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AyahTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AyahTable,
    AyahData,
    $$AyahTableFilterComposer,
    $$AyahTableOrderingComposer,
    $$AyahTableAnnotationComposer,
    $$AyahTableCreateCompanionBuilder,
    $$AyahTableUpdateCompanionBuilder,
    (AyahData, BaseReferences<_$AppDatabase, $AyahTable, AyahData>),
    AyahData,
    PrefetchHooks Function()>;
typedef $$BookmarkTableCreateCompanionBuilder = BookmarkCompanion Function({
  Value<int> id,
  required int surah,
  required int ayah,
  Value<DateTime> createdAt,
});
typedef $$BookmarkTableUpdateCompanionBuilder = BookmarkCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> ayah,
  Value<DateTime> createdAt,
});

class $$BookmarkTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkTable> {
  $$BookmarkTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BookmarkTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkTable> {
  $$BookmarkTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookmarkTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkTable> {
  $$BookmarkTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarkTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarkTable,
    BookmarkData,
    $$BookmarkTableFilterComposer,
    $$BookmarkTableOrderingComposer,
    $$BookmarkTableAnnotationComposer,
    $$BookmarkTableCreateCompanionBuilder,
    $$BookmarkTableUpdateCompanionBuilder,
    (BookmarkData, BaseReferences<_$AppDatabase, $BookmarkTable, BookmarkData>),
    BookmarkData,
    PrefetchHooks Function()> {
  $$BookmarkTableTableManager(_$AppDatabase db, $BookmarkTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> surah = const Value.absent(),
            Value<int> ayah = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BookmarkCompanion(
            id: id,
            surah: surah,
            ayah: ayah,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int surah,
            required int ayah,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BookmarkCompanion.insert(
            id: id,
            surah: surah,
            ayah: ayah,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarkTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarkTable,
    BookmarkData,
    $$BookmarkTableFilterComposer,
    $$BookmarkTableOrderingComposer,
    $$BookmarkTableAnnotationComposer,
    $$BookmarkTableCreateCompanionBuilder,
    $$BookmarkTableUpdateCompanionBuilder,
    (BookmarkData, BaseReferences<_$AppDatabase, $BookmarkTable, BookmarkData>),
    BookmarkData,
    PrefetchHooks Function()>;
typedef $$NoteTableCreateCompanionBuilder = NoteCompanion Function({
  Value<int> id,
  required int surah,
  required int ayah,
  Value<String?> title,
  required String body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$NoteTableUpdateCompanionBuilder = NoteCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> ayah,
  Value<String?> title,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$NoteTableFilterComposer extends Composer<_$AppDatabase, $NoteTable> {
  $$NoteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NoteTableOrderingComposer extends Composer<_$AppDatabase, $NoteTable> {
  $$NoteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayah => $composableBuilder(
      column: $table.ayah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NoteTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTable> {
  $$NoteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NoteTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NoteTable,
    NoteData,
    $$NoteTableFilterComposer,
    $$NoteTableOrderingComposer,
    $$NoteTableAnnotationComposer,
    $$NoteTableCreateCompanionBuilder,
    $$NoteTableUpdateCompanionBuilder,
    (NoteData, BaseReferences<_$AppDatabase, $NoteTable, NoteData>),
    NoteData,
    PrefetchHooks Function()> {
  $$NoteTableTableManager(_$AppDatabase db, $NoteTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> surah = const Value.absent(),
            Value<int> ayah = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NoteCompanion(
            id: id,
            surah: surah,
            ayah: ayah,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int surah,
            required int ayah,
            Value<String?> title = const Value.absent(),
            required String body,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NoteCompanion.insert(
            id: id,
            surah: surah,
            ayah: ayah,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NoteTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NoteTable,
    NoteData,
    $$NoteTableFilterComposer,
    $$NoteTableOrderingComposer,
    $$NoteTableAnnotationComposer,
    $$NoteTableCreateCompanionBuilder,
    $$NoteTableUpdateCompanionBuilder,
    (NoteData, BaseReferences<_$AppDatabase, $NoteTable, NoteData>),
    NoteData,
    PrefetchHooks Function()>;
typedef $$MemUnitTableCreateCompanionBuilder = MemUnitCompanion Function({
  Value<int> id,
  required String kind,
  Value<int?> pageMadina,
  Value<int?> startSurah,
  Value<int?> startAyah,
  Value<int?> endSurah,
  Value<int?> endAyah,
  Value<int?> startWord,
  Value<int?> endWord,
  Value<String?> title,
  Value<String?> locatorJson,
  required String unitKey,
  required int createdAtDay,
  required int updatedAtDay,
});
typedef $$MemUnitTableUpdateCompanionBuilder = MemUnitCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<int?> pageMadina,
  Value<int?> startSurah,
  Value<int?> startAyah,
  Value<int?> endSurah,
  Value<int?> endAyah,
  Value<int?> startWord,
  Value<int?> endWord,
  Value<String?> title,
  Value<String?> locatorJson,
  Value<String> unitKey,
  Value<int> createdAtDay,
  Value<int> updatedAtDay,
});

final class $$MemUnitTableReferences
    extends BaseReferences<_$AppDatabase, $MemUnitTable, MemUnitData> {
  $$MemUnitTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScheduleStateTable, List<ScheduleStateData>>
      _scheduleStateRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scheduleState,
              aliasName:
                  $_aliasNameGenerator(db.memUnit.id, db.scheduleState.unitId));

  $$ScheduleStateTableProcessedTableManager get scheduleStateRefs {
    final manager = $$ScheduleStateTableTableManager($_db, $_db.scheduleState)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scheduleStateRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReviewLogTable, List<ReviewLogData>>
      _reviewLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reviewLog,
          aliasName: $_aliasNameGenerator(db.memUnit.id, db.reviewLog.unitId));

  $$ReviewLogTableProcessedTableManager get reviewLogRefs {
    final manager = $$ReviewLogTableTableManager($_db, $_db.reviewLog)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MemUnitTableFilterComposer
    extends Composer<_$AppDatabase, $MemUnitTable> {
  $$MemUnitTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startSurah => $composableBuilder(
      column: $table.startSurah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startAyah => $composableBuilder(
      column: $table.startAyah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endSurah => $composableBuilder(
      column: $table.endSurah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endAyah => $composableBuilder(
      column: $table.endAyah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startWord => $composableBuilder(
      column: $table.startWord, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endWord => $composableBuilder(
      column: $table.endWord, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locatorJson => $composableBuilder(
      column: $table.locatorJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitKey => $composableBuilder(
      column: $table.unitKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => ColumnFilters(column));

  Expression<bool> scheduleStateRefs(
      Expression<bool> Function($$ScheduleStateTableFilterComposer f) f) {
    final $$ScheduleStateTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduleState,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduleStateTableFilterComposer(
              $db: $db,
              $table: $db.scheduleState,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reviewLogRefs(
      Expression<bool> Function($$ReviewLogTableFilterComposer f) f) {
    final $$ReviewLogTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLog,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogTableFilterComposer(
              $db: $db,
              $table: $db.reviewLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MemUnitTableOrderingComposer
    extends Composer<_$AppDatabase, $MemUnitTable> {
  $$MemUnitTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startSurah => $composableBuilder(
      column: $table.startSurah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startAyah => $composableBuilder(
      column: $table.startAyah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endSurah => $composableBuilder(
      column: $table.endSurah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endAyah => $composableBuilder(
      column: $table.endAyah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startWord => $composableBuilder(
      column: $table.startWord, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endWord => $composableBuilder(
      column: $table.endWord, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locatorJson => $composableBuilder(
      column: $table.locatorJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitKey => $composableBuilder(
      column: $table.unitKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay,
      builder: (column) => ColumnOrderings(column));
}

class $$MemUnitTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemUnitTable> {
  $$MemUnitTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get pageMadina => $composableBuilder(
      column: $table.pageMadina, builder: (column) => column);

  GeneratedColumn<int> get startSurah => $composableBuilder(
      column: $table.startSurah, builder: (column) => column);

  GeneratedColumn<int> get startAyah =>
      $composableBuilder(column: $table.startAyah, builder: (column) => column);

  GeneratedColumn<int> get endSurah =>
      $composableBuilder(column: $table.endSurah, builder: (column) => column);

  GeneratedColumn<int> get endAyah =>
      $composableBuilder(column: $table.endAyah, builder: (column) => column);

  GeneratedColumn<int> get startWord =>
      $composableBuilder(column: $table.startWord, builder: (column) => column);

  GeneratedColumn<int> get endWord =>
      $composableBuilder(column: $table.endWord, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get locatorJson => $composableBuilder(
      column: $table.locatorJson, builder: (column) => column);

  GeneratedColumn<String> get unitKey =>
      $composableBuilder(column: $table.unitKey, builder: (column) => column);

  GeneratedColumn<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => column);

  GeneratedColumn<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => column);

  Expression<T> scheduleStateRefs<T extends Object>(
      Expression<T> Function($$ScheduleStateTableAnnotationComposer a) f) {
    final $$ScheduleStateTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scheduleState,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScheduleStateTableAnnotationComposer(
              $db: $db,
              $table: $db.scheduleState,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reviewLogRefs<T extends Object>(
      Expression<T> Function($$ReviewLogTableAnnotationComposer a) f) {
    final $$ReviewLogTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLog,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MemUnitTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemUnitTable,
    MemUnitData,
    $$MemUnitTableFilterComposer,
    $$MemUnitTableOrderingComposer,
    $$MemUnitTableAnnotationComposer,
    $$MemUnitTableCreateCompanionBuilder,
    $$MemUnitTableUpdateCompanionBuilder,
    (MemUnitData, $$MemUnitTableReferences),
    MemUnitData,
    PrefetchHooks Function({bool scheduleStateRefs, bool reviewLogRefs})> {
  $$MemUnitTableTableManager(_$AppDatabase db, $MemUnitTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemUnitTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemUnitTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemUnitTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int?> pageMadina = const Value.absent(),
            Value<int?> startSurah = const Value.absent(),
            Value<int?> startAyah = const Value.absent(),
            Value<int?> endSurah = const Value.absent(),
            Value<int?> endAyah = const Value.absent(),
            Value<int?> startWord = const Value.absent(),
            Value<int?> endWord = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> locatorJson = const Value.absent(),
            Value<String> unitKey = const Value.absent(),
            Value<int> createdAtDay = const Value.absent(),
            Value<int> updatedAtDay = const Value.absent(),
          }) =>
              MemUnitCompanion(
            id: id,
            kind: kind,
            pageMadina: pageMadina,
            startSurah: startSurah,
            startAyah: startAyah,
            endSurah: endSurah,
            endAyah: endAyah,
            startWord: startWord,
            endWord: endWord,
            title: title,
            locatorJson: locatorJson,
            unitKey: unitKey,
            createdAtDay: createdAtDay,
            updatedAtDay: updatedAtDay,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String kind,
            Value<int?> pageMadina = const Value.absent(),
            Value<int?> startSurah = const Value.absent(),
            Value<int?> startAyah = const Value.absent(),
            Value<int?> endSurah = const Value.absent(),
            Value<int?> endAyah = const Value.absent(),
            Value<int?> startWord = const Value.absent(),
            Value<int?> endWord = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> locatorJson = const Value.absent(),
            required String unitKey,
            required int createdAtDay,
            required int updatedAtDay,
          }) =>
              MemUnitCompanion.insert(
            id: id,
            kind: kind,
            pageMadina: pageMadina,
            startSurah: startSurah,
            startAyah: startAyah,
            endSurah: endSurah,
            endAyah: endAyah,
            startWord: startWord,
            endWord: endWord,
            title: title,
            locatorJson: locatorJson,
            unitKey: unitKey,
            createdAtDay: createdAtDay,
            updatedAtDay: updatedAtDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MemUnitTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {scheduleStateRefs = false, reviewLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scheduleStateRefs) db.scheduleState,
                if (reviewLogRefs) db.reviewLog
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scheduleStateRefs)
                    await $_getPrefetchedData<MemUnitData, $MemUnitTable,
                            ScheduleStateData>(
                        currentTable: table,
                        referencedTable: $$MemUnitTableReferences
                            ._scheduleStateRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MemUnitTableReferences(db, table, p0)
                                .scheduleStateRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items),
                  if (reviewLogRefs)
                    await $_getPrefetchedData<MemUnitData, $MemUnitTable,
                            ReviewLogData>(
                        currentTable: table,
                        referencedTable:
                            $$MemUnitTableReferences._reviewLogRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MemUnitTableReferences(db, table, p0)
                                .reviewLogRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MemUnitTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemUnitTable,
    MemUnitData,
    $$MemUnitTableFilterComposer,
    $$MemUnitTableOrderingComposer,
    $$MemUnitTableAnnotationComposer,
    $$MemUnitTableCreateCompanionBuilder,
    $$MemUnitTableUpdateCompanionBuilder,
    (MemUnitData, $$MemUnitTableReferences),
    MemUnitData,
    PrefetchHooks Function({bool scheduleStateRefs, bool reviewLogRefs})>;
typedef $$ScheduleStateTableCreateCompanionBuilder = ScheduleStateCompanion
    Function({
  Value<int> unitId,
  required double ef,
  required int reps,
  required int intervalDays,
  required int dueDay,
  Value<int?> lastReviewDay,
  Value<int?> lastGradeQ,
  required int lapseCount,
  Value<int> isSuspended,
  Value<int?> suspendedAtDay,
});
typedef $$ScheduleStateTableUpdateCompanionBuilder = ScheduleStateCompanion
    Function({
  Value<int> unitId,
  Value<double> ef,
  Value<int> reps,
  Value<int> intervalDays,
  Value<int> dueDay,
  Value<int?> lastReviewDay,
  Value<int?> lastGradeQ,
  Value<int> lapseCount,
  Value<int> isSuspended,
  Value<int?> suspendedAtDay,
});

final class $$ScheduleStateTableReferences extends BaseReferences<_$AppDatabase,
    $ScheduleStateTable, ScheduleStateData> {
  $$ScheduleStateTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $MemUnitTable _unitIdTable(_$AppDatabase db) => db.memUnit.createAlias(
      $_aliasNameGenerator(db.scheduleState.unitId, db.memUnit.id));

  $$MemUnitTableProcessedTableManager get unitId {
    final $_column = $_itemColumn<int>('unit_id')!;

    final manager = $$MemUnitTableTableManager($_db, $_db.memUnit)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ScheduleStateTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleStateTable> {
  $$ScheduleStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get ef => $composableBuilder(
      column: $table.ef, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReviewDay => $composableBuilder(
      column: $table.lastReviewDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastGradeQ => $composableBuilder(
      column: $table.lastGradeQ, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapseCount => $composableBuilder(
      column: $table.lapseCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get suspendedAtDay => $composableBuilder(
      column: $table.suspendedAtDay,
      builder: (column) => ColumnFilters(column));

  $$MemUnitTableFilterComposer get unitId {
    final $$MemUnitTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableFilterComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduleStateTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleStateTable> {
  $$ScheduleStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get ef => $composableBuilder(
      column: $table.ef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReviewDay => $composableBuilder(
      column: $table.lastReviewDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastGradeQ => $composableBuilder(
      column: $table.lastGradeQ, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapseCount => $composableBuilder(
      column: $table.lapseCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get suspendedAtDay => $composableBuilder(
      column: $table.suspendedAtDay,
      builder: (column) => ColumnOrderings(column));

  $$MemUnitTableOrderingComposer get unitId {
    final $$MemUnitTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableOrderingComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduleStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleStateTable> {
  $$ScheduleStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get ef =>
      $composableBuilder(column: $table.ef, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get lastReviewDay => $composableBuilder(
      column: $table.lastReviewDay, builder: (column) => column);

  GeneratedColumn<int> get lastGradeQ => $composableBuilder(
      column: $table.lastGradeQ, builder: (column) => column);

  GeneratedColumn<int> get lapseCount => $composableBuilder(
      column: $table.lapseCount, builder: (column) => column);

  GeneratedColumn<int> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => column);

  GeneratedColumn<int> get suspendedAtDay => $composableBuilder(
      column: $table.suspendedAtDay, builder: (column) => column);

  $$MemUnitTableAnnotationComposer get unitId {
    final $$MemUnitTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableAnnotationComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduleStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduleStateTable,
    ScheduleStateData,
    $$ScheduleStateTableFilterComposer,
    $$ScheduleStateTableOrderingComposer,
    $$ScheduleStateTableAnnotationComposer,
    $$ScheduleStateTableCreateCompanionBuilder,
    $$ScheduleStateTableUpdateCompanionBuilder,
    (ScheduleStateData, $$ScheduleStateTableReferences),
    ScheduleStateData,
    PrefetchHooks Function({bool unitId})> {
  $$ScheduleStateTableTableManager(_$AppDatabase db, $ScheduleStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> unitId = const Value.absent(),
            Value<double> ef = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<int> dueDay = const Value.absent(),
            Value<int?> lastReviewDay = const Value.absent(),
            Value<int?> lastGradeQ = const Value.absent(),
            Value<int> lapseCount = const Value.absent(),
            Value<int> isSuspended = const Value.absent(),
            Value<int?> suspendedAtDay = const Value.absent(),
          }) =>
              ScheduleStateCompanion(
            unitId: unitId,
            ef: ef,
            reps: reps,
            intervalDays: intervalDays,
            dueDay: dueDay,
            lastReviewDay: lastReviewDay,
            lastGradeQ: lastGradeQ,
            lapseCount: lapseCount,
            isSuspended: isSuspended,
            suspendedAtDay: suspendedAtDay,
          ),
          createCompanionCallback: ({
            Value<int> unitId = const Value.absent(),
            required double ef,
            required int reps,
            required int intervalDays,
            required int dueDay,
            Value<int?> lastReviewDay = const Value.absent(),
            Value<int?> lastGradeQ = const Value.absent(),
            required int lapseCount,
            Value<int> isSuspended = const Value.absent(),
            Value<int?> suspendedAtDay = const Value.absent(),
          }) =>
              ScheduleStateCompanion.insert(
            unitId: unitId,
            ef: ef,
            reps: reps,
            intervalDays: intervalDays,
            dueDay: dueDay,
            lastReviewDay: lastReviewDay,
            lastGradeQ: lastGradeQ,
            lapseCount: lapseCount,
            isSuspended: isSuspended,
            suspendedAtDay: suspendedAtDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ScheduleStateTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ScheduleStateTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$ScheduleStateTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ScheduleStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScheduleStateTable,
    ScheduleStateData,
    $$ScheduleStateTableFilterComposer,
    $$ScheduleStateTableOrderingComposer,
    $$ScheduleStateTableAnnotationComposer,
    $$ScheduleStateTableCreateCompanionBuilder,
    $$ScheduleStateTableUpdateCompanionBuilder,
    (ScheduleStateData, $$ScheduleStateTableReferences),
    ScheduleStateData,
    PrefetchHooks Function({bool unitId})>;
typedef $$ReviewLogTableCreateCompanionBuilder = ReviewLogCompanion Function({
  Value<int> id,
  required int unitId,
  required int tsDay,
  Value<int?> tsSeconds,
  required int gradeQ,
  Value<int?> durationSeconds,
  Value<int?> mistakesCount,
});
typedef $$ReviewLogTableUpdateCompanionBuilder = ReviewLogCompanion Function({
  Value<int> id,
  Value<int> unitId,
  Value<int> tsDay,
  Value<int?> tsSeconds,
  Value<int> gradeQ,
  Value<int?> durationSeconds,
  Value<int?> mistakesCount,
});

final class $$ReviewLogTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogTable, ReviewLogData> {
  $$ReviewLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MemUnitTable _unitIdTable(_$AppDatabase db) => db.memUnit
      .createAlias($_aliasNameGenerator(db.reviewLog.unitId, db.memUnit.id));

  $$MemUnitTableProcessedTableManager get unitId {
    final $_column = $_itemColumn<int>('unit_id')!;

    final manager = $$MemUnitTableTableManager($_db, $_db.memUnit)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewLogTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tsDay => $composableBuilder(
      column: $table.tsDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tsSeconds => $composableBuilder(
      column: $table.tsSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gradeQ => $composableBuilder(
      column: $table.gradeQ, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mistakesCount => $composableBuilder(
      column: $table.mistakesCount, builder: (column) => ColumnFilters(column));

  $$MemUnitTableFilterComposer get unitId {
    final $$MemUnitTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableFilterComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tsDay => $composableBuilder(
      column: $table.tsDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tsSeconds => $composableBuilder(
      column: $table.tsSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gradeQ => $composableBuilder(
      column: $table.gradeQ, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mistakesCount => $composableBuilder(
      column: $table.mistakesCount,
      builder: (column) => ColumnOrderings(column));

  $$MemUnitTableOrderingComposer get unitId {
    final $$MemUnitTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableOrderingComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tsDay =>
      $composableBuilder(column: $table.tsDay, builder: (column) => column);

  GeneratedColumn<int> get tsSeconds =>
      $composableBuilder(column: $table.tsSeconds, builder: (column) => column);

  GeneratedColumn<int> get gradeQ =>
      $composableBuilder(column: $table.gradeQ, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get mistakesCount => $composableBuilder(
      column: $table.mistakesCount, builder: (column) => column);

  $$MemUnitTableAnnotationComposer get unitId {
    final $$MemUnitTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.memUnit,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MemUnitTableAnnotationComposer(
              $db: $db,
              $table: $db.memUnit,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewLogTable,
    ReviewLogData,
    $$ReviewLogTableFilterComposer,
    $$ReviewLogTableOrderingComposer,
    $$ReviewLogTableAnnotationComposer,
    $$ReviewLogTableCreateCompanionBuilder,
    $$ReviewLogTableUpdateCompanionBuilder,
    (ReviewLogData, $$ReviewLogTableReferences),
    ReviewLogData,
    PrefetchHooks Function({bool unitId})> {
  $$ReviewLogTableTableManager(_$AppDatabase db, $ReviewLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> unitId = const Value.absent(),
            Value<int> tsDay = const Value.absent(),
            Value<int?> tsSeconds = const Value.absent(),
            Value<int> gradeQ = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
            Value<int?> mistakesCount = const Value.absent(),
          }) =>
              ReviewLogCompanion(
            id: id,
            unitId: unitId,
            tsDay: tsDay,
            tsSeconds: tsSeconds,
            gradeQ: gradeQ,
            durationSeconds: durationSeconds,
            mistakesCount: mistakesCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int unitId,
            required int tsDay,
            Value<int?> tsSeconds = const Value.absent(),
            required int gradeQ,
            Value<int?> durationSeconds = const Value.absent(),
            Value<int?> mistakesCount = const Value.absent(),
          }) =>
              ReviewLogCompanion.insert(
            id: id,
            unitId: unitId,
            tsDay: tsDay,
            tsSeconds: tsSeconds,
            gradeQ: gradeQ,
            durationSeconds: durationSeconds,
            mistakesCount: mistakesCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewLogTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ReviewLogTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$ReviewLogTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewLogTable,
    ReviewLogData,
    $$ReviewLogTableFilterComposer,
    $$ReviewLogTableOrderingComposer,
    $$ReviewLogTableAnnotationComposer,
    $$ReviewLogTableCreateCompanionBuilder,
    $$ReviewLogTableUpdateCompanionBuilder,
    (ReviewLogData, $$ReviewLogTableReferences),
    ReviewLogData,
    PrefetchHooks Function({bool unitId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  required String profile,
  required int forceRevisionOnly,
  required int dailyMinutesDefault,
  Value<String?> minutesByWeekdayJson,
  required int maxNewPagesPerDay,
  required int maxNewUnitsPerDay,
  required double avgNewMinutesPerAyah,
  required double avgReviewMinutesPerAyah,
  Value<int> requirePageMetadata,
  Value<String?> typicalGradeDistributionJson,
  required int updatedAtDay,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> profile,
  Value<int> forceRevisionOnly,
  Value<int> dailyMinutesDefault,
  Value<String?> minutesByWeekdayJson,
  Value<int> maxNewPagesPerDay,
  Value<int> maxNewUnitsPerDay,
  Value<double> avgNewMinutesPerAyah,
  Value<double> avgReviewMinutesPerAyah,
  Value<int> requirePageMetadata,
  Value<String?> typicalGradeDistributionJson,
  Value<int> updatedAtDay,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profile => $composableBuilder(
      column: $table.profile, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get forceRevisionOnly => $composableBuilder(
      column: $table.forceRevisionOnly,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyMinutesDefault => $composableBuilder(
      column: $table.dailyMinutesDefault,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get minutesByWeekdayJson => $composableBuilder(
      column: $table.minutesByWeekdayJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxNewPagesPerDay => $composableBuilder(
      column: $table.maxNewPagesPerDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxNewUnitsPerDay => $composableBuilder(
      column: $table.maxNewUnitsPerDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requirePageMetadata => $composableBuilder(
      column: $table.requirePageMetadata,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typicalGradeDistributionJson => $composableBuilder(
      column: $table.typicalGradeDistributionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profile => $composableBuilder(
      column: $table.profile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get forceRevisionOnly => $composableBuilder(
      column: $table.forceRevisionOnly,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyMinutesDefault => $composableBuilder(
      column: $table.dailyMinutesDefault,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get minutesByWeekdayJson => $composableBuilder(
      column: $table.minutesByWeekdayJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxNewPagesPerDay => $composableBuilder(
      column: $table.maxNewPagesPerDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxNewUnitsPerDay => $composableBuilder(
      column: $table.maxNewUnitsPerDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requirePageMetadata => $composableBuilder(
      column: $table.requirePageMetadata,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typicalGradeDistributionJson =>
      $composableBuilder(
          column: $table.typicalGradeDistributionJson,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay,
      builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profile =>
      $composableBuilder(column: $table.profile, builder: (column) => column);

  GeneratedColumn<int> get forceRevisionOnly => $composableBuilder(
      column: $table.forceRevisionOnly, builder: (column) => column);

  GeneratedColumn<int> get dailyMinutesDefault => $composableBuilder(
      column: $table.dailyMinutesDefault, builder: (column) => column);

  GeneratedColumn<String> get minutesByWeekdayJson => $composableBuilder(
      column: $table.minutesByWeekdayJson, builder: (column) => column);

  GeneratedColumn<int> get maxNewPagesPerDay => $composableBuilder(
      column: $table.maxNewPagesPerDay, builder: (column) => column);

  GeneratedColumn<int> get maxNewUnitsPerDay => $composableBuilder(
      column: $table.maxNewUnitsPerDay, builder: (column) => column);

  GeneratedColumn<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah, builder: (column) => column);

  GeneratedColumn<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah, builder: (column) => column);

  GeneratedColumn<int> get requirePageMetadata => $composableBuilder(
      column: $table.requirePageMetadata, builder: (column) => column);

  GeneratedColumn<String> get typicalGradeDistributionJson =>
      $composableBuilder(
          column: $table.typicalGradeDistributionJson,
          builder: (column) => column);

  GeneratedColumn<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> profile = const Value.absent(),
            Value<int> forceRevisionOnly = const Value.absent(),
            Value<int> dailyMinutesDefault = const Value.absent(),
            Value<String?> minutesByWeekdayJson = const Value.absent(),
            Value<int> maxNewPagesPerDay = const Value.absent(),
            Value<int> maxNewUnitsPerDay = const Value.absent(),
            Value<double> avgNewMinutesPerAyah = const Value.absent(),
            Value<double> avgReviewMinutesPerAyah = const Value.absent(),
            Value<int> requirePageMetadata = const Value.absent(),
            Value<String?> typicalGradeDistributionJson = const Value.absent(),
            Value<int> updatedAtDay = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            profile: profile,
            forceRevisionOnly: forceRevisionOnly,
            dailyMinutesDefault: dailyMinutesDefault,
            minutesByWeekdayJson: minutesByWeekdayJson,
            maxNewPagesPerDay: maxNewPagesPerDay,
            maxNewUnitsPerDay: maxNewUnitsPerDay,
            avgNewMinutesPerAyah: avgNewMinutesPerAyah,
            avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
            requirePageMetadata: requirePageMetadata,
            typicalGradeDistributionJson: typicalGradeDistributionJson,
            updatedAtDay: updatedAtDay,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String profile,
            required int forceRevisionOnly,
            required int dailyMinutesDefault,
            Value<String?> minutesByWeekdayJson = const Value.absent(),
            required int maxNewPagesPerDay,
            required int maxNewUnitsPerDay,
            required double avgNewMinutesPerAyah,
            required double avgReviewMinutesPerAyah,
            Value<int> requirePageMetadata = const Value.absent(),
            Value<String?> typicalGradeDistributionJson = const Value.absent(),
            required int updatedAtDay,
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            profile: profile,
            forceRevisionOnly: forceRevisionOnly,
            dailyMinutesDefault: dailyMinutesDefault,
            minutesByWeekdayJson: minutesByWeekdayJson,
            maxNewPagesPerDay: maxNewPagesPerDay,
            maxNewUnitsPerDay: maxNewUnitsPerDay,
            avgNewMinutesPerAyah: avgNewMinutesPerAyah,
            avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
            requirePageMetadata: requirePageMetadata,
            typicalGradeDistributionJson: typicalGradeDistributionJson,
            updatedAtDay: updatedAtDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$MemProgressTableCreateCompanionBuilder = MemProgressCompanion
    Function({
  Value<int> id,
  required int nextSurah,
  required int nextAyah,
  required int updatedAtDay,
});
typedef $$MemProgressTableUpdateCompanionBuilder = MemProgressCompanion
    Function({
  Value<int> id,
  Value<int> nextSurah,
  Value<int> nextAyah,
  Value<int> updatedAtDay,
});

class $$MemProgressTableFilterComposer
    extends Composer<_$AppDatabase, $MemProgressTable> {
  $$MemProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextSurah => $composableBuilder(
      column: $table.nextSurah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextAyah => $composableBuilder(
      column: $table.nextAyah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => ColumnFilters(column));
}

class $$MemProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $MemProgressTable> {
  $$MemProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextSurah => $composableBuilder(
      column: $table.nextSurah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextAyah => $composableBuilder(
      column: $table.nextAyah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay,
      builder: (column) => ColumnOrderings(column));
}

class $$MemProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemProgressTable> {
  $$MemProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nextSurah =>
      $composableBuilder(column: $table.nextSurah, builder: (column) => column);

  GeneratedColumn<int> get nextAyah =>
      $composableBuilder(column: $table.nextAyah, builder: (column) => column);

  GeneratedColumn<int> get updatedAtDay => $composableBuilder(
      column: $table.updatedAtDay, builder: (column) => column);
}

class $$MemProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemProgressTable,
    MemProgressData,
    $$MemProgressTableFilterComposer,
    $$MemProgressTableOrderingComposer,
    $$MemProgressTableAnnotationComposer,
    $$MemProgressTableCreateCompanionBuilder,
    $$MemProgressTableUpdateCompanionBuilder,
    (
      MemProgressData,
      BaseReferences<_$AppDatabase, $MemProgressTable, MemProgressData>
    ),
    MemProgressData,
    PrefetchHooks Function()> {
  $$MemProgressTableTableManager(_$AppDatabase db, $MemProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> nextSurah = const Value.absent(),
            Value<int> nextAyah = const Value.absent(),
            Value<int> updatedAtDay = const Value.absent(),
          }) =>
              MemProgressCompanion(
            id: id,
            nextSurah: nextSurah,
            nextAyah: nextAyah,
            updatedAtDay: updatedAtDay,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int nextSurah,
            required int nextAyah,
            required int updatedAtDay,
          }) =>
              MemProgressCompanion.insert(
            id: id,
            nextSurah: nextSurah,
            nextAyah: nextAyah,
            updatedAtDay: updatedAtDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemProgressTable,
    MemProgressData,
    $$MemProgressTableFilterComposer,
    $$MemProgressTableOrderingComposer,
    $$MemProgressTableAnnotationComposer,
    $$MemProgressTableCreateCompanionBuilder,
    $$MemProgressTableUpdateCompanionBuilder,
    (
      MemProgressData,
      BaseReferences<_$AppDatabase, $MemProgressTable, MemProgressData>
    ),
    MemProgressData,
    PrefetchHooks Function()>;
typedef $$CalibrationSampleTableCreateCompanionBuilder
    = CalibrationSampleCompanion Function({
  Value<int> id,
  required String sampleKind,
  required int durationSeconds,
  required int ayahCount,
  required int createdAtDay,
  Value<int?> createdAtSeconds,
});
typedef $$CalibrationSampleTableUpdateCompanionBuilder
    = CalibrationSampleCompanion Function({
  Value<int> id,
  Value<String> sampleKind,
  Value<int> durationSeconds,
  Value<int> ayahCount,
  Value<int> createdAtDay,
  Value<int?> createdAtSeconds,
});

class $$CalibrationSampleTableFilterComposer
    extends Composer<_$AppDatabase, $CalibrationSampleTable> {
  $$CalibrationSampleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sampleKind => $composableBuilder(
      column: $table.sampleKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahCount => $composableBuilder(
      column: $table.ayahCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtSeconds => $composableBuilder(
      column: $table.createdAtSeconds,
      builder: (column) => ColumnFilters(column));
}

class $$CalibrationSampleTableOrderingComposer
    extends Composer<_$AppDatabase, $CalibrationSampleTable> {
  $$CalibrationSampleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sampleKind => $composableBuilder(
      column: $table.sampleKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahCount => $composableBuilder(
      column: $table.ayahCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtSeconds => $composableBuilder(
      column: $table.createdAtSeconds,
      builder: (column) => ColumnOrderings(column));
}

class $$CalibrationSampleTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalibrationSampleTable> {
  $$CalibrationSampleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sampleKind => $composableBuilder(
      column: $table.sampleKind, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => column);

  GeneratedColumn<int> get createdAtSeconds => $composableBuilder(
      column: $table.createdAtSeconds, builder: (column) => column);
}

class $$CalibrationSampleTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalibrationSampleTable,
    CalibrationSampleData,
    $$CalibrationSampleTableFilterComposer,
    $$CalibrationSampleTableOrderingComposer,
    $$CalibrationSampleTableAnnotationComposer,
    $$CalibrationSampleTableCreateCompanionBuilder,
    $$CalibrationSampleTableUpdateCompanionBuilder,
    (
      CalibrationSampleData,
      BaseReferences<_$AppDatabase, $CalibrationSampleTable,
          CalibrationSampleData>
    ),
    CalibrationSampleData,
    PrefetchHooks Function()> {
  $$CalibrationSampleTableTableManager(
      _$AppDatabase db, $CalibrationSampleTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalibrationSampleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalibrationSampleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalibrationSampleTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sampleKind = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> ayahCount = const Value.absent(),
            Value<int> createdAtDay = const Value.absent(),
            Value<int?> createdAtSeconds = const Value.absent(),
          }) =>
              CalibrationSampleCompanion(
            id: id,
            sampleKind: sampleKind,
            durationSeconds: durationSeconds,
            ayahCount: ayahCount,
            createdAtDay: createdAtDay,
            createdAtSeconds: createdAtSeconds,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sampleKind,
            required int durationSeconds,
            required int ayahCount,
            required int createdAtDay,
            Value<int?> createdAtSeconds = const Value.absent(),
          }) =>
              CalibrationSampleCompanion.insert(
            id: id,
            sampleKind: sampleKind,
            durationSeconds: durationSeconds,
            ayahCount: ayahCount,
            createdAtDay: createdAtDay,
            createdAtSeconds: createdAtSeconds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CalibrationSampleTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalibrationSampleTable,
    CalibrationSampleData,
    $$CalibrationSampleTableFilterComposer,
    $$CalibrationSampleTableOrderingComposer,
    $$CalibrationSampleTableAnnotationComposer,
    $$CalibrationSampleTableCreateCompanionBuilder,
    $$CalibrationSampleTableUpdateCompanionBuilder,
    (
      CalibrationSampleData,
      BaseReferences<_$AppDatabase, $CalibrationSampleTable,
          CalibrationSampleData>
    ),
    CalibrationSampleData,
    PrefetchHooks Function()>;
typedef $$PendingCalibrationUpdateTableCreateCompanionBuilder
    = PendingCalibrationUpdateCompanion Function({
  Value<int> id,
  Value<double?> avgNewMinutesPerAyah,
  Value<double?> avgReviewMinutesPerAyah,
  Value<String?> typicalGradeDistributionJson,
  required int effectiveDay,
  required int createdAtDay,
});
typedef $$PendingCalibrationUpdateTableUpdateCompanionBuilder
    = PendingCalibrationUpdateCompanion Function({
  Value<int> id,
  Value<double?> avgNewMinutesPerAyah,
  Value<double?> avgReviewMinutesPerAyah,
  Value<String?> typicalGradeDistributionJson,
  Value<int> effectiveDay,
  Value<int> createdAtDay,
});

class $$PendingCalibrationUpdateTableFilterComposer
    extends Composer<_$AppDatabase, $PendingCalibrationUpdateTable> {
  $$PendingCalibrationUpdateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typicalGradeDistributionJson => $composableBuilder(
      column: $table.typicalGradeDistributionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get effectiveDay => $composableBuilder(
      column: $table.effectiveDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => ColumnFilters(column));
}

class $$PendingCalibrationUpdateTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingCalibrationUpdateTable> {
  $$PendingCalibrationUpdateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typicalGradeDistributionJson =>
      $composableBuilder(
          column: $table.typicalGradeDistributionJson,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get effectiveDay => $composableBuilder(
      column: $table.effectiveDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay,
      builder: (column) => ColumnOrderings(column));
}

class $$PendingCalibrationUpdateTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingCalibrationUpdateTable> {
  $$PendingCalibrationUpdateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get avgNewMinutesPerAyah => $composableBuilder(
      column: $table.avgNewMinutesPerAyah, builder: (column) => column);

  GeneratedColumn<double> get avgReviewMinutesPerAyah => $composableBuilder(
      column: $table.avgReviewMinutesPerAyah, builder: (column) => column);

  GeneratedColumn<String> get typicalGradeDistributionJson =>
      $composableBuilder(
          column: $table.typicalGradeDistributionJson,
          builder: (column) => column);

  GeneratedColumn<int> get effectiveDay => $composableBuilder(
      column: $table.effectiveDay, builder: (column) => column);

  GeneratedColumn<int> get createdAtDay => $composableBuilder(
      column: $table.createdAtDay, builder: (column) => column);
}

class $$PendingCalibrationUpdateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingCalibrationUpdateTable,
    PendingCalibrationUpdateData,
    $$PendingCalibrationUpdateTableFilterComposer,
    $$PendingCalibrationUpdateTableOrderingComposer,
    $$PendingCalibrationUpdateTableAnnotationComposer,
    $$PendingCalibrationUpdateTableCreateCompanionBuilder,
    $$PendingCalibrationUpdateTableUpdateCompanionBuilder,
    (
      PendingCalibrationUpdateData,
      BaseReferences<_$AppDatabase, $PendingCalibrationUpdateTable,
          PendingCalibrationUpdateData>
    ),
    PendingCalibrationUpdateData,
    PrefetchHooks Function()> {
  $$PendingCalibrationUpdateTableTableManager(
      _$AppDatabase db, $PendingCalibrationUpdateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingCalibrationUpdateTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingCalibrationUpdateTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingCalibrationUpdateTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double?> avgNewMinutesPerAyah = const Value.absent(),
            Value<double?> avgReviewMinutesPerAyah = const Value.absent(),
            Value<String?> typicalGradeDistributionJson = const Value.absent(),
            Value<int> effectiveDay = const Value.absent(),
            Value<int> createdAtDay = const Value.absent(),
          }) =>
              PendingCalibrationUpdateCompanion(
            id: id,
            avgNewMinutesPerAyah: avgNewMinutesPerAyah,
            avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
            typicalGradeDistributionJson: typicalGradeDistributionJson,
            effectiveDay: effectiveDay,
            createdAtDay: createdAtDay,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double?> avgNewMinutesPerAyah = const Value.absent(),
            Value<double?> avgReviewMinutesPerAyah = const Value.absent(),
            Value<String?> typicalGradeDistributionJson = const Value.absent(),
            required int effectiveDay,
            required int createdAtDay,
          }) =>
              PendingCalibrationUpdateCompanion.insert(
            id: id,
            avgNewMinutesPerAyah: avgNewMinutesPerAyah,
            avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
            typicalGradeDistributionJson: typicalGradeDistributionJson,
            effectiveDay: effectiveDay,
            createdAtDay: createdAtDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingCalibrationUpdateTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PendingCalibrationUpdateTable,
        PendingCalibrationUpdateData,
        $$PendingCalibrationUpdateTableFilterComposer,
        $$PendingCalibrationUpdateTableOrderingComposer,
        $$PendingCalibrationUpdateTableAnnotationComposer,
        $$PendingCalibrationUpdateTableCreateCompanionBuilder,
        $$PendingCalibrationUpdateTableUpdateCompanionBuilder,
        (
          PendingCalibrationUpdateData,
          BaseReferences<_$AppDatabase, $PendingCalibrationUpdateTable,
              PendingCalibrationUpdateData>
        ),
        PendingCalibrationUpdateData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AyahTableTableManager get ayah => $$AyahTableTableManager(_db, _db.ayah);
  $$BookmarkTableTableManager get bookmark =>
      $$BookmarkTableTableManager(_db, _db.bookmark);
  $$NoteTableTableManager get note => $$NoteTableTableManager(_db, _db.note);
  $$MemUnitTableTableManager get memUnit =>
      $$MemUnitTableTableManager(_db, _db.memUnit);
  $$ScheduleStateTableTableManager get scheduleState =>
      $$ScheduleStateTableTableManager(_db, _db.scheduleState);
  $$ReviewLogTableTableManager get reviewLog =>
      $$ReviewLogTableTableManager(_db, _db.reviewLog);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MemProgressTableTableManager get memProgress =>
      $$MemProgressTableTableManager(_db, _db.memProgress);
  $$CalibrationSampleTableTableManager get calibrationSample =>
      $$CalibrationSampleTableTableManager(_db, _db.calibrationSample);
  $$PendingCalibrationUpdateTableTableManager get pendingCalibrationUpdate =>
      $$PendingCalibrationUpdateTableTableManager(
          _db, _db.pendingCalibrationUpdate);
}
