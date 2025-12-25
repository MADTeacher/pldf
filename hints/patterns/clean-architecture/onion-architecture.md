# Onion Architecture (Луковая архитектура)

## Описание

Onion Architecture (Луковая архитектура) - это архитектурный паттерн, предложенный Джеффри Палермо, который организует приложение в виде концентрических слоев, где зависимости направлены внутрь к ядру. Внешние слои зависят от внутренних, но не наоборот.

## Когда использовать

- ✅ Долгосрочные проекты с сложной бизнес-логикой
- ✅ Когда нужна полная независимость от инфраструктуры
- ✅ DDD (Domain-Driven Design) проекты
- ✅ Когда важна тестируемость бизнес-логики
- ✅ Большие команды с четким разделением ответственности

## Когда НЕ использовать

- ❌ Простые проекты
- ❌ Краткосрочные проекты
- ❌ Когда команда не готова к сложной структуре

## Концепция

```
        ┌─────────────────┐
        │   UI / API      │  ← Внешний слой
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │ Infrastructure  │  ← Внешний слой
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Application    │  ← Средний слой
        │    Services     │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │    Domain      │  ← Ядро (независимый)
        │   (Entities,   │
        │  Interfaces)   │
        └────────────────┘
```

## Слои

### Domain Core (Ядро домена)

Самый внутренний слой. Содержит бизнес-сущности и интерфейсы. Не зависит ни от чего внешнего.

```dart
// domain/entities/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  // Бизнес-правила в сущности
  bool isValid() {
    return email.contains('@') && 
           name.isNotEmpty && 
           name.length >= 2;
  }

  bool canBeDeleted() {
    // Бизнес-правило: пользователь может быть удален только через 30 дней
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation >= 30;
  }
}
```

```dart
// domain/interfaces/repositories/user_repository_interface.dart
abstract class IUserRepository {
  Future<User?> findById(String id);
  Future<User?> findByEmail(String email);
  Future<User> save(User user);
  Future<void> delete(String id);
}

// domain/interfaces/services/email_service_interface.dart
abstract class IEmailService {
  Future<void> sendWelcomeEmail(String email);
  Future<void> sendPasswordResetEmail(String email);
}
```

### Application Services (Сервисы приложения)

Содержат use cases и координируют работу доменных сущностей и репозиториев.

```dart
// application/services/user_service.dart
class UserService {
  final IUserRepository userRepository;
  final IEmailService emailService;

  UserService({
    required this.userRepository,
    required this.emailService,
  });

  Future<User> createUser(String email, String name) async {
    // Валидация
    if (email.isEmpty || name.isEmpty) {
      throw ValidationException('Email and name are required');
    }

    // Проверка существования
    final existing = await userRepository.findByEmail(email);
    if (existing != null) {
      throw BusinessException('User with this email already exists');
    }

    // Создание доменной сущности
    final user = User(
      id: generateId(),
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    // Применение бизнес-правил
    if (!user.isValid()) {
      throw ValidationException('Invalid user data');
    }

    // Сохранение
    final savedUser = await userRepository.save(user);

    // Побочные эффекты
    await emailService.sendWelcomeEmail(savedUser.email);

    return savedUser;
  }

  Future<User?> getUserById(String id) async {
    return await userRepository.findById(id);
  }

  Future<void> deleteUser(String id) async {
    final user = await userRepository.findById(id);
    if (user == null) {
      throw NotFoundException('User not found');
    }

    // Применение бизнес-правил
    if (!user.canBeDeleted()) {
      throw BusinessException('User cannot be deleted yet');
    }

    await userRepository.delete(id);
  }
}
```

### Infrastructure (Инфраструктура)

Реализует интерфейсы из домена. Работает с БД, внешними API, файловой системой.

```dart
// infrastructure/repositories/user_repository.dart
class UserRepository implements IUserRepository {
  final Database database;

  UserRepository(this.database);

  @override
  Future<User?> findById(String id) async {
    final result = await database.query(
      'SELECT * FROM users WHERE id = ?',
      [id],
    );
    if (result.isEmpty) return null;
    return _mapToDomain(result.first);
  }

  @override
  Future<User?> findByEmail(String email) async {
    final result = await database.query(
      'SELECT * FROM users WHERE email = ?',
      [email],
    );
    if (result.isEmpty) return null;
    return _mapToDomain(result.first);
  }

  @override
  Future<User> save(User user) async {
    await database.insert('users', {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'created_at': user.createdAt.toIso8601String(),
    });
    return user;
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  User _mapToDomain(Map<String, dynamic> row) {
    return User(
      id: row['id'],
      email: row['email'],
      name: row['name'],
      createdAt: DateTime.parse(row['created_at']),
    );
  }
}
```

```dart
// infrastructure/services/email_service.dart
class EmailService implements IEmailService {
  final SmtpClient smtpClient;

  EmailService(this.smtpClient);

  @override
  Future<void> sendWelcomeEmail(String email) async {
    await smtpClient.send(
      to: email,
      subject: 'Welcome!',
      body: 'Welcome to our service!',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Реализация отправки email для сброса пароля
  }
}
```

### UI / Presentation (Слой представления)

Внешний слой - контроллеры, веб-API, CLI.

```dart
// presentation/controllers/user_controller.dart
class UserController {
  final UserService userService;

  UserController(this.userService);

  Future<Response> createUser(Request request) async {
    try {
      final data = request.body;
      final user = await userService.createUser(
        data['email'],
        data['name'],
      );
      return Response.json({
        'id': user.id,
        'email': user.email,
        'name': user.name,
      }, statusCode: 201);
    } on ValidationException catch (e) {
      return Response.json(
        {'error': e.message},
        statusCode: 400,
      );
    } on BusinessException catch (e) {
      return Response.json(
        {'error': e.message},
        statusCode: 409,
      );
    } catch (e) {
      return Response.json(
        {'error': 'Internal server error'},
        statusCode: 500,
      );
    }
  }

  Future<Response> getUser(String id) async {
    try {
      final user = await userService.getUserById(id);
      if (user == null) {
        return Response.json(
          {'error': 'User not found'},
          statusCode: 404,
        );
      }
      return Response.json({
        'id': user.id,
        'email': user.email,
        'name': user.name,
      });
    } catch (e) {
      return Response.json(
        {'error': 'Internal server error'},
        statusCode: 500,
      );
    }
  }
}
```

## Структура проекта

```
lib/
├── domain/                    # Ядро (независимый)
│   ├── entities/
│   │   └── user.dart
│   └── interfaces/
│       ├── repositories/
│       │   └── user_repository_interface.dart
│       └── services/
│           └── email_service_interface.dart
├── application/               # Сервисы приложения
│   └── services/
│       └── user_service.dart
├── infrastructure/           # Реализации
│   ├── repositories/
│   │   └── user_repository.dart
│   ├── services/
│   │   └── email_service.dart
│   └── database/
│       └── database.dart
└── presentation/             # UI слой
    └── controllers/
        └── user_controller.dart
```

## Правило зависимостей

**Все зависимости направлены внутрь:**

- Domain не зависит ни от чего
- Application зависит только от Domain
- Infrastructure зависит от Domain и Application
- Presentation зависит от Application

```
Presentation → Application → Domain
Infrastructure → Application → Domain
```

## Dependency Inversion

Интерфейсы определены в Domain, реализации в Infrastructure:

```dart
// ✅ Правильно: Интерфейс в Domain
// domain/interfaces/repositories/user_repository_interface.dart
abstract class IUserRepository {
  Future<User?> findById(String id);
}

// ✅ Правильно: Реализация в Infrastructure
// infrastructure/repositories/user_repository.dart
class UserRepository implements IUserRepository {
  // Реализация
}

// ✅ Правильно: Application использует интерфейс
// application/services/user_service.dart
class UserService {
  final IUserRepository repository; // Интерфейс, не реализация
}
```

## Тестирование

Легко тестировать ядро с моками:

```dart
// Тест UserService
class MockUserRepository implements IUserRepository {
  User? userToReturn;
  bool saveCalled = false;

  @override
  Future<User?> findById(String id) async => userToReturn;

  @override
  Future<User?> findByEmail(String email) async => null;

  @override
  Future<User> save(User user) async {
    saveCalled = true;
    return user;
  }

  @override
  Future<void> delete(String id) async {}
}

class MockEmailService implements IEmailService {
  bool emailSent = false;

  @override
  Future<void> sendWelcomeEmail(String email) async {
    emailSent = true;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  test('createUser should save user and send email', () async {
    // Arrange
    final mockRepo = MockUserRepository();
    final mockEmail = MockEmailService();
    final service = UserService(
      userRepository: mockRepo,
      emailService: mockEmail,
    );

    // Act
    final user = await service.createUser('test@test.com', 'Test');

    // Assert
    expect(user.email, 'test@test.com');
    expect(mockRepo.saveCalled, true);
    expect(mockEmail.emailSent, true);
  });
}
```

## Преимущества

- ✅ Полная независимость домена от инфраструктуры
- ✅ Высокая тестируемость - легко мокировать
- ✅ Гибкость - легко заменить инфраструктуру
- ✅ Четкое разделение ответственности
- ✅ Подходит для DDD

## Недостатки

- ❌ Больше абстракций и кода
- ❌ Крутая кривая обучения
- ❌ Может быть избыточно для простых проектов
- ❌ Требует дисциплины от команды

## Отличия от Clean Architecture

| Onion Architecture | Clean Architecture |
|-------------------|-------------------|
| Концентрические слои | Плоские слои |
| Domain в центре | Entities в центре |
| Application Services как отдельный слой | Use Cases как отдельный слой |
| Больше акцент на DDD | Больше акцент на независимость |

## Best Practices

1. **Domain не знает о внешнем мире** - только интерфейсы
2. **Бизнес-правила в Domain** - в сущностях и value objects
3. **Application Services координируют** - не содержат бизнес-логику
4. **Инфраструктура реализует интерфейсы** - из Domain
5. **Используйте Dependency Injection** - для связывания
6. **Тестируйте Domain изолированно** - без инфраструктуры

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - похожий подход
- [Hexagonal Architecture](hexagonal-architecture.md) - порты и адаптеры
- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html) - для сложных доменов

