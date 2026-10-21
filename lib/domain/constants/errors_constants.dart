class ErrorsConstants {
  static const String unauthorized = 'unauthorized';
  static const String unknownError = "unknownError";
  static const String noInternet = "noInternet";
  static const String timeout = "timeout";

  static const String noUserFound = "noUserFound";

  static bool existsKey(String key) {
    return [
      unauthorized,
      unknownError,
      noInternet,
      timeout,
      noUserFound,
    ].contains(key);
  }
}
