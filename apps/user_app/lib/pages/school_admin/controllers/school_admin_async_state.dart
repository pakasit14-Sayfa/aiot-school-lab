/// A truthful async state contract for School Admin database-backed views.
///
/// Pages must distinguish loading, data, empty, and error states. Loading and
/// error states may retain the last server-confirmed value while refreshing or
/// while reporting a failed mutation.
sealed class SchoolAdminAsyncState<T> {
  const SchoolAdminAsyncState();

  bool get isLoading => this is SchoolAdminLoading<T>;
  bool get hasData => this is SchoolAdminData<T>;
  bool get isEmpty => this is SchoolAdminEmpty<T>;
  bool get hasError => this is SchoolAdminError<T>;
}

final class SchoolAdminLoading<T> extends SchoolAdminAsyncState<T> {
  const SchoolAdminLoading({this.previousData});

  final T? previousData;
}

final class SchoolAdminData<T> extends SchoolAdminAsyncState<T> {
  const SchoolAdminData(this.value);

  final T value;
}

final class SchoolAdminEmpty<T> extends SchoolAdminAsyncState<T> {
  const SchoolAdminEmpty({this.label = 'ยังไม่มีข้อมูล'});

  final String label;
}

final class SchoolAdminError<T> extends SchoolAdminAsyncState<T> {
  const SchoolAdminError({
    required this.message,
    this.error,
    this.stackTrace,
    this.previousData,
  });

  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final T? previousData;
}
