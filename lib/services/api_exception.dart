import 'package:dio/dio.dart';

/// Field-level validation error returned by the API.
class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

/// A user-safe error produced by the API layer.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.details = const []});

  final String message;
  final int? statusCode;
  final List<ApiFieldError> details;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Could not reach the MealMate server. Check your connection and '
          'make sure the API is running.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'The server certificate could not be verified.',
        );
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        return ApiException(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Something went wrong. Please try again.',
        );
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    var message =
        'The server returned an error'
        '${statusCode != null ? ' ($statusCode)' : ''}.';
    var details = const <ApiFieldError>[];

    final body = response?.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);

      final rawMessage = map['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage.trim();
      }

      final rawDetails = map['details'];
      if (rawDetails is List) {
        details = rawDetails
            .whereType<Map>()
            .map(
              (item) => ApiFieldError(
                field: item['field']?.toString() ?? '',
                message: item['message']?.toString() ?? '',
              ),
            )
            .toList(growable: false);
      }
    }

    return ApiException(message, statusCode: statusCode, details: details);
  }

  @override
  String toString() => message;
}
