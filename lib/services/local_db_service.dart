import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/constants.dart';
import '../models/mind_orb.dart';

/// 本機心情儲存。正式環境用 Hive，測試可換記憶體實作。
abstract class OrbLocalStore {
  Future<void> saveOrb(MindOrb orb);

  List<MindOrb> getAllOrbs();

  MindOrb? getOrb(String id);

  Future<void> deleteOrb(String id);
}

/// 本機 box `mind_orbs_box`。
///
/// 正式啟動寫入 App 文件目錄，程序結束後仍在。
/// 測試可傳 [storagePath]，改寫到指定資料夾。
class LocalDbService implements OrbLocalStore {
  Box<MindOrb>? _box;

  Future<void> init({String? storagePath}) async {
    if (storagePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(storagePath);
    }
    if (!Hive.isAdapterRegistered(AppConstants.hiveMindOrbTypeId)) {
      Hive.registerAdapter(MindOrbAdapter());
    }
    _box = await Hive.openBox<MindOrb>(AppConstants.mindOrbsBox);
  }

  @override
  Future<void> saveOrb(MindOrb orb) async {
    final box = _orbs;
    await box.put(orb.id, orb);
    await box.flush();
  }

  @override
  List<MindOrb> getAllOrbs() => _orbs.values.toList();

  @override
  MindOrb? getOrb(String id) => _orbs.get(id);

  @override
  Future<void> deleteOrb(String id) async {
    final box = _orbs;
    await box.delete(id);
    await box.flush();
  }

  Future<void> close() async {
    final box = _box;
    if (box != null && box.isOpen) {
      await box.close();
    }
    _box = null;
  }

  Box<MindOrb> get _orbs {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('LocalDbService 尚未初始化');
    }
    return box;
  }
}
