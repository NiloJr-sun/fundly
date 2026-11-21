/// "Good morning", "Good afternoon" or "Good evening" for a local time:
/// morning from 05:00, afternoon from 12:00, evening from 18:00 until 05:00.
String greetingFor(DateTime localTime) {
  final hour = localTime.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  return 'Good evening';
}
