enum Environment {
  dev,
  prod,
}

class AppConfig {
  static Environment _environment = Environment.dev;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.dev:
        return 'http://127.0.0.1:3000/api';
      case Environment.prod:
        return 'https://api.arogyam.com/api'; // Placeholder
    }
  }
}
