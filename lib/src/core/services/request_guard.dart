import 'package:dio/dio.dart';

/// Manages request cancellation and ensures only latest response is applied.
class RequestGuard {
  int _lastRequestId = 0;
  CancelToken? _cancelToken;

  /// Returns a new [CancelToken] and increments requestId
  (int, CancelToken) newRequest() {
    _cancelToken?.cancel("Cancelled due to new request");
    _cancelToken = CancelToken();
    _lastRequestId++;
    return (_lastRequestId, _cancelToken!);
  }

  /// Checks if this request is still the latest
  bool isLatest(int requestId) => requestId == _lastRequestId;

  /// Cancel current request (if any)
  void cancelCurrent() {
    _cancelToken?.cancel("Cancelled by user");
  }
}
