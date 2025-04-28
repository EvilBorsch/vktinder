import 'package:hive/hive.dart';

part 'skipped_user_ids.g.dart';

@HiveType(typeId: 3)
class HiveSkippedUserIds extends HiveObject {
  @HiveField(0)
  final List<String> userIds;

  HiveSkippedUserIds({
    required this.userIds,
  });

  // Convert from regular Set<String>
  factory HiveSkippedUserIds.fromSet(Set<String> userIds) {
    return HiveSkippedUserIds(userIds: userIds.toList());
  }

  // Convert to regular Set<String>
  Set<String> toSet() {
    return Set<String>.from(userIds);
  }
}
