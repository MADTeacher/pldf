# Riverpod - современное управление состоянием в Flutter

## Описание

Riverpod - это современная альтернатива Provider, созданная тем же автором. Она решает проблемы Provider, такие как безопасность типов во время компиляции, лучшая производительность и более гибкая архитектура.

## Когда использовать

- ✅ Современные Flutter приложения
- ✅ Когда нужна безопасность типов во время компиляции
- ✅ Для больших приложений с сложной логикой
- ✅ Когда нужна лучшая производительность, чем Provider

## Когда НЕ использовать

- ❌ Для очень простых приложений (может быть избыточно)
- ❌ Когда команда уже использует Provider и не хочет мигрировать
- ❌ Для начинающих (более сложный, чем Provider)

## Базовое использование

### Установка

```yaml
dependencies:
  flutter_riverpod: ^2.0.0
```

### Простой пример

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider для состояния
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

// StateNotifier для бизнес-логики
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
  void decrement() => state--;
}

// Главный виджет
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// Использование в виджете
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: $count', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => ref.read(counterProvider.notifier).decrement(),
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => ref.read(counterProvider.notifier).increment(),
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

### Асинхронные провайдеры

```dart
// FutureProvider для асинхронных данных
final userProvider = FutureProvider<User>((ref) async {
  return await api.getUser();
});

// Использование
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text('User: ${user.name}'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Зависимости между провайдерами

```dart
// Провайдер для API клиента
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Провайдер, зависящий от другого
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return await api.getTasks();
});

// Провайдер для фильтрованных задач
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  final filter = ref.watch(filterProvider);
  return tasks.where((task) => task.status == filter).toList();
});
```

### Family провайдеры

```dart
// Провайдер с параметром
final taskProvider = FutureProvider.family<Task, int>((ref, taskId) async {
  final api = ref.watch(apiClientProvider);
  return await api.getTask(taskId);
});

// Использование
class TaskWidget extends ConsumerWidget {
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskProvider(taskId));

    return taskAsync.when(
      data: (task) => Text(task.title),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### AutoDispose для автоматической очистки

```dart
// Автоматическая очистка при размонтировании
final timerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(Duration(seconds: 1), (i) => i);
});
```

## Преимущества

- ✅ Безопасность типов во время компиляции
- ✅ Лучшая производительность, чем Provider
- ✅ Более гибкая архитектура
- ✅ Встроенная поддержка асинхронности
- ✅ Автоматическая очистка ресурсов

## Недостатки

- ❌ Более сложный, чем Provider
- ❌ Меньше документации и примеров
- ❌ Требует изучения новых концепций

## Best Practices

1. **Используйте StateNotifier** для изменяемого состояния
2. **Используйте Provider** для неизменяемых данных
3. **Используйте FutureProvider/StreamProvider** для асинхронных данных
4. **Используйте family** для провайдеров с параметрами
5. **Используйте autoDispose** для временных провайдеров

## Связанные паттерны

- [Provider](provider.md) - более простая альтернатива
- [BLoC](bloc.md) - для более структурированной архитектуры

