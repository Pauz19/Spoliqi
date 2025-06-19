class AppNotification {
  final String key; // Localization key
  final List<String> args; // Arguments for the key
  final DateTime time;
  final String? legacyMessage; // For backward compatibility (optional)

  AppNotification({
    required this.key,
    required this.args,
    required this.time,
    this.legacyMessage,
  });
}