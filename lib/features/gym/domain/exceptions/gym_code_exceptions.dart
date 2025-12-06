// lib/features/gym/domain/exceptions/gym_code_exceptions.dart

/// Base exception for gym code related errors
abstract class GymCodeException implements Exception {
  final String message;
  const GymCodeException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a gym code is not found
class GymCodeNotFoundException extends GymCodeException {
  const GymCodeNotFoundException([
    String message = 'Gym code not found. Please check the code and try again.',
  ]) : super(message);
}

/// Thrown when a gym code has expired
class GymCodeExpiredException extends GymCodeException {
  final DateTime expiredAt;
  final String? gymName;

  const GymCodeExpiredException({
    required this.expiredAt,
    this.gymName,
    String message = 'This gym code has expired. Please get the current code from your gym.',
  }) : super(message);

  @override
  String toString() {
    final gymInfo = gymName != null ? ' for $gymName' : '';
    final expiredDate = expiredAt.toString().split(' ')[0];
    return '$message$gymInfo (expired on $expiredDate)';
  }
}

/// Thrown when a gym code is inactive
class GymCodeInactiveException extends GymCodeException {
  const GymCodeInactiveException([
    String message = 'This gym code is no longer active.',
  ]) : super(message);
}

/// Thrown when too many validation attempts are made
class TooManyAttemptsException extends GymCodeException {
  final int waitSeconds;

  const TooManyAttemptsException({
    this.waitSeconds = 30,
    String message = 'Too many attempts. Please wait before trying again.',
  }) : super(message);

  @override
  String toString() => '$message (wait $waitSeconds seconds)';
}

/// Thrown when code format is invalid
class InvalidCodeFormatException extends GymCodeException {
  const InvalidCodeFormatException([
    String message = 'Invalid code format. Code must be 6 characters.',
  ]) : super(message);
}
