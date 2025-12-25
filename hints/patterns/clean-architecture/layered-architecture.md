# Layered Architecture (Многослойная архитектура)

## Описание

Layered Architecture (Многослойная архитектура) - это классический подход к организации приложения, где код разделен на логические слои с четкими правилами взаимодействия. Каждый слой имеет свою ответственность и может взаимодействовать только с соседними слоями.

## Когда использовать

- ✅ Средние и большие приложения
- ✅ Когда нужна четкая структура
- ✅ Командная разработка
- ✅ Когда бизнес-логика отделена от UI и данных
- ✅ Традиционные веб-приложения

## Когда НЕ использовать

- ❌ Очень простые приложения
- ❌ Когда нужна максимальная гибкость (лучше Clean Architecture)
- ❌ Микросервисы (лучше Domain-driven)

## Структура слоев

```
┌─────────────────────┐
│   Presentation       │  ← UI слой (Controllers, Views)
├─────────────────────┤
│   Business/Service  │  ← Бизнес-логика
├─────────────────────┤
│   Data Access       │  ← Работа с данными
├─────────────────────┤
│   Infrastructure    │  ← БД, внешние сервисы
└─────────────────────┘
```

### Presentation Layer (Слой представления)

Отвечает за взаимодействие с пользователем. Обрабатывает HTTP запросы, валидирует входные данные, возвращает ответы.

```dart
// controllers/user_controller.dart
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
    } catch (e) {
      return Response.json(
        {'error': e.toString()},
        statusCode: 400,
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
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  }
}
```

### Business/Service Layer (Слой бизнес-логики)

Содержит бизнес-правила и логику приложения. Не зависит от деталей UI и БД.

```dart
// services/user_service.dart
class UserService {
  final UserRepository userRepository;
  final EmailService emailService;

  UserService({
    required this.userRepository,
    required this.emailService,
  });

  Future<User> createUser(String email, String name) async {
    // Валидация
    if (email.isEmpty || name.isEmpty) {
      throw ValidationException('Email and name are required');
    }

    if (!email.contains('@')) {
      throw ValidationException('Invalid email format');
    }

    // Бизнес-правила
    final existingUser = await userRepository.findByEmail(email);
    if (existingUser != null) {
      throw BusinessException('User with this email already exists');
    }

    // Создание пользователя
    final user = User(
      id: generateId(),
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    // Сохранение
    final savedUser = await userRepository.save(user);

    // Дополнительная бизнес-логика
    await emailService.sendWelcomeEmail(savedUser.email);

    return savedUser;
  }

  Future<User?> getUserById(String id) async {
    return await userRepository.findById(id);
  }

  Future<List<User>> getAllUsers() async {
    return await userRepository.findAll();
  }

  Future<void> deleteUser(String id) async {
    final user = await userRepository.findById(id);
    if (user == null) {
      throw NotFoundException('User not found');
    }

    // Бизнес-правила для удаления
    // Например, нельзя удалить пользователя с активными заказами
    // ...

    await userRepository.delete(id);
  }
}
```

### Data Access Layer (Слой доступа к данным)

Отвечает за работу с данными: БД, файлы, внешние API. Скрывает детали реализации от бизнес-слоя.

```dart
// repositories/user_repository.dart
abstract class UserRepository {
  Future<User?> findById(String id);
  Future<User?> findByEmail(String email);
  Future<User> save(User user);
  Future<List<User>> findAll();
  Future<void> delete(String id);
}

// repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final Database database;

  UserRepositoryImpl(this.database);

  @override
  Future<User?> findById(String id) async {
    final result = await database.query(
      'SELECT * FROM users WHERE id = ?',
      [id],
    );
    if (result.isEmpty) return null;
    return _mapToUser(result.first);
  }

  @override
  Future<User?> findByEmail(String email) async {
    final result = await database.query(
      'SELECT * FROM users WHERE email = ?',
      [email],
    );
    if (result.isEmpty) return null;
    return _mapToUser(result.first);
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
  Future<List<User>> findAll() async {
    final results = await database.query('SELECT * FROM users');
    return results.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  User _mapToUser(Map<String, dynamic> row) {
    return User(
      id: row['id'],
      email: row['email'],
      name: row['name'],
      createdAt: DateTime.parse(row['created_at']),
    );
  }
}
```

### Infrastructure Layer (Слой инфраструктуры)

Низкоуровневые детали: подключение к БД, работа с файловой системой, внешние API.

```dart
// infrastructure/database/database.dart
class Database {
  late final Connection connection;

  Future<void> connect() async {
    connection = await openConnection();
  }

  Future<List<Map<String, dynamic>>> query(
    String sql,
    List<dynamic>? params,
  ) async {
    // Реализация запроса к БД
    return await connection.query(sql, params);
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    // Реализация вставки
  }

  Future<void> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Реализация удаления
  }
}
```

## Структура проекта

```
lib/
├── controllers/              # Presentation Layer
│   └── user_controller.dart
├── services/                 # Business Layer
│   ├── user_service.dart
│   └── email_service.dart
├── repositories/             # Data Access Layer
│   ├── user_repository.dart
│   └── user_repository_impl.dart
├── models/                   # Модели данных
│   └── user.dart
├── infrastructure/           # Infrastructure Layer
│   ├── database/
│   └── external/
└── main.dart
```

## Правила взаимодействия слоев

1. **Presentation зависит от Business** - контроллеры используют сервисы
2. **Business зависит от Data Access** - сервисы используют репозитории
3. **Data Access зависит от Infrastructure** - репозитории используют БД
4. **Нет обратных зависимостей** - нижние слои не знают о верхних

```
Presentation → Business → Data Access → Infrastructure
```

## Пример полного потока

```dart
// 1. HTTP запрос приходит в Controller
class UserController {
  final UserService userService; // Зависимость от Business Layer

  Future<Response> createUser(Request request) async {
    // 2. Controller вызывает Service
    final user = await userService.createUser(
      request.body['email'],
      request.body['name'],
    );
    // 3. Возвращает ответ
    return Response.json(user.toJson());
  }
}

// 4. Service содержит бизнес-логику
class UserService {
  final UserRepository repository; // Зависимость от Data Access Layer

  Future<User> createUser(String email, String name) async {
    // Бизнес-правила
    if (email.isEmpty) throw ValidationException('Email required');
    
    // 5. Service вызывает Repository
    return await repository.save(User(...));
  }
}

// 6. Repository работает с данными
class UserRepositoryImpl implements UserRepository {
  final Database database; // Зависимость от Infrastructure Layer

  Future<User> save(User user) async {
    // 7. Repository использует Database
    await database.insert('users', user.toMap());
    return user;
  }
}
```

## Преимущества

- ✅ Простота понимания - четкая структура
- ✅ Разделение ответственности - каждый слой имеет свою роль
- ✅ Тестируемость - можно мокировать слои
- ✅ Переиспользование - бизнес-логика не зависит от UI
- ✅ Подходит для традиционных приложений

## Недостатки

- ❌ Может привести к "толстым контроллерам" или "толстым сервисам"
- ❌ Менее гибкая, чем Clean Architecture
- ❌ Может быть избыточной для простых проектов
- ❌ Сложнее тестировать изолированно

## Best Practices

1. **Тонкие контроллеры** - только валидация и вызов сервисов
2. **Бизнес-логика в сервисах** - не в контроллерах или репозиториях
3. **Репозитории только для данных** - без бизнес-логики
4. **Используйте интерфейсы** - для репозиториев и сервисов
5. **Dependency Injection** - для управления зависимостями
6. **Не пропускайте слои** - не вызывайте Repository из Controller

## Анти-паттерны

### ❌ Толстый контроллер

```dart
// ПЛОХО: Бизнес-логика в контроллере
class UserController {
  Future<Response> createUser(Request request) async {
    final email = request.body['email'];
    if (email.isEmpty) {
      return Response.json({'error': 'Email required'}, statusCode: 400);
    }
    
    // Бизнес-логика не должна быть здесь!
    final existing = await database.query('SELECT * FROM users WHERE email = ?', [email]);
    if (existing.isNotEmpty) {
      return Response.json({'error': 'User exists'}, statusCode: 400);
    }
    
    // ...
  }
}
```

### ✅ Правильно: Тонкий контроллер

```dart
// ХОРОШО: Контроллер только вызывает сервис
class UserController {
  final UserService userService;

  Future<Response> createUser(Request request) async {
    try {
      final user = await userService.createUser(
        request.body['email'],
        request.body['name'],
      );
      return Response.json(user.toJson());
    } catch (e) {
      return Response.json({'error': e.toString()}, statusCode: 400);
    }
  }
}
```

### ❌ Пропуск слоя

```dart
// ПЛОХО: Controller напрямую использует Repository
class UserController {
  final UserRepository repository; // Пропущен Service слой!

  Future<Response> createUser(Request request) async {
    final user = await repository.save(User(...)); // Бизнес-логика потеряна!
    return Response.json(user.toJson());
  }
}
```

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - более строгий подход
- [Service Layer Pattern](backend-structure.md) - для backend приложений
- [Repository Pattern](../data-fetching/) - для работы с данными

