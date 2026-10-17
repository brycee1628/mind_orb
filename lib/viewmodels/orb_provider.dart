import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/constants.dart';
import '../models/mind_orb.dart';
import '../services/orb_repository.dart';

class OrbProvider extends ChangeNotifier {
  OrbProvider(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final OrbRepository _repository;
  final Uuid _uuid;

  List<MindOrb> _orbs = const [];
  bool _ready = false;
  String? _errorMessage;

  List<MindOrb> get orbs => _orbs;
  bool get isReady => _ready;
  String? get errorMessage => _errorMessage;
  bool get cloudEnabled => _repository.cloudEnabled;

  Future<void> load() async {
    try {
      await _repository.syncPendingPublicOrbs();
      _orbs = _sorted(_repository.getAllOrbs());
      _errorMessage = null;
    } catch (error) {
      _errorMessage = '讀取心情時發生問題：$error';
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<MindOrb> createOrb({
    required String title,
    required String content,
    required EmotionType emotion,
    required bool isPublic,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', '標題不可為空');
    }
    if (trimmedTitle.length > AppConstants.maxTitleLength) {
      throw ArgumentError.value(title, 'title', '標題最多 20 字');
    }
    if (trimmedContent.length > AppConstants.maxContentLength) {
      throw ArgumentError.value(content, 'content', '內文最多 500 字');
    }

    final orb = MindOrb(
      id: _uuid.v4(),
      title: trimmedTitle,
      content: trimmedContent,
      emotion: emotion,
      createdAt: DateTime.now(),
      isPublic: isPublic,
    );
    await _repository.saveOrb(orb);
    _orbs = _sorted([orb, ..._orbs]);
    _errorMessage = null;
    notifyListeners();
    return orb;
  }

  Future<void> deleteOrb(String id) async {
    await _repository.deleteOrb(id);
    _orbs = List.unmodifiable(_orbs.where((orb) => orb.id != id));
    notifyListeners();
  }

  Stream<List<MindOrb>> watchPublicOrbs() => _repository.watchPublicOrbs();

  Future<void> sendHug(String orbId) => _repository.sendHug(orbId);

  List<MindOrb> _sorted(Iterable<MindOrb> orbs) {
    final copy = orbs.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(copy);
  }
}
