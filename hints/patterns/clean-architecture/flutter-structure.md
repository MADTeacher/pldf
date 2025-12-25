# Структура Flutter проектов

## Описание

Рекомендации по организации структуры Flutter приложений с применением принципов чистой архитектуры. Рассматриваются различные подходы в зависимости от размера и сложности проекта.

## Когда использовать

- ✅ Flutter приложения любого размера
- ✅ Когда нужна масштабируемая структура
- ✅ Командная разработка
- ✅ Долгосрочные проекты

## Подходы к структуре

### 1. Feature-based структура (Рекомендуется)

Организация по функциональным модулям. Каждая фича содержит все необходимые слои.

```
lib/
├── core/                      # Общие компоненты
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── utils/
│   └── widgets/
├── features/                   # Функциональные модули
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/          # или provider, riverpod
│   │       ├── pages/
│   │       └── widgets/
│   ├── notes/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### 2. Layer-based структура

Организация по слоям (классическая чистая архитектура).

```
lib/
├── core/
│   ├── error/
│   ├── network/
│   └── usecase/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── bloc/
│   ├── pages/
│   └── widgets/
└── main.dart
```

**Когда использовать**: Для небольших проектов или когда фичи тесно связаны.

## Детальная структура Feature-based

### Структура фичи

```
features/notes/
├── data/
│   ├── datasources/
│   │   ├── notes_local_datasource.dart
│   │   └── notes_remote_datasource.dart
│   ├── models/
│   │   └── note_model.dart
│   └── repositories/
│       └── notes_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── note.dart
│   ├── repositories/
│   │   └── notes_repository.dart
│   └── usecases/
│       ├── get_notes.dart
│       ├── create_note.dart
│       └── delete_note.dart
└── presentation/
    ├── bloc/
    │   ├── notes_bloc.dart
    │   ├── notes_event.dart
    │   └── notes_state.dart
    ├── pages/
    │   ├── notes_list_page.dart
    │   └── note_edit_page.dart
    └── widgets/
        ├── note_card.dart
        └── note_form.dart
```

### Domain слой

```dart
// domain/entities/note.dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

```dart
// domain/repositories/notes_repository.dart
abstract class NotesRepository {
  Future<Either<Failure, List<Note>>> getNotes();
  Future<Either<Failure, Note>> createNote(Note note);
  Future<Either<Failure, void>> deleteNote(String id);
}
```

```dart
// domain/usecases/get_notes.dart
class GetNotes {
  final NotesRepository repository;

  GetNotes(this.repository);

  Future<Either<Failure, List<Note>>> call() async {
    return await repository.getNotes();
  }
}
```

### Data слой

```dart
// data/models/note_model.dart
class NoteModel extends Note {
  NoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

```dart
// data/datasources/notes_remote_datasource.dart
abstract class NotesRemoteDataSource {
  Future<List<Map<String, dynamic>>> getNotes();
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> note);
}

class NotesRemoteDataSourceImpl implements NotesRemoteDataSource {
  final ApiClient apiClient;

  NotesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Map<String, dynamic>>> getNotes() async {
    final response = await apiClient.get('/notes');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> note) async {
    final response = await apiClient.post('/notes', data: note);
    return Map<String, dynamic>.from(response.data);
  }
}
```

```dart
// data/repositories/notes_repository_impl.dart
class NotesRepositoryImpl implements NotesRepository {
  final NotesRemoteDataSource remoteDataSource;
  final NotesLocalDataSource localDataSource;

  NotesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Note>>> getNotes() async {
    try {
      // Пробуем получить из кэша
      final localNotes = await localDataSource.getNotes();
      if (localNotes.isNotEmpty) {
        return Right(localNotes.map((n) => NoteModel.fromJson(n)).toList());
      }

      // Если нет в кэше, получаем с сервера
      final remoteData = await remoteDataSource.getNotes();
      final notes = remoteData.map((json) => NoteModel.fromJson(json)).toList();
      
      // Сохраняем в кэш
      await localDataSource.cacheNotes(remoteData);
      
      return Right(notes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Note>> createNote(Note note) async {
    try {
      final noteModel = NoteModel(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
      
      final json = await remoteDataSource.createNote(noteModel.toJson());
      final createdNote = NoteModel.fromJson(json);
      
      await localDataSource.insertNote(json);
      
      return Right(createdNote);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await remoteDataSource.deleteNote(id);
      await localDataSource.deleteNote(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

### Presentation слой

```dart
// presentation/bloc/notes_event.dart
abstract class NotesEvent {}

class LoadNotes extends NotesEvent {}
class CreateNote extends NotesEvent {
  final String title;
  final String content;
  CreateNote(this.title, this.content);
}
class DeleteNote extends NotesEvent {
  final String id;
  DeleteNote(this.id);
}
```

```dart
// presentation/bloc/notes_state.dart
abstract class NotesState {}

class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}
class NotesLoaded extends NotesState {
  final List<Note> notes;
  NotesLoaded(this.notes);
}
class NotesError extends NotesState {
  final String message;
  NotesError(this.message);
}
```

```dart
// presentation/bloc/notes_bloc.dart
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final GetNotes getNotes;
  final CreateNote createNote;
  final DeleteNote deleteNote;

  NotesBloc({
    required this.getNotes,
    required this.createNote,
    required this.deleteNote,
  }) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<CreateNote>(_onCreateNote);
    on<DeleteNote>(_onDeleteNote);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    final result = await getNotes();
    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (notes) => emit(NotesLoaded(notes)),
    );
  }

  Future<void> _onCreateNote(CreateNote event, Emitter<NotesState> emit) async {
    final note = Note(
      id: generateId(),
      title: event.title,
      content: event.content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final result = await createNote(note);
    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => add(LoadNotes()),
    );
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    final result = await deleteNote(event.id);
    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => add(LoadNotes()),
    );
  }
}
```

```dart
// presentation/pages/notes_list_page.dart
class NotesListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is NotesError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is NotesLoaded) {
            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                return NoteCard(note: state.notes[index]);
              },
            );
          }
          return SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditPage()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Core компоненты

### Error handling

```dart
// core/error/failures.dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}
```

```dart
// core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
```

### Either для обработки ошибок

```dart
// core/usecase/usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
```

Использование с пакетом `dartz`:

```dart
dependencies:
  dartz: ^0.10.1
```

## Dependency Injection

Используйте `get_it` или `injectable`:

```dart
// injection/injection.dart
final getIt = GetIt.instance;

void setup() {
  // Data sources
  getIt.registerLazySingleton<NotesRemoteDataSource>(
    () => NotesRemoteDataSourceImpl(getIt()),
  );
  
  // Repositories
  getIt.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );
  
  // Use cases
  getIt.registerLazySingleton(() => GetNotes(getIt()));
  getIt.registerLazySingleton(() => CreateNote(getIt()));
  
  // Bloc
  getIt.registerFactory(
    () => NotesBloc(
      getNotes: getIt(),
      createNote: getIt(),
      deleteNote: getIt(),
    ),
  );
}
```

## Преимущества Feature-based структуры

- ✅ Модульность - каждая фича независима
- ✅ Масштабируемость - легко добавлять новые фичи
- ✅ Командная работа - разные команды работают над разными фичами
- ✅ Тестируемость - легко тестировать изолированно
- ✅ Переиспользование - core компоненты используются везде

## Best Practices

1. **Разделяйте по фичам** - каждая фича содержит все слои
2. **Используйте core для общих компонентов** - не дублируйте код
3. **Следуйте принципам чистой архитектуры** - зависимости направлены внутрь
4. **Используйте Dependency Injection** - для управления зависимостями
5. **Тестируйте каждый слой** - domain, data, presentation
6. **Используйте Either для ошибок** - явная обработка ошибок
7. **Не смешивайте слои** - domain не знает о data и presentation

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - общие принципы
- [BLoC](../state-management/flutter/bloc.md) - для управления состоянием
- [Provider](../state-management/flutter/provider.md) - альтернатива BLoC

