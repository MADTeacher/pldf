# Логирование и мониторинг ошибок

## Описание

Паттерны логирования ошибок: структурированное логирование, уровни логирования, интеграция с сервисами мониторинга.

## Уровни логирования

- **Error** - критические ошибки
- **Warn** - предупреждения
- **Info** - информационные сообщения
- **Debug** - отладочная информация

## Пример реализации

```dart
enum LogLevel { error, warn, info, debug }

class Logger {
  final String service;

  Logger({this.service = 'app'});

  void error(String message, {Object? error, Map<String, dynamic>? context}) {
    final logEntry = {
      'level': 'error',
      'message': message,
      'service': service,
      'timestamp': DateTime.now().toIso8601String(),
      if (error != null)
        'error': {
          'name': error.runtimeType.toString(),
          'message': error.toString(),
          'stack': error is StackTrace ? error.toString() : null,
        },
      if (context != null) 'context': context,
    };

    print('[ERROR] $logEntry');
    // Отправка в сервис мониторинга
    sendToMonitoring(logEntry);
  }

  void warn(String message, {Map<String, dynamic>? context}) {
    final logEntry = {
      'level': 'warn',
      'message': message,
      'service': service,
      'timestamp': DateTime.now().toIso8601String(),
      if (context != null) 'context': context,
    };
    print('[WARN] $logEntry');
  }

  void info(String message, {Map<String, dynamic>? context}) {
    final logEntry = {
      'level': 'info',
      'message': message,
      'service': service,
      'timestamp': DateTime.now().toIso8601String(),
      if (context != null) 'context': context,
    };
    print('[INFO] $logEntry');
  }

  void sendToMonitoring(Map<String, dynamic> logEntry) {
    // Интеграция с Sentry, LogRocket и т.д.
    // Sentry.captureException(logEntry['error']);
  }
}

// Использование
final logger = Logger(service: 'api');

try {
  await apiRequest();
} catch (error, stackTrace) {
  logger.error(
    'API request failed',
    error: error,
    context: {'endpoint': '/api/tasks'},
  );
}
```

## Best Practices

1. **Используйте структурированное логирование** - JSON формат
2. **Включайте контекст** - URL, пользователь, параметры
3. **Не логируйте чувствительные данные** - пароли, токены
4. **Используйте уровни логирования** правильно
5. **Интегрируйте с мониторингом** - Sentry, LogRocket

## Связанные паттерны

- [Error Boundaries](error-boundaries.md) - для логирования ошибок React
- [Обработка ошибок API](api-error-handling.md) - для логирования API ошибок

