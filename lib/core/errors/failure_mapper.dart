import 'package:supabase_flutter/supabase_flutter.dart';
import '../result/result.dart';

class FailureMapper {
  static AppFailure from(Object error) {
    if (error is AuthException) {
      return AuthFailure(error.message, cause: error);
    }
    if (error is PostgrestException) {
      return DbFailure(error.message, cause: error);
    }
    if (error is StorageException) {
      return StorageFailure(error.message, cause: error);
    }
    return UnknownFailure('Erro inesperado', cause: error);
  }
}
