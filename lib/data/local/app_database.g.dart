// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Pending'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown'),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _verificationQuestionMeta =
      const VerificationMeta('verificationQuestion');
  @override
  late final GeneratedColumn<String> verificationQuestion =
      GeneratedColumn<String>(
        'verification_question',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendingCreateMeta = const VerificationMeta(
    'pendingCreate',
  );
  @override
  late final GeneratedColumn<bool> pendingCreate = GeneratedColumn<bool>(
    'pending_create',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_create" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingUpdateMeta = const VerificationMeta(
    'pendingUpdate',
  );
  @override
  late final GeneratedColumn<bool> pendingUpdate = GeneratedColumn<bool>(
    'pending_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_update" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingDeleteMeta = const VerificationMeta(
    'pendingDelete',
  );
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
    'pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    category,
    location,
    date,
    status,
    imageUrl,
    localImagePath,
    username,
    ownerId,
    verificationQuestion,
    createdAt,
    updatedAt,
    synced,
    pendingCreate,
    pendingUpdate,
    pendingDelete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('verification_question')) {
      context.handle(
        _verificationQuestionMeta,
        verificationQuestion.isAcceptableOrUnknown(
          data['verification_question']!,
          _verificationQuestionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('pending_create')) {
      context.handle(
        _pendingCreateMeta,
        pendingCreate.isAcceptableOrUnknown(
          data['pending_create']!,
          _pendingCreateMeta,
        ),
      );
    }
    if (data.containsKey('pending_update')) {
      context.handle(
        _pendingUpdateMeta,
        pendingUpdate.isAcceptableOrUnknown(
          data['pending_update']!,
          _pendingUpdateMeta,
        ),
      );
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
        _pendingDeleteMeta,
        pendingDelete.isAcceptableOrUnknown(
          data['pending_delete']!,
          _pendingDeleteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      verificationQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_question'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      pendingCreate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_create'],
      )!,
      pendingUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_update'],
      )!,
      pendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_delete'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  /// Matches the Firestore document id. Firestore can generate this id
  /// locally (no network needed), so offline-created items keep the same id
  /// end-to-end and never need to be "renamed" after syncing.
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String date;
  final String status;
  final String imageUrl;

  /// Local file path for an image that hasn't been uploaded to Cloudinary
  /// yet. Null once [imageUrl] is populated.
  final String? localImagePath;
  final String username;
  final String ownerId;
  final String? verificationQuestion;
  final DateTime? createdAt;

  /// Last time this row changed locally. Used for last-write-wins conflict
  /// resolution against the server's `createdAt`/incoming snapshot data.
  final DateTime updatedAt;
  final bool synced;
  final bool pendingCreate;
  final bool pendingUpdate;
  final bool pendingDelete;
  const ItemRow({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.status,
    required this.imageUrl,
    this.localImagePath,
    required this.username,
    required this.ownerId,
    this.verificationQuestion,
    this.createdAt,
    required this.updatedAt,
    required this.synced,
    required this.pendingCreate,
    required this.pendingUpdate,
    required this.pendingDelete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['location'] = Variable<String>(location);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    map['image_url'] = Variable<String>(imageUrl);
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    map['username'] = Variable<String>(username);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || verificationQuestion != null) {
      map['verification_question'] = Variable<String>(verificationQuestion);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    map['pending_create'] = Variable<bool>(pendingCreate);
    map['pending_update'] = Variable<bool>(pendingUpdate);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      location: Value(location),
      date: Value(date),
      status: Value(status),
      imageUrl: Value(imageUrl),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      username: Value(username),
      ownerId: Value(ownerId),
      verificationQuestion: verificationQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(verificationQuestion),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
      pendingCreate: Value(pendingCreate),
      pendingUpdate: Value(pendingUpdate),
      pendingDelete: Value(pendingDelete),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      location: serializer.fromJson<String>(json['location']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      username: serializer.fromJson<String>(json['username']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      verificationQuestion: serializer.fromJson<String?>(
        json['verificationQuestion'],
      ),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      pendingCreate: serializer.fromJson<bool>(json['pendingCreate']),
      pendingUpdate: serializer.fromJson<bool>(json['pendingUpdate']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'location': serializer.toJson<String>(location),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'username': serializer.toJson<String>(username),
      'ownerId': serializer.toJson<String>(ownerId),
      'verificationQuestion': serializer.toJson<String?>(verificationQuestion),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
      'pendingCreate': serializer.toJson<bool>(pendingCreate),
      'pendingUpdate': serializer.toJson<bool>(pendingUpdate),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
    };
  }

  ItemRow copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? date,
    String? status,
    String? imageUrl,
    Value<String?> localImagePath = const Value.absent(),
    String? username,
    String? ownerId,
    Value<String?> verificationQuestion = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
    bool? synced,
    bool? pendingCreate,
    bool? pendingUpdate,
    bool? pendingDelete,
  }) => ItemRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    location: location ?? this.location,
    date: date ?? this.date,
    status: status ?? this.status,
    imageUrl: imageUrl ?? this.imageUrl,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    username: username ?? this.username,
    ownerId: ownerId ?? this.ownerId,
    verificationQuestion: verificationQuestion.present
        ? verificationQuestion.value
        : this.verificationQuestion,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    synced: synced ?? this.synced,
    pendingCreate: pendingCreate ?? this.pendingCreate,
    pendingUpdate: pendingUpdate ?? this.pendingUpdate,
    pendingDelete: pendingDelete ?? this.pendingDelete,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      location: data.location.present ? data.location.value : this.location,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      username: data.username.present ? data.username.value : this.username,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      verificationQuestion: data.verificationQuestion.present
          ? data.verificationQuestion.value
          : this.verificationQuestion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      pendingCreate: data.pendingCreate.present
          ? data.pendingCreate.value
          : this.pendingCreate,
      pendingUpdate: data.pendingUpdate.present
          ? data.pendingUpdate.value
          : this.pendingUpdate,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('username: $username, ')
          ..write('ownerId: $ownerId, ')
          ..write('verificationQuestion: $verificationQuestion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingUpdate: $pendingUpdate, ')
          ..write('pendingDelete: $pendingDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    location,
    date,
    status,
    imageUrl,
    localImagePath,
    username,
    ownerId,
    verificationQuestion,
    createdAt,
    updatedAt,
    synced,
    pendingCreate,
    pendingUpdate,
    pendingDelete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.location == this.location &&
          other.date == this.date &&
          other.status == this.status &&
          other.imageUrl == this.imageUrl &&
          other.localImagePath == this.localImagePath &&
          other.username == this.username &&
          other.ownerId == this.ownerId &&
          other.verificationQuestion == this.verificationQuestion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced &&
          other.pendingCreate == this.pendingCreate &&
          other.pendingUpdate == this.pendingUpdate &&
          other.pendingDelete == this.pendingDelete);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<String> location;
  final Value<String> date;
  final Value<String> status;
  final Value<String> imageUrl;
  final Value<String?> localImagePath;
  final Value<String> username;
  final Value<String> ownerId;
  final Value<String?> verificationQuestion;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<bool> pendingCreate;
  final Value<bool> pendingUpdate;
  final Value<bool> pendingDelete;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.username = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.verificationQuestion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingUpdate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.username = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.verificationQuestion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingUpdate = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? location,
    Expression<String>? date,
    Expression<String>? status,
    Expression<String>? imageUrl,
    Expression<String>? localImagePath,
    Expression<String>? username,
    Expression<String>? ownerId,
    Expression<String>? verificationQuestion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<bool>? pendingCreate,
    Expression<bool>? pendingUpdate,
    Expression<bool>? pendingDelete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (username != null) 'username': username,
      if (ownerId != null) 'owner_id': ownerId,
      if (verificationQuestion != null)
        'verification_question': verificationQuestion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (pendingCreate != null) 'pending_create': pendingCreate,
      if (pendingUpdate != null) 'pending_update': pendingUpdate,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? category,
    Value<String>? location,
    Value<String>? date,
    Value<String>? status,
    Value<String>? imageUrl,
    Value<String?>? localImagePath,
    Value<String>? username,
    Value<String>? ownerId,
    Value<String?>? verificationQuestion,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? synced,
    Value<bool>? pendingCreate,
    Value<bool>? pendingUpdate,
    Value<bool>? pendingDelete,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      username: username ?? this.username,
      ownerId: ownerId ?? this.ownerId,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      pendingCreate: pendingCreate ?? this.pendingCreate,
      pendingUpdate: pendingUpdate ?? this.pendingUpdate,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (verificationQuestion.present) {
      map['verification_question'] = Variable<String>(
        verificationQuestion.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (pendingCreate.present) {
      map['pending_create'] = Variable<bool>(pendingCreate.value);
    }
    if (pendingUpdate.present) {
      map['pending_update'] = Variable<bool>(pendingUpdate.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('username: $username, ')
          ..write('ownerId: $ownerId, ')
          ..write('verificationQuestion: $verificationQuestion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingUpdate: $pendingUpdate, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClaimsTable extends Claims with TableInfo<$ClaimsTable, ClaimRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _itemTitleMeta = const VerificationMeta(
    'itemTitle',
  );
  @override
  late final GeneratedColumn<String> itemTitle = GeneratedColumn<String>(
    'item_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _itemImageUrlMeta = const VerificationMeta(
    'itemImageUrl',
  );
  @override
  late final GeneratedColumn<String> itemImageUrl = GeneratedColumn<String>(
    'item_image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _claimantIdMeta = const VerificationMeta(
    'claimantId',
  );
  @override
  late final GeneratedColumn<String> claimantId = GeneratedColumn<String>(
    'claimant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _claimantNameMeta = const VerificationMeta(
    'claimantName',
  );
  @override
  late final GeneratedColumn<String> claimantName = GeneratedColumn<String>(
    'claimant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _additionalDetailsMeta = const VerificationMeta(
    'additionalDetails',
  );
  @override
  late final GeneratedColumn<String> additionalDetails =
      GeneratedColumn<String>(
        'additional_details',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendingCreateMeta = const VerificationMeta(
    'pendingCreate',
  );
  @override
  late final GeneratedColumn<bool> pendingCreate = GeneratedColumn<bool>(
    'pending_create',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_create" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pendingUpdateMeta = const VerificationMeta(
    'pendingUpdate',
  );
  @override
  late final GeneratedColumn<bool> pendingUpdate = GeneratedColumn<bool>(
    'pending_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_update" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    itemTitle,
    itemImageUrl,
    claimantId,
    claimantName,
    ownerId,
    answer,
    additionalDetails,
    status,
    createdAt,
    updatedAt,
    synced,
    pendingCreate,
    pendingUpdate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClaimRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('item_title')) {
      context.handle(
        _itemTitleMeta,
        itemTitle.isAcceptableOrUnknown(data['item_title']!, _itemTitleMeta),
      );
    }
    if (data.containsKey('item_image_url')) {
      context.handle(
        _itemImageUrlMeta,
        itemImageUrl.isAcceptableOrUnknown(
          data['item_image_url']!,
          _itemImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('claimant_id')) {
      context.handle(
        _claimantIdMeta,
        claimantId.isAcceptableOrUnknown(data['claimant_id']!, _claimantIdMeta),
      );
    }
    if (data.containsKey('claimant_name')) {
      context.handle(
        _claimantNameMeta,
        claimantName.isAcceptableOrUnknown(
          data['claimant_name']!,
          _claimantNameMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('additional_details')) {
      context.handle(
        _additionalDetailsMeta,
        additionalDetails.isAcceptableOrUnknown(
          data['additional_details']!,
          _additionalDetailsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('pending_create')) {
      context.handle(
        _pendingCreateMeta,
        pendingCreate.isAcceptableOrUnknown(
          data['pending_create']!,
          _pendingCreateMeta,
        ),
      );
    }
    if (data.containsKey('pending_update')) {
      context.handle(
        _pendingUpdateMeta,
        pendingUpdate.isAcceptableOrUnknown(
          data['pending_update']!,
          _pendingUpdateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClaimRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClaimRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_title'],
      )!,
      itemImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_image_url'],
      )!,
      claimantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimant_id'],
      )!,
      claimantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimant_name'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      additionalDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}additional_details'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      pendingCreate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_create'],
      )!,
      pendingUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_update'],
      )!,
    );
  }

  @override
  $ClaimsTable createAlias(String alias) {
    return $ClaimsTable(attachedDatabase, alias);
  }
}

class ClaimRow extends DataClass implements Insertable<ClaimRow> {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImageUrl;
  final String claimantId;
  final String claimantName;
  final String ownerId;
  final String answer;
  final String additionalDetails;
  final String status;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final bool synced;
  final bool pendingCreate;
  final bool pendingUpdate;
  const ClaimRow({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.claimantId,
    required this.claimantName,
    required this.ownerId,
    required this.answer,
    required this.additionalDetails,
    required this.status,
    this.createdAt,
    required this.updatedAt,
    required this.synced,
    required this.pendingCreate,
    required this.pendingUpdate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['item_title'] = Variable<String>(itemTitle);
    map['item_image_url'] = Variable<String>(itemImageUrl);
    map['claimant_id'] = Variable<String>(claimantId);
    map['claimant_name'] = Variable<String>(claimantName);
    map['owner_id'] = Variable<String>(ownerId);
    map['answer'] = Variable<String>(answer);
    map['additional_details'] = Variable<String>(additionalDetails);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    map['pending_create'] = Variable<bool>(pendingCreate);
    map['pending_update'] = Variable<bool>(pendingUpdate);
    return map;
  }

  ClaimsCompanion toCompanion(bool nullToAbsent) {
    return ClaimsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      itemTitle: Value(itemTitle),
      itemImageUrl: Value(itemImageUrl),
      claimantId: Value(claimantId),
      claimantName: Value(claimantName),
      ownerId: Value(ownerId),
      answer: Value(answer),
      additionalDetails: Value(additionalDetails),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
      pendingCreate: Value(pendingCreate),
      pendingUpdate: Value(pendingUpdate),
    );
  }

  factory ClaimRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClaimRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemTitle: serializer.fromJson<String>(json['itemTitle']),
      itemImageUrl: serializer.fromJson<String>(json['itemImageUrl']),
      claimantId: serializer.fromJson<String>(json['claimantId']),
      claimantName: serializer.fromJson<String>(json['claimantName']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      answer: serializer.fromJson<String>(json['answer']),
      additionalDetails: serializer.fromJson<String>(json['additionalDetails']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      pendingCreate: serializer.fromJson<bool>(json['pendingCreate']),
      pendingUpdate: serializer.fromJson<bool>(json['pendingUpdate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'itemTitle': serializer.toJson<String>(itemTitle),
      'itemImageUrl': serializer.toJson<String>(itemImageUrl),
      'claimantId': serializer.toJson<String>(claimantId),
      'claimantName': serializer.toJson<String>(claimantName),
      'ownerId': serializer.toJson<String>(ownerId),
      'answer': serializer.toJson<String>(answer),
      'additionalDetails': serializer.toJson<String>(additionalDetails),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
      'pendingCreate': serializer.toJson<bool>(pendingCreate),
      'pendingUpdate': serializer.toJson<bool>(pendingUpdate),
    };
  }

  ClaimRow copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemImageUrl,
    String? claimantId,
    String? claimantName,
    String? ownerId,
    String? answer,
    String? additionalDetails,
    String? status,
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
    bool? synced,
    bool? pendingCreate,
    bool? pendingUpdate,
  }) => ClaimRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    itemTitle: itemTitle ?? this.itemTitle,
    itemImageUrl: itemImageUrl ?? this.itemImageUrl,
    claimantId: claimantId ?? this.claimantId,
    claimantName: claimantName ?? this.claimantName,
    ownerId: ownerId ?? this.ownerId,
    answer: answer ?? this.answer,
    additionalDetails: additionalDetails ?? this.additionalDetails,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    synced: synced ?? this.synced,
    pendingCreate: pendingCreate ?? this.pendingCreate,
    pendingUpdate: pendingUpdate ?? this.pendingUpdate,
  );
  ClaimRow copyWithCompanion(ClaimsCompanion data) {
    return ClaimRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemTitle: data.itemTitle.present ? data.itemTitle.value : this.itemTitle,
      itemImageUrl: data.itemImageUrl.present
          ? data.itemImageUrl.value
          : this.itemImageUrl,
      claimantId: data.claimantId.present
          ? data.claimantId.value
          : this.claimantId,
      claimantName: data.claimantName.present
          ? data.claimantName.value
          : this.claimantName,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      answer: data.answer.present ? data.answer.value : this.answer,
      additionalDetails: data.additionalDetails.present
          ? data.additionalDetails.value
          : this.additionalDetails,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      pendingCreate: data.pendingCreate.present
          ? data.pendingCreate.value
          : this.pendingCreate,
      pendingUpdate: data.pendingUpdate.present
          ? data.pendingUpdate.value
          : this.pendingUpdate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClaimRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemTitle: $itemTitle, ')
          ..write('itemImageUrl: $itemImageUrl, ')
          ..write('claimantId: $claimantId, ')
          ..write('claimantName: $claimantName, ')
          ..write('ownerId: $ownerId, ')
          ..write('answer: $answer, ')
          ..write('additionalDetails: $additionalDetails, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingUpdate: $pendingUpdate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    itemTitle,
    itemImageUrl,
    claimantId,
    claimantName,
    ownerId,
    answer,
    additionalDetails,
    status,
    createdAt,
    updatedAt,
    synced,
    pendingCreate,
    pendingUpdate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClaimRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.itemTitle == this.itemTitle &&
          other.itemImageUrl == this.itemImageUrl &&
          other.claimantId == this.claimantId &&
          other.claimantName == this.claimantName &&
          other.ownerId == this.ownerId &&
          other.answer == this.answer &&
          other.additionalDetails == this.additionalDetails &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced &&
          other.pendingCreate == this.pendingCreate &&
          other.pendingUpdate == this.pendingUpdate);
}

class ClaimsCompanion extends UpdateCompanion<ClaimRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> itemTitle;
  final Value<String> itemImageUrl;
  final Value<String> claimantId;
  final Value<String> claimantName;
  final Value<String> ownerId;
  final Value<String> answer;
  final Value<String> additionalDetails;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  final Value<bool> pendingCreate;
  final Value<bool> pendingUpdate;
  final Value<int> rowid;
  const ClaimsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemTitle = const Value.absent(),
    this.itemImageUrl = const Value.absent(),
    this.claimantId = const Value.absent(),
    this.claimantName = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.answer = const Value.absent(),
    this.additionalDetails = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingUpdate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClaimsCompanion.insert({
    required String id,
    this.itemId = const Value.absent(),
    this.itemTitle = const Value.absent(),
    this.itemImageUrl = const Value.absent(),
    this.claimantId = const Value.absent(),
    this.claimantName = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.answer = const Value.absent(),
    this.additionalDetails = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.pendingUpdate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ClaimRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? itemTitle,
    Expression<String>? itemImageUrl,
    Expression<String>? claimantId,
    Expression<String>? claimantName,
    Expression<String>? ownerId,
    Expression<String>? answer,
    Expression<String>? additionalDetails,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
    Expression<bool>? pendingCreate,
    Expression<bool>? pendingUpdate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (itemTitle != null) 'item_title': itemTitle,
      if (itemImageUrl != null) 'item_image_url': itemImageUrl,
      if (claimantId != null) 'claimant_id': claimantId,
      if (claimantName != null) 'claimant_name': claimantName,
      if (ownerId != null) 'owner_id': ownerId,
      if (answer != null) 'answer': answer,
      if (additionalDetails != null) 'additional_details': additionalDetails,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
      if (pendingCreate != null) 'pending_create': pendingCreate,
      if (pendingUpdate != null) 'pending_update': pendingUpdate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClaimsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? itemTitle,
    Value<String>? itemImageUrl,
    Value<String>? claimantId,
    Value<String>? claimantName,
    Value<String>? ownerId,
    Value<String>? answer,
    Value<String>? additionalDetails,
    Value<String>? status,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? synced,
    Value<bool>? pendingCreate,
    Value<bool>? pendingUpdate,
    Value<int>? rowid,
  }) {
    return ClaimsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      claimantId: claimantId ?? this.claimantId,
      claimantName: claimantName ?? this.claimantName,
      ownerId: ownerId ?? this.ownerId,
      answer: answer ?? this.answer,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      pendingCreate: pendingCreate ?? this.pendingCreate,
      pendingUpdate: pendingUpdate ?? this.pendingUpdate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemTitle.present) {
      map['item_title'] = Variable<String>(itemTitle.value);
    }
    if (itemImageUrl.present) {
      map['item_image_url'] = Variable<String>(itemImageUrl.value);
    }
    if (claimantId.present) {
      map['claimant_id'] = Variable<String>(claimantId.value);
    }
    if (claimantName.present) {
      map['claimant_name'] = Variable<String>(claimantName.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (additionalDetails.present) {
      map['additional_details'] = Variable<String>(additionalDetails.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (pendingCreate.present) {
      map['pending_create'] = Variable<bool>(pendingCreate.value);
    }
    if (pendingUpdate.present) {
      map['pending_update'] = Variable<bool>(pendingUpdate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClaimsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemTitle: $itemTitle, ')
          ..write('itemImageUrl: $itemImageUrl, ')
          ..write('claimantId: $claimantId, ')
          ..write('claimantName: $claimantName, ')
          ..write('ownerId: $ownerId, ')
          ..write('answer: $answer, ')
          ..write('additionalDetails: $additionalDetails, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('pendingUpdate: $pendingUpdate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewerIdMeta = const VerificationMeta(
    'viewerId',
  );
  @override
  late final GeneratedColumn<String> viewerId = GeneratedColumn<String>(
    'viewer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _postIdMeta = const VerificationMeta('postId');
  @override
  late final GeneratedColumn<String> postId = GeneratedColumn<String>(
    'post_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Item'),
  );
  static const VerificationMeta _itemImageUrlMeta = const VerificationMeta(
    'itemImageUrl',
  );
  @override
  late final GeneratedColumn<String> itemImageUrl = GeneratedColumn<String>(
    'item_image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _participantIdsJsonMeta =
      const VerificationMeta('participantIdsJson');
  @override
  late final GeneratedColumn<String> participantIdsJson =
      GeneratedColumn<String>(
        'participant_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _otherUserIdMeta = const VerificationMeta(
    'otherUserId',
  );
  @override
  late final GeneratedColumn<String> otherUserId = GeneratedColumn<String>(
    'other_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _otherUserNameMeta = const VerificationMeta(
    'otherUserName',
  );
  @override
  late final GeneratedColumn<String> otherUserName = GeneratedColumn<String>(
    'other_user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('User'),
  );
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastMessageTimeMeta = const VerificationMeta(
    'lastMessageTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageTime =
      GeneratedColumn<DateTime>(
        'last_message_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pendingMarkReadMeta = const VerificationMeta(
    'pendingMarkRead',
  );
  @override
  late final GeneratedColumn<bool> pendingMarkRead = GeneratedColumn<bool>(
    'pending_mark_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_mark_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    viewerId,
    postId,
    itemName,
    itemImageUrl,
    itemType,
    participantIdsJson,
    otherUserId,
    otherUserName,
    lastMessage,
    lastMessageTime,
    unreadCount,
    pendingMarkRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('viewer_id')) {
      context.handle(
        _viewerIdMeta,
        viewerId.isAcceptableOrUnknown(data['viewer_id']!, _viewerIdMeta),
      );
    }
    if (data.containsKey('post_id')) {
      context.handle(
        _postIdMeta,
        postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    }
    if (data.containsKey('item_image_url')) {
      context.handle(
        _itemImageUrlMeta,
        itemImageUrl.isAcceptableOrUnknown(
          data['item_image_url']!,
          _itemImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    }
    if (data.containsKey('participant_ids_json')) {
      context.handle(
        _participantIdsJsonMeta,
        participantIdsJson.isAcceptableOrUnknown(
          data['participant_ids_json']!,
          _participantIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
        _otherUserIdMeta,
        otherUserId.isAcceptableOrUnknown(
          data['other_user_id']!,
          _otherUserIdMeta,
        ),
      );
    }
    if (data.containsKey('other_user_name')) {
      context.handle(
        _otherUserNameMeta,
        otherUserName.isAcceptableOrUnknown(
          data['other_user_name']!,
          _otherUserNameMeta,
        ),
      );
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_message_time')) {
      context.handle(
        _lastMessageTimeMeta,
        lastMessageTime.isAcceptableOrUnknown(
          data['last_message_time']!,
          _lastMessageTimeMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('pending_mark_read')) {
      context.handle(
        _pendingMarkReadMeta,
        pendingMarkRead.isAcceptableOrUnknown(
          data['pending_mark_read']!,
          _pendingMarkReadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}viewer_id'],
      )!,
      postId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}post_id'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      itemImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_image_url'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      participantIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_ids_json'],
      )!,
      otherUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_id'],
      )!,
      otherUserName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_name'],
      )!,
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      )!,
      lastMessageTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_time'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      pendingMarkRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_mark_read'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationRow extends DataClass implements Insertable<ConversationRow> {
  final String id;
  final String viewerId;
  final String postId;
  final String itemName;
  final String itemImageUrl;
  final String itemType;

  /// JSON-encoded `List<String>` of participant ids.
  final String participantIdsJson;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  /// True once a local "mark as read" still needs to be pushed to Firestore.
  final bool pendingMarkRead;
  const ConversationRow({
    required this.id,
    required this.viewerId,
    required this.postId,
    required this.itemName,
    required this.itemImageUrl,
    required this.itemType,
    required this.participantIdsJson,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.pendingMarkRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['viewer_id'] = Variable<String>(viewerId);
    map['post_id'] = Variable<String>(postId);
    map['item_name'] = Variable<String>(itemName);
    map['item_image_url'] = Variable<String>(itemImageUrl);
    map['item_type'] = Variable<String>(itemType);
    map['participant_ids_json'] = Variable<String>(participantIdsJson);
    map['other_user_id'] = Variable<String>(otherUserId);
    map['other_user_name'] = Variable<String>(otherUserName);
    map['last_message'] = Variable<String>(lastMessage);
    map['last_message_time'] = Variable<DateTime>(lastMessageTime);
    map['unread_count'] = Variable<int>(unreadCount);
    map['pending_mark_read'] = Variable<bool>(pendingMarkRead);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      viewerId: Value(viewerId),
      postId: Value(postId),
      itemName: Value(itemName),
      itemImageUrl: Value(itemImageUrl),
      itemType: Value(itemType),
      participantIdsJson: Value(participantIdsJson),
      otherUserId: Value(otherUserId),
      otherUserName: Value(otherUserName),
      lastMessage: Value(lastMessage),
      lastMessageTime: Value(lastMessageTime),
      unreadCount: Value(unreadCount),
      pendingMarkRead: Value(pendingMarkRead),
    );
  }

  factory ConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationRow(
      id: serializer.fromJson<String>(json['id']),
      viewerId: serializer.fromJson<String>(json['viewerId']),
      postId: serializer.fromJson<String>(json['postId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      itemImageUrl: serializer.fromJson<String>(json['itemImageUrl']),
      itemType: serializer.fromJson<String>(json['itemType']),
      participantIdsJson: serializer.fromJson<String>(
        json['participantIdsJson'],
      ),
      otherUserId: serializer.fromJson<String>(json['otherUserId']),
      otherUserName: serializer.fromJson<String>(json['otherUserName']),
      lastMessage: serializer.fromJson<String>(json['lastMessage']),
      lastMessageTime: serializer.fromJson<DateTime>(json['lastMessageTime']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      pendingMarkRead: serializer.fromJson<bool>(json['pendingMarkRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewerId': serializer.toJson<String>(viewerId),
      'postId': serializer.toJson<String>(postId),
      'itemName': serializer.toJson<String>(itemName),
      'itemImageUrl': serializer.toJson<String>(itemImageUrl),
      'itemType': serializer.toJson<String>(itemType),
      'participantIdsJson': serializer.toJson<String>(participantIdsJson),
      'otherUserId': serializer.toJson<String>(otherUserId),
      'otherUserName': serializer.toJson<String>(otherUserName),
      'lastMessage': serializer.toJson<String>(lastMessage),
      'lastMessageTime': serializer.toJson<DateTime>(lastMessageTime),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'pendingMarkRead': serializer.toJson<bool>(pendingMarkRead),
    };
  }

  ConversationRow copyWith({
    String? id,
    String? viewerId,
    String? postId,
    String? itemName,
    String? itemImageUrl,
    String? itemType,
    String? participantIdsJson,
    String? otherUserId,
    String? otherUserName,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? pendingMarkRead,
  }) => ConversationRow(
    id: id ?? this.id,
    viewerId: viewerId ?? this.viewerId,
    postId: postId ?? this.postId,
    itemName: itemName ?? this.itemName,
    itemImageUrl: itemImageUrl ?? this.itemImageUrl,
    itemType: itemType ?? this.itemType,
    participantIdsJson: participantIdsJson ?? this.participantIdsJson,
    otherUserId: otherUserId ?? this.otherUserId,
    otherUserName: otherUserName ?? this.otherUserName,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    unreadCount: unreadCount ?? this.unreadCount,
    pendingMarkRead: pendingMarkRead ?? this.pendingMarkRead,
  );
  ConversationRow copyWithCompanion(ConversationsCompanion data) {
    return ConversationRow(
      id: data.id.present ? data.id.value : this.id,
      viewerId: data.viewerId.present ? data.viewerId.value : this.viewerId,
      postId: data.postId.present ? data.postId.value : this.postId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      itemImageUrl: data.itemImageUrl.present
          ? data.itemImageUrl.value
          : this.itemImageUrl,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      participantIdsJson: data.participantIdsJson.present
          ? data.participantIdsJson.value
          : this.participantIdsJson,
      otherUserId: data.otherUserId.present
          ? data.otherUserId.value
          : this.otherUserId,
      otherUserName: data.otherUserName.present
          ? data.otherUserName.value
          : this.otherUserName,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      lastMessageTime: data.lastMessageTime.present
          ? data.lastMessageTime.value
          : this.lastMessageTime,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      pendingMarkRead: data.pendingMarkRead.present
          ? data.pendingMarkRead.value
          : this.pendingMarkRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationRow(')
          ..write('id: $id, ')
          ..write('viewerId: $viewerId, ')
          ..write('postId: $postId, ')
          ..write('itemName: $itemName, ')
          ..write('itemImageUrl: $itemImageUrl, ')
          ..write('itemType: $itemType, ')
          ..write('participantIdsJson: $participantIdsJson, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('pendingMarkRead: $pendingMarkRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    viewerId,
    postId,
    itemName,
    itemImageUrl,
    itemType,
    participantIdsJson,
    otherUserId,
    otherUserName,
    lastMessage,
    lastMessageTime,
    unreadCount,
    pendingMarkRead,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationRow &&
          other.id == this.id &&
          other.viewerId == this.viewerId &&
          other.postId == this.postId &&
          other.itemName == this.itemName &&
          other.itemImageUrl == this.itemImageUrl &&
          other.itemType == this.itemType &&
          other.participantIdsJson == this.participantIdsJson &&
          other.otherUserId == this.otherUserId &&
          other.otherUserName == this.otherUserName &&
          other.lastMessage == this.lastMessage &&
          other.lastMessageTime == this.lastMessageTime &&
          other.unreadCount == this.unreadCount &&
          other.pendingMarkRead == this.pendingMarkRead);
}

class ConversationsCompanion extends UpdateCompanion<ConversationRow> {
  final Value<String> id;
  final Value<String> viewerId;
  final Value<String> postId;
  final Value<String> itemName;
  final Value<String> itemImageUrl;
  final Value<String> itemType;
  final Value<String> participantIdsJson;
  final Value<String> otherUserId;
  final Value<String> otherUserName;
  final Value<String> lastMessage;
  final Value<DateTime> lastMessageTime;
  final Value<int> unreadCount;
  final Value<bool> pendingMarkRead;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.viewerId = const Value.absent(),
    this.postId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.itemImageUrl = const Value.absent(),
    this.itemType = const Value.absent(),
    this.participantIdsJson = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.otherUserName = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageTime = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.pendingMarkRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.viewerId = const Value.absent(),
    this.postId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.itemImageUrl = const Value.absent(),
    this.itemType = const Value.absent(),
    this.participantIdsJson = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.otherUserName = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageTime = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.pendingMarkRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ConversationRow> custom({
    Expression<String>? id,
    Expression<String>? viewerId,
    Expression<String>? postId,
    Expression<String>? itemName,
    Expression<String>? itemImageUrl,
    Expression<String>? itemType,
    Expression<String>? participantIdsJson,
    Expression<String>? otherUserId,
    Expression<String>? otherUserName,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastMessageTime,
    Expression<int>? unreadCount,
    Expression<bool>? pendingMarkRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewerId != null) 'viewer_id': viewerId,
      if (postId != null) 'post_id': postId,
      if (itemName != null) 'item_name': itemName,
      if (itemImageUrl != null) 'item_image_url': itemImageUrl,
      if (itemType != null) 'item_type': itemType,
      if (participantIdsJson != null)
        'participant_ids_json': participantIdsJson,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (otherUserName != null) 'other_user_name': otherUserName,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageTime != null) 'last_message_time': lastMessageTime,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (pendingMarkRead != null) 'pending_mark_read': pendingMarkRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? viewerId,
    Value<String>? postId,
    Value<String>? itemName,
    Value<String>? itemImageUrl,
    Value<String>? itemType,
    Value<String>? participantIdsJson,
    Value<String>? otherUserId,
    Value<String>? otherUserName,
    Value<String>? lastMessage,
    Value<DateTime>? lastMessageTime,
    Value<int>? unreadCount,
    Value<bool>? pendingMarkRead,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      viewerId: viewerId ?? this.viewerId,
      postId: postId ?? this.postId,
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      itemType: itemType ?? this.itemType,
      participantIdsJson: participantIdsJson ?? this.participantIdsJson,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      pendingMarkRead: pendingMarkRead ?? this.pendingMarkRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewerId.present) {
      map['viewer_id'] = Variable<String>(viewerId.value);
    }
    if (postId.present) {
      map['post_id'] = Variable<String>(postId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (itemImageUrl.present) {
      map['item_image_url'] = Variable<String>(itemImageUrl.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (participantIdsJson.present) {
      map['participant_ids_json'] = Variable<String>(participantIdsJson.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<String>(otherUserId.value);
    }
    if (otherUserName.present) {
      map['other_user_name'] = Variable<String>(otherUserName.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastMessageTime.present) {
      map['last_message_time'] = Variable<DateTime>(lastMessageTime.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (pendingMarkRead.present) {
      map['pending_mark_read'] = Variable<bool>(pendingMarkRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('viewerId: $viewerId, ')
          ..write('postId: $postId, ')
          ..write('itemName: $itemName, ')
          ..write('itemImageUrl: $itemImageUrl, ')
          ..write('itemType: $itemType, ')
          ..write('participantIdsJson: $participantIdsJson, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageTime: $lastMessageTime, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('pendingMarkRead: $pendingMarkRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('User'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendingCreateMeta = const VerificationMeta(
    'pendingCreate',
  );
  @override
  late final GeneratedColumn<bool> pendingCreate = GeneratedColumn<bool>(
    'pending_create',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_create" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    senderName,
    content,
    timestamp,
    isRead,
    synced,
    pendingCreate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('pending_create')) {
      context.handle(
        _pendingCreateMeta,
        pendingCreate.isAcceptableOrUnknown(
          data['pending_create']!,
          _pendingCreateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      pendingCreate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_create'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;

  /// The message body. Named `content` (not `text`) to avoid clashing with
  /// Drift's `text()` column builder.
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool synced;
  final bool pendingCreate;
  const MessageRow({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.synced,
    required this.pendingCreate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['sender_name'] = Variable<String>(senderName);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_read'] = Variable<bool>(isRead);
    map['synced'] = Variable<bool>(synced);
    map['pending_create'] = Variable<bool>(pendingCreate);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      senderName: Value(senderName),
      content: Value(content),
      timestamp: Value(timestamp),
      isRead: Value(isRead),
      synced: Value(synced),
      pendingCreate: Value(pendingCreate),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderName: serializer.fromJson<String>(json['senderName']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      synced: serializer.fromJson<bool>(json['synced']),
      pendingCreate: serializer.fromJson<bool>(json['pendingCreate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'senderName': serializer.toJson<String>(senderName),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isRead': serializer.toJson<bool>(isRead),
      'synced': serializer.toJson<bool>(synced),
      'pendingCreate': serializer.toJson<bool>(pendingCreate),
    };
  }

  MessageRow copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    bool? synced,
    bool? pendingCreate,
  }) => MessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    isRead: isRead ?? this.isRead,
    synced: synced ?? this.synced,
    pendingCreate: pendingCreate ?? this.pendingCreate,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      synced: data.synced.present ? data.synced.value : this.synced,
      pendingCreate: data.pendingCreate.present
          ? data.pendingCreate.value
          : this.pendingCreate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    senderName,
    content,
    timestamp,
    isRead,
    synced,
    pendingCreate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.senderName == this.senderName &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.isRead == this.isRead &&
          other.synced == this.synced &&
          other.pendingCreate == this.pendingCreate);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> senderName;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<bool> isRead;
  final Value<bool> synced;
  final Value<bool> pendingCreate;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRead = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRead = const Value.absent(),
    this.synced = const Value.absent(),
    this.pendingCreate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MessageRow> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? senderName,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<bool>? isRead,
    Expression<bool>? synced,
    Expression<bool>? pendingCreate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRead != null) 'is_read': isRead,
      if (synced != null) 'synced': synced,
      if (pendingCreate != null) 'pending_create': pendingCreate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<String>? senderName,
    Value<String>? content,
    Value<DateTime>? timestamp,
    Value<bool>? isRead,
    Value<bool>? synced,
    Value<bool>? pendingCreate,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      synced: synced ?? this.synced,
      pendingCreate: pendingCreate ?? this.pendingCreate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (pendingCreate.present) {
      map['pending_create'] = Variable<bool>(pendingCreate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead, ')
          ..write('synced: $synced, ')
          ..write('pendingCreate: $pendingCreate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _relatedItemIdMeta = const VerificationMeta(
    'relatedItemId',
  );
  @override
  late final GeneratedColumn<String> relatedItemId = GeneratedColumn<String>(
    'related_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedClaimIdMeta = const VerificationMeta(
    'relatedClaimId',
  );
  @override
  late final GeneratedColumn<String> relatedClaimId = GeneratedColumn<String>(
    'related_claim_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMarkReadMeta = const VerificationMeta(
    'pendingMarkRead',
  );
  @override
  late final GeneratedColumn<bool> pendingMarkRead = GeneratedColumn<bool>(
    'pending_mark_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_mark_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipientId,
    type,
    title,
    message,
    relatedItemId,
    relatedClaimId,
    isRead,
    createdAt,
    pendingMarkRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('related_item_id')) {
      context.handle(
        _relatedItemIdMeta,
        relatedItemId.isAcceptableOrUnknown(
          data['related_item_id']!,
          _relatedItemIdMeta,
        ),
      );
    }
    if (data.containsKey('related_claim_id')) {
      context.handle(
        _relatedClaimIdMeta,
        relatedClaimId.isAcceptableOrUnknown(
          data['related_claim_id']!,
          _relatedClaimIdMeta,
        ),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('pending_mark_read')) {
      context.handle(
        _pendingMarkReadMeta,
        pendingMarkRead.isAcceptableOrUnknown(
          data['pending_mark_read']!,
          _pendingMarkReadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      relatedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_item_id'],
      ),
      relatedClaimId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_claim_id'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      pendingMarkRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_mark_read'],
      )!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String message;
  final String? relatedItemId;
  final String? relatedClaimId;
  final bool isRead;
  final DateTime? createdAt;

  /// True once a local "mark as read" still needs to be pushed to Firestore.
  final bool pendingMarkRead;
  const NotificationRow({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedItemId,
    this.relatedClaimId,
    required this.isRead,
    this.createdAt,
    required this.pendingMarkRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipient_id'] = Variable<String>(recipientId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || relatedItemId != null) {
      map['related_item_id'] = Variable<String>(relatedItemId);
    }
    if (!nullToAbsent || relatedClaimId != null) {
      map['related_claim_id'] = Variable<String>(relatedClaimId);
    }
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['pending_mark_read'] = Variable<bool>(pendingMarkRead);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      recipientId: Value(recipientId),
      type: Value(type),
      title: Value(title),
      message: Value(message),
      relatedItemId: relatedItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedItemId),
      relatedClaimId: relatedClaimId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedClaimId),
      isRead: Value(isRead),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      pendingMarkRead: Value(pendingMarkRead),
    );
  }

  factory NotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      id: serializer.fromJson<String>(json['id']),
      recipientId: serializer.fromJson<String>(json['recipientId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      relatedItemId: serializer.fromJson<String?>(json['relatedItemId']),
      relatedClaimId: serializer.fromJson<String?>(json['relatedClaimId']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      pendingMarkRead: serializer.fromJson<bool>(json['pendingMarkRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipientId': serializer.toJson<String>(recipientId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'relatedItemId': serializer.toJson<String?>(relatedItemId),
      'relatedClaimId': serializer.toJson<String?>(relatedClaimId),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'pendingMarkRead': serializer.toJson<bool>(pendingMarkRead),
    };
  }

  NotificationRow copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? title,
    String? message,
    Value<String?> relatedItemId = const Value.absent(),
    Value<String?> relatedClaimId = const Value.absent(),
    bool? isRead,
    Value<DateTime?> createdAt = const Value.absent(),
    bool? pendingMarkRead,
  }) => NotificationRow(
    id: id ?? this.id,
    recipientId: recipientId ?? this.recipientId,
    type: type ?? this.type,
    title: title ?? this.title,
    message: message ?? this.message,
    relatedItemId: relatedItemId.present
        ? relatedItemId.value
        : this.relatedItemId,
    relatedClaimId: relatedClaimId.present
        ? relatedClaimId.value
        : this.relatedClaimId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    pendingMarkRead: pendingMarkRead ?? this.pendingMarkRead,
  );
  NotificationRow copyWithCompanion(NotificationsCompanion data) {
    return NotificationRow(
      id: data.id.present ? data.id.value : this.id,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      relatedItemId: data.relatedItemId.present
          ? data.relatedItemId.value
          : this.relatedItemId,
      relatedClaimId: data.relatedClaimId.present
          ? data.relatedClaimId.value
          : this.relatedClaimId,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pendingMarkRead: data.pendingMarkRead.present
          ? data.pendingMarkRead.value
          : this.pendingMarkRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('relatedItemId: $relatedItemId, ')
          ..write('relatedClaimId: $relatedClaimId, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('pendingMarkRead: $pendingMarkRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipientId,
    type,
    title,
    message,
    relatedItemId,
    relatedClaimId,
    isRead,
    createdAt,
    pendingMarkRead,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.id == this.id &&
          other.recipientId == this.recipientId &&
          other.type == this.type &&
          other.title == this.title &&
          other.message == this.message &&
          other.relatedItemId == this.relatedItemId &&
          other.relatedClaimId == this.relatedClaimId &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.pendingMarkRead == this.pendingMarkRead);
}

class NotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> id;
  final Value<String> recipientId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> message;
  final Value<String?> relatedItemId;
  final Value<String?> relatedClaimId;
  final Value<bool> isRead;
  final Value<DateTime?> createdAt;
  final Value<bool> pendingMarkRead;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.relatedItemId = const Value.absent(),
    this.relatedClaimId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pendingMarkRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    this.recipientId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.relatedItemId = const Value.absent(),
    this.relatedClaimId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pendingMarkRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<NotificationRow> custom({
    Expression<String>? id,
    Expression<String>? recipientId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? relatedItemId,
    Expression<String>? relatedClaimId,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<bool>? pendingMarkRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipientId != null) 'recipient_id': recipientId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (relatedItemId != null) 'related_item_id': relatedItemId,
      if (relatedClaimId != null) 'related_claim_id': relatedClaimId,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (pendingMarkRead != null) 'pending_mark_read': pendingMarkRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipientId,
    Value<String>? type,
    Value<String>? title,
    Value<String>? message,
    Value<String?>? relatedItemId,
    Value<String?>? relatedClaimId,
    Value<bool>? isRead,
    Value<DateTime?>? createdAt,
    Value<bool>? pendingMarkRead,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      relatedClaimId: relatedClaimId ?? this.relatedClaimId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      pendingMarkRead: pendingMarkRead ?? this.pendingMarkRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (relatedItemId.present) {
      map['related_item_id'] = Variable<String>(relatedItemId.value);
    }
    if (relatedClaimId.present) {
      map['related_claim_id'] = Variable<String>(relatedClaimId.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pendingMarkRead.present) {
      map['pending_mark_read'] = Variable<bool>(pendingMarkRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('relatedItemId: $relatedItemId, ')
          ..write('relatedClaimId: $relatedClaimId, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('pendingMarkRead: $pendingMarkRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ClaimsTable claims = $ClaimsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    items,
    claims,
    conversations,
    messages,
    notifications,
  ];
}

typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<String> location,
      Value<String> date,
      Value<String> status,
      Value<String> imageUrl,
      Value<String?> localImagePath,
      Value<String> username,
      Value<String> ownerId,
      Value<String?> verificationQuestion,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<bool> pendingUpdate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<String> location,
      Value<String> date,
      Value<String> status,
      Value<String> imageUrl,
      Value<String?> localImagePath,
      Value<String> username,
      Value<String> ownerId,
      Value<String?> verificationQuestion,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<bool> pendingUpdate,
      Value<bool> pendingDelete,
      Value<int> rowid,
    });

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationQuestion => $composableBuilder(
    column: $table.verificationQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationQuestion => $composableBuilder(
    column: $table.verificationQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get verificationQuestion => $composableBuilder(
    column: $table.verificationQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
    column: $table.pendingDelete,
    builder: (column) => column,
  );
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          ItemRow,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
          ItemRow,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> verificationQuestion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingUpdate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                title: title,
                description: description,
                category: category,
                location: location,
                date: date,
                status: status,
                imageUrl: imageUrl,
                localImagePath: localImagePath,
                username: username,
                ownerId: ownerId,
                verificationQuestion: verificationQuestion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                synced: synced,
                pendingCreate: pendingCreate,
                pendingUpdate: pendingUpdate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String?> verificationQuestion = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingUpdate = const Value.absent(),
                Value<bool> pendingDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                title: title,
                description: description,
                category: category,
                location: location,
                date: date,
                status: status,
                imageUrl: imageUrl,
                localImagePath: localImagePath,
                username: username,
                ownerId: ownerId,
                verificationQuestion: verificationQuestion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                synced: synced,
                pendingCreate: pendingCreate,
                pendingUpdate: pendingUpdate,
                pendingDelete: pendingDelete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      ItemRow,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
      ItemRow,
      PrefetchHooks Function()
    >;
typedef $$ClaimsTableCreateCompanionBuilder =
    ClaimsCompanion Function({
      required String id,
      Value<String> itemId,
      Value<String> itemTitle,
      Value<String> itemImageUrl,
      Value<String> claimantId,
      Value<String> claimantName,
      Value<String> ownerId,
      Value<String> answer,
      Value<String> additionalDetails,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<bool> pendingUpdate,
      Value<int> rowid,
    });
typedef $$ClaimsTableUpdateCompanionBuilder =
    ClaimsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> itemTitle,
      Value<String> itemImageUrl,
      Value<String> claimantId,
      Value<String> claimantName,
      Value<String> ownerId,
      Value<String> answer,
      Value<String> additionalDetails,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<bool> pendingUpdate,
      Value<int> rowid,
    });

class $$ClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableFilterComposer({
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

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemTitle => $composableBuilder(
    column: $table.itemTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimantId => $composableBuilder(
    column: $table.claimantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimantName => $composableBuilder(
    column: $table.claimantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get additionalDetails => $composableBuilder(
    column: $table.additionalDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableOrderingComposer({
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

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemTitle => $composableBuilder(
    column: $table.itemTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimantId => $composableBuilder(
    column: $table.claimantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimantName => $composableBuilder(
    column: $table.claimantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get additionalDetails => $composableBuilder(
    column: $table.additionalDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemTitle =>
      $composableBuilder(column: $table.itemTitle, builder: (column) => column);

  GeneratedColumn<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimantId => $composableBuilder(
    column: $table.claimantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimantName => $composableBuilder(
    column: $table.claimantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get additionalDetails => $composableBuilder(
    column: $table.additionalDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingUpdate => $composableBuilder(
    column: $table.pendingUpdate,
    builder: (column) => column,
  );
}

class $$ClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClaimsTable,
          ClaimRow,
          $$ClaimsTableFilterComposer,
          $$ClaimsTableOrderingComposer,
          $$ClaimsTableAnnotationComposer,
          $$ClaimsTableCreateCompanionBuilder,
          $$ClaimsTableUpdateCompanionBuilder,
          (ClaimRow, BaseReferences<_$AppDatabase, $ClaimsTable, ClaimRow>),
          ClaimRow,
          PrefetchHooks Function()
        > {
  $$ClaimsTableTableManager(_$AppDatabase db, $ClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemTitle = const Value.absent(),
                Value<String> itemImageUrl = const Value.absent(),
                Value<String> claimantId = const Value.absent(),
                Value<String> claimantName = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> additionalDetails = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingUpdate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimsCompanion(
                id: id,
                itemId: itemId,
                itemTitle: itemTitle,
                itemImageUrl: itemImageUrl,
                claimantId: claimantId,
                claimantName: claimantName,
                ownerId: ownerId,
                answer: answer,
                additionalDetails: additionalDetails,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                synced: synced,
                pendingCreate: pendingCreate,
                pendingUpdate: pendingUpdate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> itemId = const Value.absent(),
                Value<String> itemTitle = const Value.absent(),
                Value<String> itemImageUrl = const Value.absent(),
                Value<String> claimantId = const Value.absent(),
                Value<String> claimantName = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> additionalDetails = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<bool> pendingUpdate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimsCompanion.insert(
                id: id,
                itemId: itemId,
                itemTitle: itemTitle,
                itemImageUrl: itemImageUrl,
                claimantId: claimantId,
                claimantName: claimantName,
                ownerId: ownerId,
                answer: answer,
                additionalDetails: additionalDetails,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                synced: synced,
                pendingCreate: pendingCreate,
                pendingUpdate: pendingUpdate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClaimsTable,
      ClaimRow,
      $$ClaimsTableFilterComposer,
      $$ClaimsTableOrderingComposer,
      $$ClaimsTableAnnotationComposer,
      $$ClaimsTableCreateCompanionBuilder,
      $$ClaimsTableUpdateCompanionBuilder,
      (ClaimRow, BaseReferences<_$AppDatabase, $ClaimsTable, ClaimRow>),
      ClaimRow,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> viewerId,
      Value<String> postId,
      Value<String> itemName,
      Value<String> itemImageUrl,
      Value<String> itemType,
      Value<String> participantIdsJson,
      Value<String> otherUserId,
      Value<String> otherUserName,
      Value<String> lastMessage,
      Value<DateTime> lastMessageTime,
      Value<int> unreadCount,
      Value<bool> pendingMarkRead,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> viewerId,
      Value<String> postId,
      Value<String> itemName,
      Value<String> itemImageUrl,
      Value<String> itemType,
      Value<String> participantIdsJson,
      Value<String> otherUserId,
      Value<String> otherUserName,
      Value<String> lastMessage,
      Value<DateTime> lastMessageTime,
      Value<int> unreadCount,
      Value<bool> pendingMarkRead,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
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

  ColumnFilters<String> get viewerId => $composableBuilder(
    column: $table.viewerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantIdsJson => $composableBuilder(
    column: $table.participantIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get viewerId => $composableBuilder(
    column: $table.viewerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postId => $composableBuilder(
    column: $table.postId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantIdsJson => $composableBuilder(
    column: $table.participantIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewerId =>
      $composableBuilder(column: $table.viewerId, builder: (column) => column);

  GeneratedColumn<String> get postId =>
      $composableBuilder(column: $table.postId, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get itemImageUrl => $composableBuilder(
    column: $table.itemImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get participantIdsJson => $composableBuilder(
    column: $table.participantIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageTime => $composableBuilder(
    column: $table.lastMessageTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationRow,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            ConversationRow,
            BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
          ),
          ConversationRow,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> viewerId = const Value.absent(),
                Value<String> postId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> itemImageUrl = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> participantIdsJson = const Value.absent(),
                Value<String> otherUserId = const Value.absent(),
                Value<String> otherUserName = const Value.absent(),
                Value<String> lastMessage = const Value.absent(),
                Value<DateTime> lastMessageTime = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> pendingMarkRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                viewerId: viewerId,
                postId: postId,
                itemName: itemName,
                itemImageUrl: itemImageUrl,
                itemType: itemType,
                participantIdsJson: participantIdsJson,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                pendingMarkRead: pendingMarkRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> viewerId = const Value.absent(),
                Value<String> postId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> itemImageUrl = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> participantIdsJson = const Value.absent(),
                Value<String> otherUserId = const Value.absent(),
                Value<String> otherUserName = const Value.absent(),
                Value<String> lastMessage = const Value.absent(),
                Value<DateTime> lastMessageTime = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> pendingMarkRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                viewerId: viewerId,
                postId: postId,
                itemName: itemName,
                itemImageUrl: itemImageUrl,
                itemType: itemType,
                participantIdsJson: participantIdsJson,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
                pendingMarkRead: pendingMarkRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationRow,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        ConversationRow,
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
      ),
      ConversationRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> senderName,
      Value<String> content,
      Value<DateTime> timestamp,
      Value<bool> isRead,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> senderName,
      Value<String> content,
      Value<DateTime> timestamp,
      Value<bool> isRead,
      Value<bool> synced,
      Value<bool> pendingCreate,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<bool> get pendingCreate => $composableBuilder(
    column: $table.pendingCreate,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> senderName = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                content: content,
                timestamp: timestamp,
                isRead: isRead,
                synced: synced,
                pendingCreate: pendingCreate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> senderName = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> pendingCreate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                content: content,
                timestamp: timestamp,
                isRead: isRead,
                synced: synced,
                pendingCreate: pendingCreate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      required String id,
      Value<String> recipientId,
      Value<String> type,
      Value<String> title,
      Value<String> message,
      Value<String?> relatedItemId,
      Value<String?> relatedClaimId,
      Value<bool> isRead,
      Value<DateTime?> createdAt,
      Value<bool> pendingMarkRead,
      Value<int> rowid,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<String> id,
      Value<String> recipientId,
      Value<String> type,
      Value<String> title,
      Value<String> message,
      Value<String?> relatedItemId,
      Value<String?> relatedClaimId,
      Value<bool> isRead,
      Value<DateTime?> createdAt,
      Value<bool> pendingMarkRead,
      Value<int> rowid,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
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

  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedItemId => $composableBuilder(
    column: $table.relatedItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedClaimId => $composableBuilder(
    column: $table.relatedClaimId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
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

  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedItemId => $composableBuilder(
    column: $table.relatedItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedClaimId => $composableBuilder(
    column: $table.relatedClaimId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get relatedItemId => $composableBuilder(
    column: $table.relatedItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedClaimId => $composableBuilder(
    column: $table.relatedClaimId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingMarkRead => $composableBuilder(
    column: $table.pendingMarkRead,
    builder: (column) => column,
  );
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTable,
          NotificationRow,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            NotificationRow,
            BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
          ),
          NotificationRow,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipientId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> relatedItemId = const Value.absent(),
                Value<String?> relatedClaimId = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<bool> pendingMarkRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion(
                id: id,
                recipientId: recipientId,
                type: type,
                title: title,
                message: message,
                relatedItemId: relatedItemId,
                relatedClaimId: relatedClaimId,
                isRead: isRead,
                createdAt: createdAt,
                pendingMarkRead: pendingMarkRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> recipientId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> relatedItemId = const Value.absent(),
                Value<String?> relatedClaimId = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<bool> pendingMarkRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion.insert(
                id: id,
                recipientId: recipientId,
                type: type,
                title: title,
                message: message,
                relatedItemId: relatedItemId,
                relatedClaimId: relatedClaimId,
                isRead: isRead,
                createdAt: createdAt,
                pendingMarkRead: pendingMarkRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTable,
      NotificationRow,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        NotificationRow,
        BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
      ),
      NotificationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ClaimsTableTableManager get claims =>
      $$ClaimsTableTableManager(_db, _db.claims);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
}
