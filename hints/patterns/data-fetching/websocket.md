# WebSocket для real-time данных

## Описание

WebSocket - это протокол для двусторонней коммуникации между клиентом и сервером через одно постоянное соединение. Позволяет серверу отправлять данные клиенту без запроса.

## Когда использовать

- ✅ Real-time обновления (чат, уведомления)
- ✅ Live данные (котировки, мониторинг)
- ✅ Совместная работа (редактирование документов)
- ✅ Игры и интерактивные приложения

## Когда НЕ использовать

- ❌ Простые CRUD операции
- ❌ Редкие обновления
- ❌ Когда HTTP запросы достаточны
- ❌ Когда постоянное соединение не оправдано

## Пример реализации

### Базовый WebSocket клиент (Dart)

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  final String url;
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  final int maxReconnectAttempts = 5;
  final Duration reconnectDelay = const Duration(seconds: 1);
  final Map<String, List<Function>> _listeners = {};
  Timer? _reconnectTimer;

  WebSocketClient(this.url);

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          emit('message', decoded);
        },
        onError: (error) {
          print('WebSocket error: $error');
          emit('error', error);
        },
        onDone: () {
          print('WebSocket closed');
          emit('close');
          reconnect();
        },
        cancelOnError: false,
      );

      print('WebSocket connected');
      _reconnectAttempts = 0;
      emit('open', null);
    } catch (e) {
      print('Failed to connect: $e');
      reconnect();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      print('WebSocket is not open');
    }
  }

  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, Function callback) {
    _listeners[event]?.remove(callback);
  }

  void emit(String event, dynamic data) {
    _listeners[event]?.forEach((callback) {
      callback(data);
    });
  }

  void reconnect() {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(
        milliseconds: reconnectDelay.inMilliseconds * 
                     (1 << (_reconnectAttempts - 1)),
      );
      print('Reconnecting in ${delay.inMilliseconds}ms (attempt $_reconnectAttempts)');
      
      _reconnectTimer = Timer(delay, () {
        connect();
      });
    } else {
      print('Max reconnect attempts reached');
      emit('reconnect-failed', null);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

// Использование
final ws = WebSocketClient('wss://api.example.com/ws');

ws.on('open', (_) {
  print('Connected');
  ws.send({'type': 'subscribe', 'channel': 'tasks'});
});

ws.on('message', (data) {
  print('Received: $data');
  // Обработка сообщения
});

ws.on('error', (error) {
  print('Error: $error');
});

ws.connect();
```

### React Hook для WebSocket

```javascript
import { useEffect, useRef, useState, useCallback } from 'react';

function useWebSocket(url) {
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState(null);
  const wsRef = useRef(null);
  const reconnectTimeoutRef = useRef(null);

  const connect = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      return;
    }

    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      setIsConnected(true);
      console.log('WebSocket connected');
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setLastMessage(data);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      setIsConnected(false);
      // Автоматическое переподключение
      reconnectTimeoutRef.current = setTimeout(() => {
        connect();
      }, 3000);
    };
  }, [url]);

  const sendMessage = useCallback((message) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket is not connected');
    }
  }, []);

  useEffect(() => {
    connect();

    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [connect]);

  return { isConnected, lastMessage, sendMessage };
}

// Использование
function ChatComponent() {
  const { isConnected, lastMessage, sendMessage } = useWebSocket('wss://api.example.com/chat');

  const handleSend = () => {
    sendMessage({ type: 'message', text: 'Hello!' });
  };

  return (
    <div>
      <div>Status: {isConnected ? 'Connected' : 'Disconnected'}</div>
      {lastMessage && <div>Last message: {JSON.stringify(lastMessage)}</div>}
      <button onClick={handleSend} disabled={!isConnected}>
        Send
      </button>
    </div>
  );
}
```

### Обработка различных типов сообщений

```dart
class WebSocketClient {
  // ... предыдущий код ...

  void handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'notification':
        emit('notification', data['payload']);
        break;
      case 'task-updated':
        emit('task-updated', data['payload']);
        break;
      case 'user-joined':
        emit('user-joined', data['payload']);
        break;
      default:
        emit('message', data);
    }
  }

  void subscribe(String channel) {
    send({'type': 'subscribe', 'channel': channel});
  }

  void unsubscribe(String channel) {
    send({'type': 'unsubscribe', 'channel': channel});
  }
}
```

## Преимущества

- ✅ Real-time обновления без polling
- ✅ Двусторонняя коммуникация
- ✅ Меньше overhead, чем HTTP запросы
- ✅ Подходит для интерактивных приложений

## Недостатки

- ❌ Сложнее, чем HTTP
- ❌ Требует управления соединением
- ❌ Может быть избыточно для редких обновлений
- ❌ Проблемы с балансировкой нагрузки

## Best Practices

1. **Реализуйте переподключение** - автоматически переподключайтесь при разрыве
2. **Обрабатывайте ошибки** - обрабатывайте все типы ошибок соединения
3. **Используйте heartbeat** - проверяйте, что соединение активно
4. **Обрабатывайте различные типы сообщений** - используйте типы для маршрутизации
5. **Очищайте ресурсы** - закрывайте соединение при размонтировании компонента
6. **Используйте защиту от спама** - ограничивайте частоту отправки сообщений

## Связанные паттерны

- [REST API](rest-api.md) - для обычных запросов
- [GraphQL подписки](graphql.md) - альтернатива для GraphQL API

