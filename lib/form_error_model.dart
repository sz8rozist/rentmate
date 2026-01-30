class FormErrors {
  final Map<String, String> fieldErrors;

  const FormErrors(this.fieldErrors);

  String? errorFor(String field) => fieldErrors[field];

  bool get hasErrors => fieldErrors.isNotEmpty;

  FormErrors remove(String field) {
    final copy = Map<String, String>.from(fieldErrors);
    copy.remove(field);
    return FormErrors(copy);
  }

  factory FormErrors.empty() => const FormErrors({});
}
