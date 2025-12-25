# Clean Architecture (Uncle Bob)

## Описание

Clean Architecture (Чистая архитектура) - это архитектурный паттерн, предложенный Робертом Мартином (Uncle Bob), который разделяет приложение на слои с четкими правилами зависимостей. Основная идея - изоляция бизнес-логики от деталей реализации (UI, БД, внешние сервисы).

## Когда использовать

- ✅ Большие и долгосрочные проекты
- ✅ Сложная бизнес-логика
- ✅ Высокие требования к тестируемости
- ✅ Возможность смены технологий (БД, UI фреймворк)
- ✅ Большие команды, нужна четкая структура

## Когда НЕ использовать

- ❌ Простые проекты (MVP, прототипы)
- ❌ Краткосрочные проекты
- ❌ Маленькие команды без времени на структуру
- ❌ Нет сложной бизнес-логики

## Структура слоев

```
┌─────────────────────────────────────┐
│         Frameworks & Drivers        │  ← Внешний слой
│  (UI, DB, Web, Devices, External)   │
├─────────────────────────────────────┤
│      Interface Adapters             │
│  (Controllers, Presenters, Gateways)│
├─────────────────────────────────────┤
│          Use Cases                  │  ← Бизнес-логика
│    (Application Business Rules)     │
├─────────────────────────────────────┤
│          Entities                   │  ← Ядро
│    (Enterprise Business Rules)      │
└─────────────────────────────────────┘
```

### Entities (Сущности)

Самый внутренний слой. Содержит бизнес-правила предприятия. Не зависят ни от чего внешнего.

```dart
// entities/user.dart
class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });

  bool isValid() {
    return email.contains('@') && name.isNotEmpty;
  }
}
```

### Use Cases (Сценарии использования)

Содержат бизнес-правила приложения. Описывают, что приложение делает.

```dart
// use_cases/get_user_by_id.dart
class GetUserById {
  final UserRepository repository;

  GetUserById(this.repository);

  Future<User?> execute(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    return await repository.findById(userId);
  }
}
```

```dart
// use_cases/create_user.dart
class CreateUser {
  final UserRepository repository;

  CreateUser(this.repository);

  Future<User> execute(String email, String name) async {
    final user = User(
      id: generateId(),
      email: email,
      name: name,
    );

    if (!user.isValid()) {
      throw ValidationException('Invalid user data');
    }

    return await repository.save(user);
  }
}
```

### Interface Adapters (Адаптеры интерфейсов)

Преобразуют данные между Use Cases и внешними слоями.

```dart
// repositories/user_repository.dart (интерфейс)
abstract class UserRepository {
  Future<User?> findById(String id);
  Future<User> save(User user);
  Future<List<User>> findAll();
}

// presenters/user_presenter.dart
class UserPresenter {
  Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'name': user.name,
    };
  }

  User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
    );
  }
}
```

### Frameworks & Drivers (Фреймворки и драйверы)

Внешний слой - UI, БД, веб-серверы, внешние API.

```dart
// ui/controllers/user_controller.dart
class UserController {
  final GetUserById getUserById;
  final CreateUser createUser;
  final UserPresenter presenter;

  UserController({
    required this.getUserById,
    required this.createUser,
    required this.presenter,
  });

  Future<Map<String, dynamic>> getUser(String id) async {
    try {
      final user = await getUserById.execute(id);
      if (user == null) {
        return {'error': 'User not found'};
      }
      return presenter.toJson(user);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final user = await createUser.execute(
        data['email'],
        data['name'],
      );
      return presenter.toJson(user);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
```

```dart
// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final Database database;

  UserRepositoryImpl(this.database);

  @override
  Future<User?> findById(String id) async {
    final data = await database.query('SELECT * FROM users WHERE id = ?', [id]);
    if (data.isEmpty) return null;
    return _mapToUser(data.first);
  }

  @override
  Future<User> save(User user) async {
    await database.insert('users', {
      'id': user.id,
      'email': user.email,
      'name': user.name,
    });
    return user;
  }

  @override
  Future<List<User>> findAll() async {
    final data = await database.query('SELECT * FROM users');
    return data.map((row) => _mapToUser(row)).toList();
  }

  User _mapToUser(Map<String, dynamic> row) {
    return User(
      id: row['id'],
      email: row['email'],
      name: row['name'],
    );
  }
}
```

## Пример структуры проекта

```
lib/
├── core/                    # Общие утилиты
│   ├── errors/
│   └── utils/
├── domain/                  # Entities и Use Cases
│   ├── entities/
│   │   └── user.dart
│   ├── repositories/        # Интерфейсы
│   │   └── user_repository.dart
│   └── use_cases/
│       ├── get_user_by_id.dart
│       └── create_user.dart
├── data/                    # Реализации репозиториев
│   ├── models/              # Модели данных (DTO)
│   ├── repositories/
│   │   └── user_repository_impl.dart
│   └── data_sources/        # Источники данных
│       ├── local/
│       └── remote/
└── presentation/            # UI слой
    ├── controllers/
    ├── presenters/
    └── pages/
```

## Правило зависимостей

**Зависимости направлены внутрь:**

- Entities не зависят ни от чего
- Use Cases зависят только от Entities
- Interface Adapters зависят от Use Cases и Entities
- Frameworks зависят от всех внутренних слоев

```dart
// ✅ Правильно: Use Case зависит от Entity
class GetUserById {
  Future<User> execute(String id); // User - это Entity
}

// ❌ Неправильно: Entity зависит от Use Case
class User {
  GetUserById useCase; // НЕПРАВИЛЬНО!
}
```

## Dependency Inversion

Используйте интерфейсы (абстракции) вместо конкретных реализаций:

```dart
// ✅ Правильно: Use Case зависит от абстракции
class GetUserById {
  final UserRepository repository; // Интерфейс, не реализация
}

// ❌ Неправильно: Use Case зависит от реализации
class GetUserById {
  final UserRepositoryImpl repository; // Конкретная реализация
}
```

## Тестирование

Чистая архитектура упрощает тестирование:

```dart
// Тест Use Case с мок-репозиторием
class MockUserRepository implements UserRepository {
  User? userToReturn;

  @override
  Future<User?> findById(String id) async {
    return userToReturn;
  }

  @override
  Future<User> save(User user) async => user;

  @override
  Future<List<User>> findAll() async => [];
}

void main() {
  test('GetUserById should return user when found', () async {
    // Arrange
    final mockRepo = MockUserRepository();
    mockRepo.userToReturn = User(id: '1', email: 'test@test.com', name: 'Test');
    final useCase = GetUserById(mockRepo);

    // Act
    final result = await useCase.execute('1');

    // Assert
    expect(result, isNotNull);
    expect(result!.email, 'test@test.com');
  });
}
```

## Преимущества

- ✅ Независимость от фреймворков
- ✅ Тестируемость - бизнес-логика тестируется изолированно
- ✅ Независимость от UI - можно заменить UI без изменения логики
- ✅ Независимость от БД - можно сменить БД
- ✅ Независимость от внешних сервисов
- ✅ Четкая структура для больших команд

## Недостатки

- ❌ Больше кода и файлов
- ❌ Крутая кривая обучения
- ❌ Может быть избыточно для простых проектов
- ❌ Требует дисциплины от команды

## Best Practices

1. **Следуйте правилу зависимостей** - зависимости направлены внутрь
2. **Используйте Dependency Inversion** - зависьте от абстракций
3. **Один Use Case = одна операция** - не смешивайте логику
4. **Entities содержат только бизнес-правила** - без UI, БД логики
5. **Тестируйте Use Cases изолированно** - с моками репозиториев
6. **Используйте интерфейсы для репозиториев** - в domain слое

## Связанные паттерны

- [Hexagonal Architecture](hexagonal-architecture.md) - альтернативный подход
- [Onion Architecture](onion-architecture.md) - похожий подход с концентрическими слоями
- [Repository Pattern](../data-fetching/) - для работы с данными

