// lib/constants/operation_status.dart
class OperationStatus {
  // 2xx - Success
  static const int OK = 200;
  static const int CREATED = 201;
  static const int ACCEPTED = 202;
  static const int NO_CONTENT = 204;

  // 3xx - Redirection
  static const int MOVED_PERMANENTLY = 301;
  static const int FOUND = 302;
  static const int SEE_OTHER = 303;
  static const int NOT_MODIFIED = 304;
  static const int TEMPORARY_REDIRECT = 307;
  static const int PERMANENT_REDIRECT = 308;

  // 4xx - Client Errors
  static const int BAD_REQUEST = 400;
  static const int UNAUTHORIZED = 401;
  static const int PAYMENT_REQUIRED = 402;
  static const int FORBIDDEN = 403;
  static const int NOT_FOUND = 404;
  static const int METHOD_NOT_ALLOWED = 405;
  static const int NOT_ACCEPTABLE = 406;
  static const int CONFLICT = 409;
  static const int GONE = 410;
  static const int PAYLOAD_TOO_LARGE = 413;
  static const int UNSUPPORTED_MEDIA_TYPE = 415;
  static const int TOO_MANY_REQUESTS = 429;

  // 5xx - Server Errors
  static const int INTERNAL_SERVER_ERROR = 500;
  static const int NOT_IMPLEMENTED = 501;
  static const int BAD_GATEWAY = 502;
  static const int SERVICE_UNAVAILABLE = 503;
  static const int GATEWAY_TIMEOUT = 504;

  // Helper methods
  static bool isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static bool isRedirection(int statusCode) {
    return statusCode >= 300 && statusCode < 400;
  }

  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  static bool isServerError(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }

  static bool isError(int statusCode) {
    return isClientError(statusCode) || isServerError(statusCode);
  }

  static String getMessage(int statusCode) {
    switch (statusCode) {
      case OK:
        return 'OK';
      case CREATED:
        return 'Created';
      case ACCEPTED:
        return 'Accepted';
      case NO_CONTENT:
        return 'No Content';
      case MOVED_PERMANENTLY:
        return 'Moved Permanently';
      case FOUND:
        return 'Found';
      case SEE_OTHER:
        return 'See Other';
      case NOT_MODIFIED:
        return 'Not Modified';
      case TEMPORARY_REDIRECT:
        return 'Temporary Redirect';
      case PERMANENT_REDIRECT:
        return 'Permanent Redirect';
      case BAD_REQUEST:
        return 'Bad Request';
      case UNAUTHORIZED:
        return 'Unauthorized';
      case PAYMENT_REQUIRED:
        return 'Payment Required';
      case FORBIDDEN:
        return 'Forbidden';
      case NOT_FOUND:
        return 'Not Found';
      case METHOD_NOT_ALLOWED:
        return 'Method Not Allowed';
      case NOT_ACCEPTABLE:
        return 'Not Acceptable';
      case CONFLICT:
        return 'Conflict';
      case GONE:
        return 'Gone';
      case PAYLOAD_TOO_LARGE:
        return 'Payload Too Large';
      case UNSUPPORTED_MEDIA_TYPE:
        return 'Unsupported Media Type';
      case TOO_MANY_REQUESTS:
        return 'Too Many Requests';
      case INTERNAL_SERVER_ERROR:
        return 'Internal Server Error';
      case NOT_IMPLEMENTED:
        return 'Not Implemented';
      case BAD_GATEWAY:
        return 'Bad Gateway';
      case SERVICE_UNAVAILABLE:
        return 'Service Unavailable';
      case GATEWAY_TIMEOUT:
        return 'Gateway Timeout';
      default:
        return 'Unknown Status Code';
    }
  }
}