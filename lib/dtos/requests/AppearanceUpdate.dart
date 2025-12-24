// Appearance update model
class AppearanceUpdate {
  final String appearance;

  AppearanceUpdate({required this.appearance});

  Map<String, dynamic> toJson() {
    return {'appearance': appearance};
  }
}
