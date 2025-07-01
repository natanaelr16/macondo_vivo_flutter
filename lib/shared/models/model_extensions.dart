import 'user_model.dart';
import 'activity_model.dart';

// Extensions to add missing getters for backward compatibility
extension UserModelExtensions on UserModel {
  String get id => uid;
  String get role => appRole.name;
}

extension ActivityModelExtensions on ActivityModel {
  String get id => activityId;
  String get createdBy => createdBy_uid;
  String get type => category ?? 'general';
} 