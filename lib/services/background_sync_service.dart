import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';
import 'offline_emergency_service.dart';

const _kSyncTask = 'muhafiz_sync_task';
const _kSyncName = 'sync_emergency_data';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _kSyncName) {
      try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        await OfflineEmergencyService.syncAll();
      } catch (_) {}
    }
    return true;
  });
}

class BackgroundSyncService {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  /// Register a one-off background task that runs once connectivity is restored.
  static void scheduleSync() {
    Workmanager().registerOneOffTask(
      _kSyncTask,
      _kSyncName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
