import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mind_orb/models/mind_orb.dart';
import 'package:mind_orb/services/firebase_service.dart';
import 'package:mind_orb/services/local_db_service.dart';
import 'package:mind_orb/services/orb_repository.dart';
import 'package:mind_orb/viewmodels/orb_provider.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mind_orb_store_');
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('關閉 box 再打開，心情仍在磁碟上', () async {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final orb = MindOrb(
      id: 'orb-1',
      title: '留下',
      content: '關掉之後還在',
      emotion: EmotionType.sadness,
      createdAt: created,
      isPublic: true,
      hugCount: 3,
    );

    final local = LocalDbService();
    await local.init(storagePath: dir.path);
    await local.saveOrb(orb);
    await local.close();

    final hiveFile = File(
      '${dir.path}${Platform.pathSeparator}mind_orbs_box.hive',
    );
    expect(hiveFile.existsSync(), isTrue);
    expect(hiveFile.lengthSync(), greaterThan(0));

    final reopened = LocalDbService();
    await reopened.init(storagePath: dir.path);
    final loaded = reopened.getAllOrbs().single;
    expect(loaded.id, orb.id);
    expect(loaded.title, '留下');
    expect(loaded.content, '關掉之後還在');
    expect(loaded.emotion, EmotionType.sadness);
    expect(loaded.createdAt, created);
    expect(loaded.isPublic, isTrue);
    expect(loaded.hugCount, 3);

    await reopened.deleteOrb(orb.id);
    await reopened.close();

    final afterDelete = LocalDbService();
    await afterDelete.init(storagePath: dir.path);
    expect(afterDelete.getAllOrbs(), isEmpty);
    await afterDelete.close();
  });

  test('新的 Provider 從同一份 Hive 讀回上一輪寫入', () async {
    final local = LocalDbService();
    await local.init(storagePath: dir.path);
    final repository = OrbRepository(
      localDb: local,
      firebase: const Phase1FirebaseService(),
    );
    final first = OrbProvider(repository);
    await first.createOrb(
      title: '  夜裡  ',
      content: '  還在  ',
      emotion: EmotionType.calm,
      isPublic: true,
    );

    await local.close();
    final reopened = LocalDbService();
    await reopened.init(storagePath: dir.path);
    final second = OrbProvider(
      OrbRepository(
        localDb: reopened,
        firebase: const Phase1FirebaseService(),
      ),
    );
    await second.load();

    expect(second.cloudEnabled, isFalse);
    expect(second.orbs, hasLength(1));
    expect(second.orbs.single.title, '夜裡');
    expect(second.orbs.single.content, '還在');
    expect(second.orbs.single.emotion, EmotionType.calm);
    expect(second.orbs.single.isPublic, isTrue);
    await reopened.close();
  });

  test('雲端未接通時只寫本機；接通後才雙寫並補送', () async {
    final local = LocalDbService();
    await local.init(storagePath: dir.path);
    final offline = RecordingFirebaseService(cloudEnabled: false);
    final offlineRepo = OrbRepository(localDb: local, firebase: offline);
    final publicOrb = _sample(id: 'public', isPublic: true);
    final privateOrb = _sample(id: 'private');

    await offlineRepo.saveOrb(publicOrb);
    await offlineRepo.saveOrb(privateOrb);
    await offlineRepo.syncPendingPublicOrbs();
    await offlineRepo.deleteOrb(privateOrb.id);

    expect(offline.published, isEmpty);
    expect(offline.deleted, isEmpty);
    expect(local.getAllOrbs().map((orb) => orb.id).toList(), ['public']);
    expect(local.getOrb('public')!.isPublic, isTrue);

    final online = RecordingFirebaseService(cloudEnabled: true);
    final onlineRepo = OrbRepository(localDb: local, firebase: online);
    await onlineRepo.syncPendingPublicOrbs();
    expect(online.published.map((orb) => orb.id), ['public']);

    await onlineRepo.saveOrb(publicOrb.copyWith(isPublic: false, title: '收回來'));
    expect(online.deleted, ['public']);
    expect(local.getOrb('public')!.isPublic, isFalse);

    await onlineRepo.saveOrb(publicOrb.copyWith(isPublic: true));
    await onlineRepo.deleteOrb('public');
    expect(online.deleted, ['public', 'public']);
    expect(local.getAllOrbs(), isEmpty);
    await local.close();
  });

  test('toMap 與 fromMap 保留雲端同步欄位', () {
    final orb = _sample(id: 'map-1', isPublic: true, hugCount: 2);
    final restored = MindOrb.fromMap(orb.toMap());
    expect(restored.id, orb.id);
    expect(restored.title, orb.title);
    expect(restored.content, orb.content);
    expect(restored.emotion, orb.emotion);
    expect(restored.createdAt.toUtc(), orb.createdAt.toUtc());
    expect(restored.isPublic, isTrue);
    expect(restored.hugCount, 2);
    expect(orb.toMap()['emotion'], 'joy');
  });

  test('未連線的雲端服務不拋出', () async {
    const remote = Phase1FirebaseService();
    expect(remote.isCloudEnabled, isFalse);
    await remote.publishOrb(_sample(isPublic: true));
    await remote.deleteOrb('orb-1');
    await remote.sendHug('orb-1');
    await expectLater(remote.getPublicOrbsStream(), emitsDone);
  });
}

MindOrb _sample({
  String id = 'orb-1',
  bool isPublic = false,
  int hugCount = 0,
}) {
  return MindOrb(
    id: id,
    title: '留下',
    content: '關掉之後還在',
    emotion: EmotionType.joy,
    createdAt: DateTime.utc(2026, 10, 18, 12),
    isPublic: isPublic,
    hugCount: hugCount,
  );
}

class RecordingFirebaseService implements FirebaseService {
  RecordingFirebaseService({required this.cloudEnabled});

  final bool cloudEnabled;
  final published = <MindOrb>[];
  final deleted = <String>[];

  @override
  bool get isCloudEnabled => cloudEnabled;

  @override
  Future<void> publishOrb(MindOrb orb) async {
    published.add(orb);
  }

  @override
  Future<void> deleteOrb(String orbId) async {
    deleted.add(orbId);
  }

  @override
  Stream<List<MindOrb>> getPublicOrbsStream() => Stream.value(const []);

  @override
  Future<void> sendHug(String orbId) async {}
}
