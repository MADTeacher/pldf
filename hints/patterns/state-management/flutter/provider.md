# Provider - управление состоянием в Flutter

## Описание

Provider - это популярный пакет для управления состоянием в Flutter, основанный на InheritedWidget. Он предоставляет простой способ передачи данных через дерево виджетов и реактивного обновления UI.

## Когда использовать

- ✅ Простые и средние приложения
- ✅ Когда нужна простота и понятность
- ✅ Для начинающих разработчиков Flutter
- ✅ Когда состояние не очень сложное

## Когда НЕ использовать

- ❌ Очень сложное состояние с множеством зависимостей
- ❌ Когда нужна более структурированная архитектура
- ❌ Для больших командных проектов с сложной бизнес-логикой

## Базовое использование

### Установка

```yaml
dependencies:
  provider: ^6.0.0
```

### Простой пример

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Модель состояния
class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // Уведомление слушателей об изменении
  }

  void decrement() {
    _count--;
    notifyListeners();
  }
}

// Главный виджет
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => Counter(),
      child: MyApp(),
    ),
  );
}

// Использование в виджете
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Чтение значения
            Text(
              'Count: ${context.watch<Counter>().count}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  // Вызов метода
                  onPressed: () => context.read<Counter>().decrement(),
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => context.read<Counter>().increment(),
                  child: Text('+'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Продвинутые паттерны

### Множественные провайдеры

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Counter()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Асинхронные провайдеры

```dart
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadUser() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await api.getUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

// Использование
class UserWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.loading) {
      return CircularProgressIndicator();
    }

    if (userProvider.error != null) {
      return Text('Error: ${userProvider.error}');
    }

    return Text('User: ${userProvider.user?.name}');
  }
}
```

### Селективное обновление

```dart
// Использование select для оптимизации
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Виджет обновится только когда count изменится
    final count = context.select<Counter, int>((counter) => counter.count);
    
    return Text('Count: $count');
  }
}
```

## Преимущества

- ✅ Простота - легко понять и использовать
- ✅ Официальная рекомендация Flutter
- ✅ Хорошая производительность с select
- ✅ Хорошая документация и сообщество

## Недостатки

- ❌ Может стать сложным для больших приложений
- ❌ Нет встроенной поддержки для сложной бизнес-логики
- ❌ Требует ручного управления жизненным циклом

## Best Practices

1. **Используйте ChangeNotifier** для реактивного состояния
2. **Вызывайте notifyListeners()** после изменения состояния
3. **Используйте select** для оптимизации обновлений
4. **Разделяйте провайдеры** по доменам (UserProvider, TaskProvider и т.д.)
5. **Не храните UI состояние** в провайдерах (используйте StatefulWidget)

## Связанные паттерны

- [Riverpod](riverpod.md) - современная альтернатива
- [BLoC](bloc.md) - для более сложной логики

