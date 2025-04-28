import 'package:hive_flutter/hive_flutter.dart';
import 'package:vktinder/data/models/hive/statistics_user_action.dart';
import 'package:vktinder/data/models/hive/vk_group_user.dart';
import 'package:vktinder/data/models/hive/skipped_user_ids.dart';

class HiveAdapters {
  static void registerAdapters() {
    // Register adapters if they haven't been registered yet
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HiveStatisticsUserActionAdapter());
    }
    
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HiveVKGroupUserAdapter());
    }
    
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HiveSkippedUserIdsAdapter());
    }
  }
}