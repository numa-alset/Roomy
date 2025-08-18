class Env {
  static String get backendBase => const String.fromEnvironment('BACKEND_URL',
      defaultValue: 'http://10.0.2.2:3001');
  static String get stunUrl => const String.fromEnvironment('STUN_URL',
      defaultValue: 'stun:stun.l.google.com:19302');
}
