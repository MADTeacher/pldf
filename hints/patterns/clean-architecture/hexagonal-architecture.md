# Hexagonal Architecture (Ports & Adapters)

## Описание

Hexagonal Architecture (Гексагональная архитектура), также известная как Ports & Adapters, изолирует бизнес-логику приложения от внешних зависимостей через порты (интерфейсы) и адаптеры (реализации). Приложение представлено как шестиугольник, где ядро - это бизнес-логика, а адаптеры подключаются к портам.

## Когда использовать

- ✅ Когда нужно изолировать бизнес-логику от внешних систем
- ✅ Когда приложение взаимодействует с множеством внешних систем
- ✅ Когда нужна легкая замена внешних зависимостей (БД, API, UI)
- ✅ Для микросервисов с четкими границами
- ✅ Когда важна тестируемость бизнес-логики

## Когда НЕ использовать

- ❌ Очень простые приложения
- ❌ Когда нет множества внешних зависимостей
- ❌ Краткосрочные проекты

## Концепция

```
        ┌─────────────────┐
        │   Application   │  ← Ядро (бизнес-логика)
        │   (Domain)      │
        └────────┬────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│ Port  │    │ Port  │    │ Port  │  ← Порты (интерфейсы)
└───┬───┘    └───┬───┘    └───┬───┘
    │            │            │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Adapter│    │Adapter│    │Adapter│  ← Адаптеры (реализации)
└───────┘    └───────┘    └───────┘
   UI          DB          API
```

## Порты (Ports)

Порты - это интерфейсы, которые определяют, как приложение взаимодействует с внешним миром.

### Primary Ports (Входящие порты)

Определяют, как внешний мир использует приложение (например, UI, API endpoints).

```dart
// ports/in/user_service_port.dart
abstract class UserServicePort {
  Future<User> createUser(String email, String name);
  Future<User?> getUserById(String id);
  Future<List<User>> getAllUsers();
}
```

### Secondary Ports (Исходящие порты)

Определяют, что приложению нужно от внешнего мира (например, БД, внешние API).

```dart
// ports/out/user_repository_port.dart
abstract class UserRepositoryPort {
  Future<User> save(User user);
  Future<User?> findById(String id);
  Future<List<User>> findAll();
}

// ports/out/email_service_port.dart
abstract class EmailServicePort {
  Future<void> sendWelcomeEmail(String email);
}
```

## Адаптеры (Adapters)

Адаптеры - это реализации портов, которые связывают приложение с конкретными технологиями.

### Primary Adapters (Входящие адаптеры)

Реализуют входящие порты (UI, REST API, CLI и т.д.).

```dart
// adapters/in/rest/user_controller.dart
class UserController {
  final UserServicePort userService;

  UserController(this.userService);

  Future<Response> createUser(Request request) async {
    try {
      final data = request.body;
      final user = await userService.createUser(
        data['email'],
        data['name'],
      );
      return Response.json({'id': user.id, 'email': user.email});
    } catch (e) {
      return Response.json({'error': e.toString()}, statusCode: 400);
    }
  }
}
```

```dart
// adapters/in/cli/user_cli.dart
class UserCLI {
  final UserServicePort userService;

  UserCLI(this.userService);

  Future<void> handleCreateUser(List<String> args) async {
    final email = args[0];
    final name = args[1];
    final user = await userService.createUser(email, name);
    print('User created: ${user.id}');
  }
}
```

### Secondary Adapters (Исходящие адаптеры)

Реализуют исходящие порты (БД, внешние API, файловая система).

```dart
// adapters/out/persistence/user_repository_adapter.dart
class UserRepositoryAdapter implements UserRepositoryPort {
  final Database database;

  UserRepositoryAdapter(this.database);

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
  Future<User?> findById(String id) async {
    final row = await database.query('SELECT * FROM users WHERE id = ?', [id]);
    if (row.isEmpty) return null;
    return _mapToUser(row.first);
  }

  @override
  Future<List<User>> findAll() async {
    final rows = await database.query('SELECT * FROM users');
    return rows.map((row) => _mapToUser(row)).toList();
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

```dart
// adapters/out/email/smtp_email_adapter.dart
class SmtpEmailAdapter implements EmailServicePort {
  final SmtpClient smtpClient;

  SmtpEmailAdapter(this.smtpClient);

  @override
  Future<void> sendWelcomeEmail(String email) async {
    await smtpClient.send(
      to: email,
      subject: 'Welcome!',
      body: 'Welcome to our service!',
    );
  }
}
```

## Ядро приложения (Application Core)

Ядро содержит бизнес-логику и зависит только от портов, не от адаптеров.

```dart
// domain/user.dart
class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  bool isValid() {
    return email.contains('@') && name.isNotEmpty;
  }
}
```

```dart
// application/user_service.dart
class UserService implements UserServicePort {
  final UserRepositoryPort repository;
  final EmailServicePort emailService;

  UserService({
    required this.repository,
    required this.emailService,
  });

  @override
  Future<User> createUser(String email, String name) async {
    // Бизнес-логика
    if (email.isEmpty || name.isEmpty) {
      throw ValidationException('Email and name are required');
    }

    final user = User(
      id: generateId(),
      email: email,
      name: name,
    );

    if (!user.isValid()) {
      throw ValidationException('Invalid user data');
    }

    // Сохранение через порт (не знаем, какая БД)
    final savedUser = await repository.save(user);

    // Отправка email через порт (не знаем, какой email сервис)
    await emailService.sendWelcomeEmail(savedUser.email);

    return savedUser;
  }

  @override
  Future<User?> getUserById(String id) async {
    return await repository.findById(id);
  }

  @override
  Future<List<User>> getAllUsers() async {
    return await repository.findAll();
  }
}
```

## Структура проекта

```
lib/
├── domain/                    # Доменные модели
│   └── user.dart
├── application/               # Бизнес-логика
│   └── user_service.dart
├── ports/
│   ├── in/                   # Входящие порты
│   │   └── user_service_port.dart
│   └── out/                  # Исходящие порты
│       ├── user_repository_port.dart
│       └── email_service_port.dart
└── adapters/
    ├── in/                   # Входящие адаптеры
    │   ├── rest/
    │   │   └── user_controller.dart
    │   └── cli/
    │       └── user_cli.dart
    └── out/                  # Исходящие адаптеры
        ├── persistence/
        │   └── user_repository_adapter.dart
        └── email/
            └── smtp_email_adapter.dart
```

## Dependency Injection

Связывание портов и адаптеров происходит через Dependency Injection:

```dart
// main.dart
void main() {
  // Создаем адаптеры
  final database = Database();
  final smtpClient = SmtpClient();
  
  final userRepository = UserRepositoryAdapter(database);
  final emailService = SmtpEmailAdapter(smtpClient);
  
  // Создаем сервис с зависимостями через порты
  final userService = UserService(
    repository: userRepository,
    emailService: emailService,
  );
  
  // Создаем контроллеры с сервисом
  final userController = UserController(userService);
  
  // Запускаем приложение
  runApp(userController);
}
```

## Тестирование

Легко тестировать ядро с мок-адаптерами:

```dart
// Тест UserService
class MockUserRepository implements UserRepositoryPort {
  User? userToReturn;
  
  @override
  Future<User> save(User user) async {
    return userToReturn ?? user;
  }
  
  @override
  Future<User?> findById(String id) async => null;
  
  @override
  Future<List<User>> findAll() async => [];
}

class MockEmailService implements EmailServicePort {
  bool emailSent = false;
  
  @override
  Future<void> sendWelcomeEmail(String email) async {
    emailSent = true;
  }
}

void main() {
  test('createUser should save user and send email', () async {
    // Arrange
    final mockRepo = MockUserRepository();
    final mockEmail = MockEmailService();
    final service = UserService(
      repository: mockRepo,
      emailService: mockEmail,
    );
    
    // Act
    final user = await service.createUser('test@test.com', 'Test');
    
    // Assert
    expect(user.email, 'test@test.com');
    expect(mockEmail.emailSent, true);
  });
}
```

## Преимущества

- ✅ Полная изоляция бизнес-логики
- ✅ Легкая замена адаптеров (БД, UI, внешние сервисы)
- ✅ Высокая тестируемость
- ✅ Ясное разделение ответственности
- ✅ Подходит для микросервисов

## Недостатки

- ❌ Больше абстракций и кода
- ❌ Крутая кривая обучения
- ❌ Может быть избыточно для простых проектов

## Best Practices

1. **Ядро не знает об адаптерах** - только о портах
2. **Один порт = одна ответственность** - не смешивайте
3. **Адаптеры тонкие** - только преобразование данных
4. **Используйте Dependency Injection** - для связывания
5. **Тестируйте ядро изолированно** - с моками адаптеров

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - похожий подход с слоями
- [Onion Architecture](onion-architecture.md) - концентрические слои
- [Repository Pattern](../data-fetching/) - для работы с данными

