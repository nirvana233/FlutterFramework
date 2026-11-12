import 'dart:async';

class EventBusUtil {
  final _streamController = StreamController<dynamic>.broadcast();

  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  void fire(dynamic event) {
    if (_streamController.isClosed) {
      return;
    }
    _streamController.add(event);
  }

  void dispose() {
    if (_streamController.isClosed) {
      return;
    }
    _streamController.close();
  }
}
