import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';

enum PetitionStatus { notStarted, loading, complete, failed }

class PetitionStatusEntity<T> {
  PetitionStatus status;
  T? data;
  String? error;

  PetitionStatusEntity({
    this.status = PetitionStatus.loading,
    this.data,
    this.error,
  });

  PetitionStatusEntity.notStarted() : status = PetitionStatus.notStarted;

  factory PetitionStatusEntity.success({T? data}) {
    return PetitionStatusEntity(status: PetitionStatus.complete, data: data);
  }

  factory PetitionStatusEntity.loading() {
    return PetitionStatusEntity(status: PetitionStatus.loading);
  }

  factory PetitionStatusEntity.fromError(
    dynamic error, {
    String? defaultError,
  }) {
    String? errorGetted;
    if (error.toString().contains("Operation timed out") ||
        error.toString().contains("SocketException") ||
        error.toString().contains(ErrorsConstants.noInternet)) {
      errorGetted = ErrorsConstants.noInternet;
    } else if (error.toString().contains(ErrorsConstants.timeout)) {
      errorGetted = ErrorsConstants.timeout;
    } else if (error is String) {
      errorGetted = error;
      if (!ErrorsConstants.existsKey(error)) {
        errorGetted = defaultError ?? error;
      }
    } else if (error is Exception) {
      if (error.toString() == Exception().toString()) {
        errorGetted = defaultError ?? ErrorsConstants.unknownError;
      } else {
        errorGetted = error.toString();
      }
    }
    return PetitionStatusEntity(
      status: PetitionStatus.failed,
      error: errorGetted,
    );
  }

  bool get isSuccess => status == PetitionStatus.complete;
  bool get isError => status == PetitionStatus.failed;
  bool get isLoading => status == PetitionStatus.loading;
  bool get isNotStarted => status == PetitionStatus.notStarted;

  PetitionStatusEntity changeStatus(PetitionStatus status) {
    return PetitionStatusEntity(status: status, data: data, error: error);
  }

  PetitionStatusEntity setLoading() {
    return changeStatus(PetitionStatus.loading);
  }

  @override
  String toString() {
    return 'PetitionStatusEntity{status: $status, data: $data, error: $error}';
  }

  PetitionStatusEntity<T> copyWith({
    PetitionStatus? status,
    T? data,
    String? error,
  }) {
    return PetitionStatusEntity<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  PetitionStatusEntity<R> map<R>(R Function(T) transform) {
    if (isError) {
      return PetitionStatusEntity<R>(status: status, error: error);
    }
    return PetitionStatusEntity<R>(
      status: status,
      data: data != null ? transform(data as T) : null,
      error: error,
    );
  }
}
