class ApiResponse {
  const ApiResponse({required this.ok, required this.message, this.data});

  final bool ok;
  final String message;
  final Object? data;

  factory ApiResponse.fromJson(Map<String, Object?> json) {
    return ApiResponse(
      ok: json['ok'] == true,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }
}
