import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:hoop/dtos/podos/exceptions/UnauthorizedException.dart';
import 'package:hoop/dtos/podos/exceptions/ValidationException.dart';
import 'package:hoop/dtos/podos/exceptions/networkExecption.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:http/http.dart' as http;

// Main Base HTTP Service
class BaseHttpService {
  final String baseUrl;
  final TokenManager? tokenManager = TokenManager.instance;
  final Duration timeoutDuration;
  final Map<String, String> defaultHeaders;

  BaseHttpService({
    required this.baseUrl,
    this.timeoutDuration = const Duration(seconds: 30),
    Map<String, String>? defaultHeaders,
  }) : defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (defaultHeaders != null) ...defaultHeaders,
        };

  // Request interceptor - called before each request
  Future<Map<String, String>> _interceptRequest({
    required Map<String, String> headers,
    bool requiresAuth = true,
  }) async {
    final interceptedHeaders = Map<String, String>.from(headers);

    // Add authorization token if required
    if (requiresAuth && tokenManager != null) {
      final token = await tokenManager!.getToken();
      if (token != null) {
        interceptedHeaders['Authorization'] = 'Bearer $token';
      }
    }

    return interceptedHeaders;
  }

  // Response interceptor - called after each response
  Future<http.Response> _interceptResponse(http.Response response) async {

    if (response.statusCode == 401) {
      // Token expired, try to refresh
      if (tokenManager != null) {
        try {
          await tokenManager!.getRefreshToken();
          // Retry the original request (you might want to implement retry logic here)
        } catch (e) {
          await tokenManager!.deleteToken();
          throw UnauthorizedException('Session expired. Please login again.');
        }
      } else {
        throw UnauthorizedException('Authentication required.');
      }
    }

    if (response.statusCode == 422) {
      // Validation errors
      final responseBody = json.decode(response.body);
      throw ValidationException(
        responseBody['message'] ?? 'Validation failed',
        errors: responseBody['errors'] != null
            ? Map<String, dynamic>.from(responseBody['errors'])
            : null,
      );
    }

    if (response.statusCode >= 400) {
      // Handle other errors
      final responseBody = json.decode(response.body);
      throw NetworkException(
        responseBody['message'] ?? 'An error occurred',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  // Generic request method
  Future<http.Response> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      // Build URL with query parameters
      var url = '$baseUrl/$endpoint';
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...queryParameters.map((key, value) => MapEntry(key, value.toString())),
        }).toString();
      }

      // Prepare headers
      final requestHeaders = await _interceptRequest(
        headers: {
          ...defaultHeaders,
          if (headers != null) ...headers,
        },
        requiresAuth: requiresAuth,
      );

      final request = http.Request(method, Uri.parse(url));

      // Set headers
      request.headers.addAll(requestHeaders);

      // Set body for POST, PUT, PATCH
      if (body != null && ['POST', 'PUT', 'PATCH'].contains(method.toUpperCase())) {
        request.body = json.encode(body);
      }

      // Send request
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      // Intercept and process response
      return await _interceptResponse(response);
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out');
    } on FormatException catch (_) {
      throw NetworkException('Invalid response format');
    } catch (e) {
      if (e is NetworkException || e is UnauthorizedException || e is ValidationException) {
        rethrow;
      }
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  // Convenience methods
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _request(
      'GET',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _request(
      'POST',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _request(
      'PUT',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _request(
      'PATCH',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _request(
      'DELETE',
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  // ========== TYPED METHODS ==========

  Future<ApiResponse<T>> getTyped<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final response = await get(
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
log("response?? $response");
    return _parseTypedResponse<T>(response, fromJson);
  }

  Future<ApiResponse<T>> postTyped<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final response = await post(
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );

    return _parseTypedResponse<T>(response, fromJson);
  }

  // ADDED: putTyped method
  Future<ApiResponse<T>> putTyped<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final response = await put(
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );

    return _parseTypedResponse<T>(response, fromJson);
  }

  // ADDED: patchTyped method
  Future<ApiResponse<T>> patchTyped<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final response = await patch(
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );

    return _parseTypedResponse<T>(response, fromJson);
  }

  // ADDED: deleteTyped method
  Future<ApiResponse<T>> deleteTyped<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final response = await delete(
      endpoint,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );

    return _parseTypedResponse<T>(response, fromJson);
  }

  // Parse typed response
  ApiResponse<T> _parseTypedResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    final responseBody = json.decode(response.body);
    
    T? parsedData;
    if (fromJson != null && responseBody['data'] != null) {
      parsedData = fromJson(responseBody['data']);
    } else if (responseBody['data'] != null) {
      parsedData = responseBody['data'] as T;
    }

    return ApiResponse<T>(
      success: response.statusCode >= 200 && response.statusCode < 300,
      data: parsedData,
      message: responseBody['message'],
      error: responseBody['error'],
      statusCode: response.statusCode,
    );
  }

 Future<http.Response> uploadFile(
  String endpoint,
  List<int> fileBytes,
  String fileName, {
  Map<String, String>? fields,
  Map<String, String>? headers,
  bool requiresAuth = true,
  void Function(double progress)? onProgress, // Changed to accept percentage
}) async {
  try {
    var url = '$baseUrl/$endpoint';
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add file
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    // Add fields
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
    }

    // Add headers
    final requestHeaders = await _interceptRequest(
      headers: {
        ...defaultHeaders,
        if (headers != null) ...headers,
      },
      requiresAuth: requiresAuth,
    );

    requestHeaders.remove('Content-Type'); // Remove for multipart
    request.headers.addAll(requestHeaders);

    // Track progress if callback is provided
    final totalBytes = request.contentLength ?? fileBytes.length;
    int sentBytes = 0;
    final streamedRequest = request.send();

    if (onProgress != null) {
      // Wrap the stream to track progress
      final streamedResponse = await streamedRequest.timeout(timeoutDuration);
      
      // Create a new stream that tracks progress
      final List<int> bytes = [];
      await for (var chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        sentBytes += chunk.length;
        
        // Calculate and report progress percentage
        final progress = (sentBytes / totalBytes * 100).clamp(0, 100).toDouble();
        onProgress(progress);
      }
      
      // Create response from accumulated bytes
      final response = http.Response.bytes(
        bytes,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: http.Request(
          'POST',
          Uri.parse(url),
        ),
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
      
      return await _interceptResponse(response);
    } else {
      // Original behavior without progress tracking
      final streamedResponse = await streamedRequest.timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      return await _interceptResponse(response);
    }
  } on TimeoutException catch (_) {
    throw NetworkException('Upload timed out');
  } catch (e) {
    if (e is NetworkException || e is UnauthorizedException || e is ValidationException) {
      rethrow;
    }
    throw NetworkException('Upload failed: ${e.toString()}');
  }
}

  // ADDED: Typed file upload method
  Future<ApiResponse<T>> uploadFileTyped<T>(
    String endpoint,
    List<int> fileBytes,
    String fileName, {
    Map<String, String>? fields,
    T Function(dynamic)? fromJson,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final response = await uploadFile(
      endpoint,
      fileBytes,
      fileName,
      fields: fields,
      headers: headers,
      requiresAuth: requiresAuth,
    );

    return _parseTypedResponse<T>(response, fromJson);
  }
}