# REST API клиенты

## Описание

REST (Representational State Transfer) - это архитектурный стиль для создания веб-сервисов. REST API использует HTTP методы (GET, POST, PUT, DELETE) для работы с ресурсами.

## Когда использовать

- ✅ Стандартные CRUD операции
- ✅ Простая структура данных
- ✅ Когда команда знакома с REST
- ✅ Для большинства веб-приложений

## Основные принципы

1. **Используйте HTTP методы правильно**:
   - `GET` - получение данных (без побочных эффектов)
   - `POST` - создание нового ресурса
   - `PUT` - полное обновление ресурса
   - `PATCH` - частичное обновление ресурса
   - `DELETE` - удаление ресурса

2. **Используйте правильные статус коды**:
   - `200` - успех
   - `201` - создано
   - `400` - ошибка клиента
   - `401` - не авторизован
   - `404` - не найдено
   - `500` - ошибка сервера

## Пример реализации

### Базовый API клиент (Dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseURL;
  final http.Client _client;

  ApiClient({required this.baseURL}) : _client = http.Client();

  Future<Map<String, dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseURL$endpoint');
    
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    // Добавление токена аутентификации
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await _client.post(
            url,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            url,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            url,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Обработка ошибок HTTP
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'HTTP error! status: ${response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('API request failed: $e');
      rethrow;
    }
  }

  // CRUD методы
  Future<Map<String, dynamic>> get(String endpoint) async {
    return request(endpoint, method: 'GET');
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return request(endpoint, method: 'POST', data: data);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return request(endpoint, method: 'PUT', data: data);
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    return request(endpoint, method: 'PATCH', data: data);
  }

  Future<void> delete(String endpoint) async {
    await request(endpoint, method: 'DELETE');
  }
}

// Использование
final api = ApiClient(baseURL: 'https://api.example.com');

// Получение списка задач
final tasksResponse = await api.get('/api/tasks');
final tasks = tasksResponse['data'] as List;

// Создание задачи
final newTaskResponse = await api.post('/api/tasks', {
  'title': 'Новая задача',
  'completed': false,
});

// Обновление задачи
final updatedTaskResponse = await api.patch('/api/tasks/1', {
  'completed': true,
});

// Удаление задачи
await api.delete('/api/tasks/1');
```

### React Hook для работы с API

```javascript
import { useState, useEffect } from 'react';

function useApi(endpoint, options = {}) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);
        const result = await api.get(endpoint);
        setData(result);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    if (options.enabled !== false) {
      fetchData();
    }
  }, [endpoint, options.enabled]);

  const refetch = async () => {
    setLoading(true);
    try {
      const result = await api.get(endpoint);
      setData(result);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return { data, loading, error, refetch };
}

// Использование
function TasksList() {
  const { data: tasks, loading, error, refetch } = useApi('/api/tasks');

  if (loading) return <div>Загрузка...</div>;
  if (error) return <div>Ошибка: {error}</div>;

  return (
    <div>
      {tasks.map(task => (
        <div key={task.id}>{task.title}</div>
      ))}
      <button onClick={refetch}>Обновить</button>
    </div>
  );
}
```

### Обработка ошибок

```dart
class ApiError implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? data;

  ApiError(this.message, {this.status, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  Future<Map<String, dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('$baseURL$endpoint');
      http.Response response;
      
      // ... выполнение запроса ...
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        throw ApiError(
          errorData?['message'] ?? 'Request failed',
          status: response.statusCode,
          data: errorData,
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      // Обработка сетевых ошибок
      throw ApiError('Network error', data: {'originalError': e.toString()});
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Unexpected error: $e');
    }
  }
}
```

### Кэширование

```dart
class CachedApiClient extends ApiClient {
  final Map<String, _CacheEntry> _cache = {};
  final Duration cacheTime;

  CachedApiClient({
    required super.baseURL,
    Duration? cacheTime,
  }) : cacheTime = cacheTime ?? const Duration(minutes: 5);

  @override
  Future<Map<String, dynamic>> get(String endpoint) async {
    final cached = _cache[endpoint];
    
    // Проверка кэша
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < cacheTime) {
      return cached.data;
    }

    // Запрос к API
    final data = await super.get(endpoint);
    
    // Сохранение в кэш
    _cache[endpoint] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
    );

    return data;
  }

  void invalidate(String endpoint) {
    _cache.remove(endpoint);
  }

  void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}
```

## Best Practices

1. **Используйте базовый URL** - настройте один базовый URL для всех запросов
2. **Обрабатывайте ошибки** - всегда обрабатывайте сетевые и HTTP ошибки
3. **Показывайте состояние загрузки** - информируйте пользователя о процессе
4. **Используйте правильные HTTP методы** - следуйте REST принципам
5. **Кэшируйте данные** - уменьшайте количество запросов к серверу
6. **Используйте retry логику** - повторяйте запросы при временных ошибках
7. **Валидируйте данные** - проверяйте данные перед отправкой

## Связанные паттерны

- [Обработка ошибок API](../error-handling/api-error-handling.md) - для обработки ошибок
- [JWT аутентификация](../auth-patterns/jwt-auth.md) - для аутентификации запросов

