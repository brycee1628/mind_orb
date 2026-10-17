import '../models/mind_orb.dart';
import 'firebase_service.dart';
import 'local_db_service.dart';

/// 心情的讀寫入口。本機一定先寫入；雲端已接通且心球標記放流時，才同步出去。
/// 雲端未接通時，放流旗標仍留在本機。[syncPendingPublicOrbs] 會在啟動時
/// 把已標記放流的心球補送到雲端。
class OrbRepository {
  const OrbRepository({required this.localDb, required this.firebase});

  final OrbLocalStore localDb;
  final FirebaseService firebase;

  bool get cloudEnabled => firebase.isCloudEnabled;

  List<MindOrb> getAllOrbs() => localDb.getAllOrbs();

  Future<void> saveOrb(MindOrb orb) async {
    final previous = localDb.getOrb(orb.id);
    await localDb.saveOrb(orb);
    if (!firebase.isCloudEnabled) return;
    if (orb.isPublic) {
      await firebase.publishOrb(orb);
      return;
    }
    if (previous?.isPublic ?? false) {
      await firebase.deleteOrb(orb.id);
    }
  }

  Future<void> deleteOrb(String id) async {
    final previous = localDb.getOrb(id);
    await localDb.deleteOrb(id);
    if (firebase.isCloudEnabled && (previous?.isPublic ?? false)) {
      await firebase.deleteOrb(id);
    }
  }

  Future<void> syncPendingPublicOrbs() async {
    if (!firebase.isCloudEnabled) return;
    for (final orb in localDb.getAllOrbs()) {
      if (orb.isPublic) {
        await firebase.publishOrb(orb);
      }
    }
  }

  Stream<List<MindOrb>> watchPublicOrbs() => firebase.getPublicOrbsStream();

  Future<void> sendHug(String orbId) => firebase.sendHug(orbId);
}
