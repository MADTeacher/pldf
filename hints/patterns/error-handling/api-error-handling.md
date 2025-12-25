# Обработка ошибок API

## Описание

Паттерны обработки ошибок при работе с API: сетевые ошибки, HTTP ошибки, валидация данных.

## Типы ошибок

### Сетевые ошибки
- Нет интернета
- Таймаут запроса
- Ошибка DNS

### HTTP ошибки
- 400 - Bad Request (валидация)
- 401 - Unauthorized (не авторизован)
- 403 - Forbidden (нет доступа)
- 404 - Not Found
- 500 - Server Error

## Пример реализации

```dart
class ApiError implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? data;

  ApiError(this.message, {this.status, this.data});

  @override
  String toString() => message;
}

Future<Map<String, dynamic>> handleApiRequest(
  String url, {
  String method = 'GET',
  Map<String, dynamic>? data,
}) async {
  try {
    final uri = Uri.parse(url);
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: data != null ? jsonEncode(data) : null,
        );
        break;
      default:
        throw ApiError('Unsupported method: $method');
    }
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw ApiError(
        errorData?['message'] ?? 'HTTP error! status: ${response.statusCode}',
        status: response.statusCode,
        data: errorData,
      );
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  } on SocketException catch (_) {
    // Сетевые ошибки
    throw ApiError('Network error. Please check your connection.');
  } on ApiError {
    rethrow;
  } catch (e) {
    // Неизвестные ошибки
    throw ApiError('An unexpected error occurred: $e');
  }
}

// Обработка в виджете
class ApiDataWidget extends StatefulWidget {
  final String url;
  
  const ApiDataWidget({required this.url, super.key});

  @override
  State<ApiDataWidget> createState() => _ApiDataWidgetState();
}

class _ApiDataWidgetState extends State<ApiDataWidget> {
  Map<String, dynamic>? data;
  ApiError? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await handleApiRequest(widget.url);
      setState(() {
        data = result;
        loading = false;
      });
    } on ApiError catch (e) {
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator();
    if (error != null) return Text('Error: ${error!.message}');
    return Text('Data: $data');
  }
}
```

## Best Practices

1. **Различайте типы ошибок** - обрабатывайте по-разному
2. **Предоставляйте понятные сообщения** пользователю
3. **Логируйте ошибки** для отладки
4. **Реализуйте retry логику** для временных ошибок

## Связанные паттерны

- [Логирование](logging.md) - для логирования ошибок

