// lib/features/gym/domain/usecases/validate_gym_code.dart
import '../models/gym_code_validation_result.dart';
import '../services/gym_code_service.dart';
import '../exceptions/gym_code_exceptions.dart';

export '../exceptions/gym_code_exceptions.dart';
export '../models/gym_code_validation_result.dart';

/// Use case for validating gym registration codes
/// 
/// This validates rotating gym codes that expire monthly.
/// Throws specific exceptions for different failure cases.
class ValidateGymCode {
  final GymCodeService _service;

  ValidateGymCode([GymCodeService? service])
      : _service = service ?? GymCodeService();

  /// Validate a gym code and return gym information
  /// 
  /// Throws:
  /// - [GymCodeNotFoundException] if code doesn't exist
  /// - [GymCodeExpiredException] if code has expired
  /// - [GymCodeInactiveException] if code is deactivated
  /// - [InvalidCodeFormatException] if code format is invalid
  Future<GymCodeValidationResult> execute(String code) async {
    return await _service.validateCode(code);
  }
}
