import '../models/mind_orb.dart';

/// 雲端星海的存取合約。畫面只經由 [OrbRepository] 使用它。
///
/// [Phase1FirebaseService] 不連上網路，呼叫後直接結束。
/// 接上 Firestore 時，文件放在 `public_orbs`，
/// 時間先轉成 DateTime 再交給 [MindOrb.fromMap]。
abstract class FirebaseService {
  bool get isCloudEnabled;

  Future<void> publishOrb(MindOrb orb);

  Future<void> deleteOrb(String orbId);

  Stream<List<MindOrb>> getPublicOrbsStream();

  Future<void> sendHug(String orbId);
}

class Phase1FirebaseService implements FirebaseService {
  const Phase1FirebaseService();

  @override
  bool get isCloudEnabled => false;

  @override
  Future<void> publishOrb(MindOrb orb) {
    _requireId(orb.id);
    return Future<void>.value();
  }

  @override
  Future<void> deleteOrb(String orbId) {
    _requireId(orbId);
    return Future<void>.value();
  }

  @override
  Stream<List<MindOrb>> getPublicOrbsStream() {
    return const Stream<List<MindOrb>>.empty();
  }

  @override
  Future<void> sendHug(String orbId) {
    _requireId(orbId);
    return Future<void>.value();
  }

  void _requireId(String id) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', '不可為空');
    }
  }
}
