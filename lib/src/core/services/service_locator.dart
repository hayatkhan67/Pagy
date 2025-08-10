class SimpleServiceLocator {
  static final SimpleServiceLocator _instance =
      SimpleServiceLocator._internal();
  factory SimpleServiceLocator() => _instance;
  SimpleServiceLocator._internal();

  final _services = <Type, dynamic>{};

  void register<T>(T instance) {
    _services[T] = instance;
  }

  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception("Service of type $T not found");
    }
    return service;
  }
}
