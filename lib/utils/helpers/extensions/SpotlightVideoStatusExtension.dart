


// Additional helper methods
import 'package:hoop/dtos/podos/enums/SpotlightVideoStatus.dart';

extension SpotlightVideoStatusExtension on SpotlightVideoStatus {
  String get name {
    switch (this) {
      case SpotlightVideoStatus.active: return 'ACTIVE';
      case SpotlightVideoStatus.inactive: return 'INACTIVE';
      case SpotlightVideoStatus.pending: return 'PENDING';
    }
  }

  String get displayName {
    switch (this) {
      case SpotlightVideoStatus.active: return 'Active';
      case SpotlightVideoStatus.inactive: return 'Inactive';
      case SpotlightVideoStatus.pending: return 'Pending';
    }
  }
}