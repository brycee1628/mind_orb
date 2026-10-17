import 'package:hive/hive.dart';

import '../core/utils/constants.dart';

/// 順序即 Hive 儲存值，不可調換或插入。
enum EmotionType { joy, sadness, anger, calm, anxiety }

class MindOrb {
  const MindOrb({
    required this.id,
    required this.title,
    required this.content,
    required this.emotion,
    required this.createdAt,
    this.isPublic = false,
    this.hugCount = 0,
  }) : assert(id != ''),
       assert(title.length <= AppConstants.maxTitleLength),
       assert(content.length <= AppConstants.maxContentLength);

  final String id;
  final String title;
  final String content;
  final EmotionType emotion;
  final DateTime createdAt;
  final bool isPublic;
  final int hugCount;

  MindOrb copyWith({
    String? id,
    String? title,
    String? content,
    EmotionType? emotion,
    DateTime? createdAt,
    bool? isPublic,
    int? hugCount,
  }) {
    return MindOrb(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      hugCount: hugCount ?? this.hugCount,
    );
  }

  /// Firestore 用的純 Map。時間用 UTC ISO-8601，避免模型依賴 cloud_firestore。
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'emotion': emotion.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'isPublic': isPublic,
      'hugCount': hugCount,
    };
  }

  factory MindOrb.fromMap(Map<String, dynamic> map) {
    return MindOrb(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      emotion: EmotionType.values.byName(map['emotion'] as String),
      createdAt: _readDate(map['createdAt']),
      isPublic: map['isPublic'] as bool? ?? false,
      hugCount: (map['hugCount'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _readDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.parse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    throw FormatException('createdAt 格式無法辨識：$raw');
  }
}

class MindOrbAdapter extends TypeAdapter<MindOrb> {
  @override
  final int typeId = AppConstants.hiveMindOrbTypeId;

  @override
  MindOrb read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    final emotionIndex = fields[3];
    if (emotionIndex is! int ||
        emotionIndex < 0 ||
        emotionIndex >= EmotionType.values.length) {
      throw FormatException('未知的情緒索引：$emotionIndex');
    }
    final createdAt = fields[4];
    if (createdAt is! int) {
      throw FormatException('createdAt 不是毫秒時間');
    }
    return MindOrb(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      emotion: EmotionType.values[emotionIndex],
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      isPublic: fields[5] as bool? ?? false,
      hugCount: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, MindOrb obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.emotion.index)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.isPublic)
      ..writeByte(6)
      ..write(obj.hugCount);
  }
}
