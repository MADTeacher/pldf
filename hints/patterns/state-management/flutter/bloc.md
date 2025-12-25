# BLoC паттерн в Flutter

## Описание

BLoC (Business Logic Component) - это паттерн управления состоянием, который разделяет бизнес-логику и UI. Он основан на потоке событий (Events) и состояния (States), что делает код более тестируемым и предсказуемым.

## Когда использовать

- ✅ Большие приложения с сложной бизнес-логикой
- ✅ Когда нужна тестируемость
- ✅ Для командных проектов
- ✅ Когда нужна предсказуемость и структурированность

## Когда НЕ использовать

- ❌ Простые приложения (может быть избыточно)
- ❌ Для начинающих (более сложный)
- ❌ Когда нужна быстрота разработки

## Базовое использование

### Установка

```yaml
dependencies:
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0
```

### Простой пример

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// События
abstract class CounterEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class IncrementEvent extends CounterEvent {}
class DecrementEvent extends CounterEvent {}

// Состояние
class CounterState extends Equatable {
  final int count;

  CounterState(this.count);

  @override
  List<Object> get props => [count];
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(0)) {
    on<IncrementEvent>((event, emit) {
      emit(CounterState(state.count + 1));
    });

    on<DecrementEvent>((event, emit) {
      emit(CounterState(state.count - 1));
    });
  }
}

// Главный виджет
void main() {
  runApp(
    MaterialApp(
      home: BlocProvider(
        create: (context) => CounterBloc(),
        child: CounterWidget(),
      ),
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
        child: BlocBuilder<CounterBloc, CounterState>(
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${state.count}', style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.read<CounterBloc>().add(DecrementEvent()),
                      child: Text('-'),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => context.read<CounterBloc>().add(IncrementEvent()),
                      child: Text('+'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

## Продвинутые паттерны

### Асинхронные события

```dart
// Событие для загрузки данных
class LoadTasksEvent extends CounterEvent {}

// Состояние с загрузкой
class TasksState extends Equatable {
  final List<Task> tasks;
  final bool loading;
  final String? error;

  TasksState({
    this.tasks = const [],
    this.loading = false,
    this.error,
  });

  @override
  List<Object?> get props => [tasks, loading, error];
}

// BLoC с асинхронной логикой
class TasksBloc extends Bloc<CounterEvent, TasksState> {
  final TaskRepository repository;

  TasksBloc(this.repository) : super(TasksState()) {
    on<LoadTasksEvent>(_onLoadTasks);
  }

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    
    try {
      final tasks = await repository.getTasks();
      emit(state.copyWith(tasks: tasks, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }
}
```

### Множественные BLoC

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CounterBloc()),
        BlocProvider(create: (_) => TasksBloc(TaskRepository())),
        BlocProvider(create: (_) => UserBloc(UserRepository())),
      ],
      child: MaterialApp(home: HomePage()),
    );
  }
}
```

### BLoCListener для побочных эффектов

```dart
class TasksWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<TasksBloc, TasksState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.error}')),
          );
        }
      },
      child: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state.loading) {
            return CircularProgressIndicator();
          }
          return ListView.builder(
            itemCount: state.tasks.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(state.tasks[index].title));
            },
          );
        },
      ),
    );
  }
}
```

## Преимущества

- ✅ Разделение бизнес-логики и UI
- ✅ Высокая тестируемость
- ✅ Предсказуемость - все изменения через события
- ✅ Подходит для больших приложений
- ✅ Хорошая документация

## Недостатки

- ❌ Больше boilerplate кода
- ❌ Более сложный для начинающих
- ❌ Может быть избыточно для простых случаев

## Best Practices

1. **Используйте Equatable** для сравнения состояний
2. **Разделяйте события и состояния** по доменам
3. **Используйте BLoCListener** для побочных эффектов
4. **Тестируйте BLoC** отдельно от UI
5. **Используйте copyWith** для обновления состояния

## Связанные паттерны

- [Provider](provider.md) - более простая альтернатива
- [Riverpod](riverpod.md) - современная альтернатива

