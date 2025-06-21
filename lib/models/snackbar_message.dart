class SnackBarMessage {
  final String message;
  final bool isError;

  SnackBarMessage({
    required this.message,
    this.isError = false,
  });
}