import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/local_db_service.dart';
import 'services/orb_repository.dart';
import 'viewmodels/orb_provider.dart';
import 'views/screens/personal_orbit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localDb = LocalDbService();
  await localDb.init();
  // 雲端服務的組裝點。目前注入的實作不連網。
  const firebase = Phase1FirebaseService();
  final repository = OrbRepository(localDb: localDb, firebase: firebase);
  runApp(MindOrbApp(repository: repository));
}

class MindOrbApp extends StatelessWidget {
  const MindOrbApp({super.key, required this.repository});

  final OrbRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrbProvider(repository)..load(),
      child: MaterialApp(
        title: '心球',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const PersonalOrbitScreen(),
      ),
    );
  }
}
