class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static dynamic get currentPlatform {
    throw UnsupportedError('Firebase is disabled in this MVP build.');
  }
}
