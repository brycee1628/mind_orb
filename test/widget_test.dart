import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_orb/main.dart';
import 'package:mind_orb/models/mind_orb.dart';
import 'package:mind_orb/services/firebase_service.dart';
import 'package:mind_orb/services/local_db_service.dart';
import 'package:mind_orb/services/orb_repository.dart';

void main() {
  testWidgets('按發射後回到星系，記憶庫看得到這顆心球', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MindOrbApp(
        repository: OrbRepository(
          localDb: MemoryOrbStore(),
          firebase: const Phase1FirebaseService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('星海還是空的'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('orb-title')), '今天很好');
    await tester.enterText(find.byKey(const Key('orb-content')), '想被留下來');
    await tester.ensureVisible(find.byKey(const Key('submit-orb')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit-orb')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('心情發射台'), findsNothing, reason: _visibleText(tester));
    expect(find.text('個人星系'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-vault')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('個人記憶庫'), findsOneWidget);
    expect(find.text('今天很好'), findsOneWidget);
    expect(find.textContaining('快樂'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _visibleText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .join(' | ');
}

class MemoryOrbStore implements OrbLocalStore {
  final Map<String, MindOrb> _items = {};

  @override
  Future<void> saveOrb(MindOrb orb) async {
    _items[orb.id] = orb;
  }

  @override
  List<MindOrb> getAllOrbs() => _items.values.toList();

  @override
  MindOrb? getOrb(String id) => _items[id];

  @override
  Future<void> deleteOrb(String id) async {
    _items.remove(id);
  }
}
