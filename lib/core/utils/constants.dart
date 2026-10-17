abstract final class AppConstants {
  static const mindOrbsBox = 'mind_orbs_box';
  static const publicOrbsCollection = 'public_orbs';
  static const maxTitleLength = 20;
  static const maxContentLength = 500;

  /// Hive TypeId。已寫進使用者裝置後不可更改。
  static const hiveMindOrbTypeId = 0;
}

String formatOrbTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
