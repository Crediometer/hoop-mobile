// lib/constants/operation_status.dart
class OperationStatus {
  final int value;
  final String message;

  const OperationStatus._(this.value, this.message);

  // 2xx - Success
  static const OK = OperationStatus._(200, 'OK');
  static const CREATED = OperationStatus._(201, 'Created');
  static const ACCEPTED = OperationStatus._(202, 'Accepted');
  static const NO_CONTENT = OperationStatus._(204, 'No Content');

  // 3xx - Redirection
  static const MOVED_PERMANENTLY = OperationStatus._(301, 'Moved Permanently');
  static const FOUND = OperationStatus._(302, 'Found');
  static const SEE_OTHER = OperationStatus._(303, 'See Other');
  static const NOT_MODIFIED = OperationStatus._(304, 'Not Modified');
  static const TEMPORARY_REDIRECT = OperationStatus._(307, 'Temporary Redirect');
  static const PERMANENT_REDIRECT = OperationStatus._(308, 'Permanent Redirect');

  // 4xx - Client Errors
  static const BAD_REQUEST = OperationStatus._(400, 'Bad Request');
  static const UNAUTHORIZED = OperationStatus._(401, 'Unauthorized');
  static const PAYMENT_REQUIRED = OperationStatus._(402, 'Payment Required');
  static const FORBIDDEN = OperationStatus._(403, 'Forbidden');
  static const NOT_FOUND = OperationStatus._(404, 'Not Found');
  static const METHOD_NOT_ALLOWED = OperationStatus._(405, 'Method Not Allowed');
  static const NOT_ACCEPTABLE = OperationStatus._(406, 'Not Acceptable');
  static const CONFLICT = OperationStatus._(409, 'Conflict');
  static const GONE = OperationStatus._(410, 'Gone');
  static const PAYLOAD_TOO_LARGE = OperationStatus._(413, 'Payload Too Large');
  static const UNSUPPORTED_MEDIA_TYPE = OperationStatus._(415, 'Unsupported Media Type');
  static const TOO_MANY_REQUESTS = OperationStatus._(429, 'Too Many Requests');

  // 5xx - Server Errors
  static const INTERNAL_SERVER_ERROR = OperationStatus._(500, 'Internal Server Error');
  static const NOT_IMPLEMENTED = OperationStatus._(501, 'Not Implemented');
  static const BAD_GATEWAY = OperationStatus._(502, 'Bad Gateway');
  static const SERVICE_UNAVAILABLE = OperationStatus._(503, 'Service Unavailable');
  static const GATEWAY_TIMEOUT = OperationStatus._(504, 'Gateway Timeout');

  // List of all statuses for iteration
  static const List<OperationStatus> values = [
    // Success
    OK,
    CREATED,
    ACCEPTED,
    NO_CONTENT,
    
    // Redirection
    MOVED_PERMANENTLY,
    FOUND,
    SEE_OTHER,
    NOT_MODIFIED,
    TEMPORARY_REDIRECT,
    PERMANENT_REDIRECT,
    
    // Client Errors
    BAD_REQUEST,
    UNAUTHORIZED,
    PAYMENT_REQUIRED,
    FORBIDDEN,
    NOT_FOUND,
    METHOD_NOT_ALLOWED,
    NOT_ACCEPTABLE,
    CONFLICT,
    GONE,
    PAYLOAD_TOO_LARGE,
    UNSUPPORTED_MEDIA_TYPE,
    TOO_MANY_REQUESTS,
    
    // Server Errors
    INTERNAL_SERVER_ERROR,
    NOT_IMPLEMENTED,
    BAD_GATEWAY,
    SERVICE_UNAVAILABLE,
    GATEWAY_TIMEOUT,
  ];

  // Factory method to create from value
  static OperationStatus fromValue(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => OperationStatus.OK,
    );
  }

  // Static method for firstWhere (as in your example)
  static OperationStatus firstWhere(bool Function(OperationStatus) test, 
      {required OperationStatus Function() orElse}) {
    return values.firstWhere(test, orElse: orElse);
  }

  // Helper methods
  bool get isSuccess => value >= 200 && value < 300;
  bool get isRedirection => value >= 300 && value < 400;
  bool get isClientError => value >= 400 && value < 500;
  bool get isServerError => value >= 500 && value < 600;
  bool get isError => isClientError || isServerError;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OperationStatus && other.value == value);
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'OperationStatus($value: $message)';

  // For backward compatibility - static helper methods
  static bool isSuccessCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static bool isRedirectionCode(int statusCode) {
    return statusCode >= 300 && statusCode < 400;
  }

  static bool isClientErrorCode(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  static bool isServerErrorCode(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }

  static bool isErrorCode(int statusCode) {
    return isClientErrorCode(statusCode) || isServerErrorCode(statusCode);
  }

  static String getMessage(int statusCode) {
    return fromValue(statusCode).message;
  }
}