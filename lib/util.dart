int getUnixTimeInSeconds() {
  final now = DateTime.now();
  return now.millisecondsSinceEpoch ~/ 1000;
}
