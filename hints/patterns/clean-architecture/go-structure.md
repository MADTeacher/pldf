# Структура Go проектов

## Описание

Рекомендации по организации структуры Go приложений с применением принципов чистой архитектуры. Рассматриваются различные подходы в зависимости от размера и сложности проекта, с учетом особенностей Go: пакетов, интерфейсов и стандартной библиотеки.

## Когда использовать

- ✅ Go приложения любого размера
- ✅ REST API, gRPC сервисы
- ✅ Микросервисы
- ✅ Командная разработка
- ✅ Долгосрочные проекты

## Особенности Go

При организации Go проектов важно учитывать:

1. **Пакеты (packages)** - основная единица организации кода
2. **Интерфейсы** - неявная реализация, идеально для чистой архитектуры
3. **Стандартная библиотека** - богатая stdlib, минимум зависимостей
4. **Идиомы Go** - простота, читаемость, явность
5. **cmd/ и internal/** - стандартные директории для приложений и библиотек

## Подходы к структуре

### 1. Стандартная Go структура (Рекомендуется для большинства проектов)

Следует стандартным конвенциям Go сообщества.

```
project/
├── cmd/                      # Точки входа приложений
│   ├── api/                  # HTTP API сервер
│   │   └── main.go
│   ├── worker/               # Фоновый воркер
│   │   └── main.go
│   └── cli/                  # CLI утилита
│       └── main.go
├── internal/                  # Приватный код приложения
│   ├── domain/               # Бизнес-логика
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── services/
│   ├── handlers/             # HTTP handlers
│   │   └── http/
│   ├── repositories/         # Реализации репозиториев
│   │   ├── postgres/
│   │   └── memory/
│   ├── services/             # Бизнес-сервисы
│   └── config/               # Конфигурация
├── pkg/                      # Публичный код (опционально)
│   ├── errors/
│   └── utils/
├── api/                      # API контракты (опционально)
│   └── openapi.yaml
├── migrations/               # Миграции БД
├── scripts/                  # Вспомогательные скрипты
├── go.mod
├── go.sum
└── README.md
```

**Когда использовать**: Для большинства Go проектов, особенно микросервисов и API серверов.

### 2. Clean Architecture структура

Строгое разделение на слои с четкими зависимостями.

```
project/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── domain/               # Ядро - бизнес-логика
│   │   ├── entities/         # Сущности
│   │   │   └── user.go
│   │   ├── repositories/     # Интерфейсы репозиториев
│   │   │   └── user_repository.go
│   │   └── services/         # Бизнес-сервисы
│   │       └── user_service.go
│   ├── usecases/             # Use cases (опционально)
│   │   └── create_user.go
│   ├── infrastructure/       # Внешние зависимости
│   │   ├── database/
│   │   │   └── postgres/
│   │   ├── repositories/     # Реализации репозиториев
│   │   │   └── postgres/
│   │   └── external/
│   └── delivery/            # Точки входа
│       ├── http/
│       │   ├── handlers/
│       │   └── routes.go
│       └── grpc/
│           └── handlers/
└── pkg/                      # Общие утилиты
    └── errors/
```

**Когда использовать**: Для сложных проектов с богатой бизнес-логикой, когда важна тестируемость и независимость от фреймворков.

### 3. Feature-based структура

Организация по функциональным модулям.

```
project/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── features/             # Функциональные модули
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   └── repository.go
│   │   │   ├── repository/   # Реализация репозитория
│   │   │   ├── service/
│   │   │   └── handler/      # HTTP handlers
│   │   ├── users/
│   │   │   ├── domain/
│   │   │   ├── repository/
│   │   │   ├── service/
│   │   │   └── handler/
│   │   └── orders/
│   │       ├── domain/
│   │       ├── repository/
│   │       ├── service/
│   │       └── handler/
│   ├── shared/               # Общие компоненты
│   │   ├── database/
│   │   ├── middleware/
│   │   └── errors/
│   └── config/
└── pkg/
```

**Когда использовать**: Для больших проектов с четко разделенными доменами, когда разные команды работают над разными фичами.

## Детальная структура (Стандартная Go)

### Domain слой

```go
// internal/domain/entities/user.go
package entities

import "time"

// User представляет пользователя в системе
type User struct {
	ID        string
	Email     string
	Name      string
	CreatedAt time.Time
}

// IsValid проверяет валидность пользователя
func (u *User) IsValid() bool {
	return u.Email != "" && u.Name != "" && len(u.Email) > 3
}
```

```go
// internal/domain/repositories/user_repository.go
package repositories

import (
	"context"
	"myproject/internal/domain/entities"
)

// UserRepository определяет интерфейс для работы с пользователями
type UserRepository interface {
	// FindByID находит пользователя по ID
	FindByID(ctx context.Context, id string) (*entities.User, error)
	
	// FindByEmail находит пользователя по email
	FindByEmail(ctx context.Context, email string) (*entities.User, error)
	
	// Create создает нового пользователя
	Create(ctx context.Context, user *entities.User) error
	
	// Update обновляет пользователя
	Update(ctx context.Context, user *entities.User) error
	
	// Delete удаляет пользователя
	Delete(ctx context.Context, id string) error
}
```

```go
// internal/domain/services/user_service.go
package services

import (
	"context"
	"errors"
	"myproject/internal/domain/entities"
	"myproject/internal/domain/repositories"
)

// UserService содержит бизнес-логику для работы с пользователями
type UserService struct {
	userRepo repositories.UserRepository
}

// NewUserService создает новый UserService
func NewUserService(userRepo repositories.UserRepository) *UserService {
	return &UserService{
		userRepo: userRepo,
	}
}

// CreateUser создает нового пользователя с валидацией
func (s *UserService) CreateUser(ctx context.Context, email, name string) (*entities.User, error) {
	// Проверка существования пользователя
	existing, err := s.userRepo.FindByEmail(ctx, email)
	if err == nil && existing != nil {
		return nil, errors.New("user with this email already exists")
	}
	
	// Создание пользователя
	user := &entities.User{
		Email: email,
		Name:  name,
	}
	
	if !user.IsValid() {
		return nil, errors.New("invalid user data")
	}
	
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}
	
	return user, nil
}

// GetUser получает пользователя по ID
func (s *UserService) GetUser(ctx context.Context, id string) (*entities.User, error) {
	return s.userRepo.FindByID(ctx, id)
}
```

### Infrastructure слой (Repository реализация)

```go
// internal/infrastructure/repositories/postgres/user_repository.go
package postgres

import (
	"context"
	"database/sql"
	"myproject/internal/domain/entities"
	"myproject/internal/domain/repositories"
	"time"
)

// userRepository реализует UserRepository для PostgreSQL
type userRepository struct {
	db *sql.DB
}

// NewUserRepository создает новый userRepository
func NewUserRepository(db *sql.DB) repositories.UserRepository {
	return &userRepository{db: db}
}

// FindByID находит пользователя по ID
func (r *userRepository) FindByID(ctx context.Context, id string) (*entities.User, error) {
	query := `SELECT id, email, name, created_at FROM users WHERE id = $1`
	
	var user entities.User
	var createdAt time.Time
	
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&createdAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	
	user.CreatedAt = createdAt
	return &user, nil
}

// FindByEmail находит пользователя по email
func (r *userRepository) FindByEmail(ctx context.Context, email string) (*entities.User, error) {
	query := `SELECT id, email, name, created_at FROM users WHERE email = $1`
	
	var user entities.User
	var createdAt time.Time
	
	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&createdAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	
	user.CreatedAt = createdAt
	return &user, nil
}

// Create создает нового пользователя
func (r *userRepository) Create(ctx context.Context, user *entities.User) error {
	query := `INSERT INTO users (id, email, name, created_at) VALUES ($1, $2, $3, $4)`
	
	_, err := r.db.ExecContext(ctx, query,
		user.ID,
		user.Email,
		user.Name,
		user.CreatedAt,
	)
	
	return err
}

// Update обновляет пользователя
func (r *userRepository) Update(ctx context.Context, user *entities.User) error {
	query := `UPDATE users SET email = $1, name = $2 WHERE id = $3`
	
	_, err := r.db.ExecContext(ctx, query,
		user.Email,
		user.Name,
		user.ID,
	)
	
	return err
}

// Delete удаляет пользователя
func (r *userRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM users WHERE id = $1`
	
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}
```

### Delivery слой (HTTP Handlers)

```go
// internal/delivery/http/handlers/user_handler.go
package handlers

import (
	"encoding/json"
	"net/http"
	"myproject/internal/domain/services"
)

// UserHandler обрабатывает HTTP запросы для пользователей
type UserHandler struct {
	userService *services.UserService
}

// NewUserHandler создает новый UserHandler
func NewUserHandler(userService *services.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// CreateUserRequest представляет запрос на создание пользователя
type CreateUserRequest struct {
	Email string `json:"email"`
	Name  string `json:"name"`
}

// CreateUserResponse представляет ответ при создании пользователя
type CreateUserResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

// Create обрабатывает POST /users
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	
	user, err := h.userService.CreateUser(r.Context(), req.Email, req.Name)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	response := CreateUserResponse{
		ID:    user.ID,
		Email: user.Email,
		Name:  user.Name,
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// GetByID обрабатывает GET /users/:id
func (h *UserHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "id is required", http.StatusBadRequest)
		return
	}
	
	user, err := h.userService.GetUser(r.Context(), id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	if user == nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}
	
	response := CreateUserResponse{
		ID:    user.ID,
		Email: user.Email,
		Name:  user.Name,
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
```

```go
// internal/delivery/http/routes.go
package http

import (
	"context"
	"myproject/internal/delivery/http/handlers"
	"myproject/internal/domain/services"
	"net/http"
)

// SetupRoutes настраивает маршруты приложения
func SetupRoutes(userService *services.UserService) *http.ServeMux {
	mux := http.NewServeMux()
	
	userHandler := handlers.NewUserHandler(userService)
	
	mux.HandleFunc("POST /users", userHandler.Create)
	mux.HandleFunc("GET /users/{id}", userHandler.GetByID)
	
	return mux
}
```

### Точка входа

```go
// cmd/api/main.go
package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	
	_ "github.com/lib/pq"
	"myproject/internal/delivery/http"
	"myproject/internal/domain/repositories"
	"myproject/internal/domain/services"
	postgresRepo "myproject/internal/infrastructure/repositories/postgres"
)

func main() {
	// Подключение к БД
	db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal("failed to connect to database:", err)
	}
	defer db.Close()
	
	// Инициализация репозиториев
	userRepo := postgresRepo.NewUserRepository(db)
	
	// Инициализация сервисов
	userService := services.NewUserService(userRepo)
	
	// Настройка маршрутов
	mux := http.SetupRoutes(userService)
	
	// Настройка сервера
	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}
	
	// Graceful shutdown
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("server failed:", err)
		}
	}()
	
	log.Println("Server started on :8080")
	
	// Ожидание сигнала для остановки
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	
	log.Println("Shutting down server...")
	
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}
	
	log.Println("Server exited")
}
```

## Дополнительные компоненты

### Обработка ошибок

```go
// pkg/errors/errors.go
package errors

import "fmt"

// DomainError представляет ошибку домена
type DomainError struct {
	Code    string
	Message string
}

func (e *DomainError) Error() string {
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

// NewDomainError создает новую ошибку домена
func NewDomainError(code, message string) *DomainError {
	return &DomainError{
		Code:    code,
		Message: message,
	}
}

// Предопределенные ошибки
var (
	ErrUserNotFound    = NewDomainError("USER_NOT_FOUND", "user not found")
	ErrUserExists      = NewDomainError("USER_EXISTS", "user already exists")
	ErrInvalidInput    = NewDomainError("INVALID_INPUT", "invalid input data")
)
```

### Middleware

```go
// internal/delivery/http/middleware/logging.go
package middleware

import (
	"log"
	"net/http"
	"time"
)

// LoggingMiddleware логирует HTTP запросы
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		next.ServeHTTP(w, r)
		
		log.Printf(
			"%s %s %s %v",
			r.Method,
			r.RequestURI,
			r.RemoteAddr,
			time.Since(start),
		)
	})
}
```

### Конфигурация

```go
// internal/config/config.go
package config

import (
	"os"
	"strconv"
)

// Config содержит конфигурацию приложения
type Config struct {
	DatabaseURL string
	Port        string
	Env         string
}

// Load загружает конфигурацию из переменных окружения
func Load() *Config {
	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://user:pass@localhost/db?sslmode=disable"),
		Port:        getEnv("PORT", "8080"),
		Env:         getEnv("ENV", "development"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
```

## Рекомендации

### 1. Используйте интерфейсы для зависимостей

Интерфейсы в Go идеально подходят для чистой архитектуры:

```go
// Хорошо: интерфейс в domain слое
type UserRepository interface {
	FindByID(ctx context.Context, id string) (*User, error)
}

// Реализация в infrastructure слое
type postgresUserRepository struct {
	db *sql.DB
}
```

### 2. Избегайте циклических зависимостей

- Domain не должен зависеть от других слоев
- Infrastructure зависит от Domain
- Delivery зависит от Domain и Infrastructure

### 3. Используйте context.Context

Всегда передавайте `context.Context` в функции, которые могут быть отменены или имеют таймауты:

```go
func (r *userRepository) FindByID(ctx context.Context, id string) (*User, error) {
	// ...
}
```

### 4. Обрабатывайте ошибки явно

Не игнорируйте ошибки, обрабатывайте их явно:

```go
user, err := repo.FindByID(ctx, id)
if err != nil {
	return nil, fmt.Errorf("failed to find user: %w", err)
}
```

### 5. Используйте go:generate для генерации кода

Для повторяющегося кода (например, моки для тестов):

```go
//go:generate mockgen -source=user_repository.go -destination=mocks/user_repository_mock.go
type UserRepository interface {
	// ...
}
```

### 6. Тестируемость

Благодаря интерфейсам легко создавать моки для тестов:

```go
// В тестах
type mockUserRepository struct {
	users map[string]*User
}

func (m *mockUserRepository) FindByID(ctx context.Context, id string) (*User, error) {
	user, ok := m.users[id]
	if !ok {
		return nil, nil
	}
	return user, nil
}
```

## Когда использовать какую структуру

### Стандартная Go структура
- ✅ Микросервисы
- ✅ REST API серверы
- ✅ Большинство Go проектов
- ✅ Когда команда знакома со стандартами Go

### Clean Architecture
- ✅ Сложная бизнес-логика
- ✅ Высокие требования к тестируемости
- ✅ Возможность смены технологий
- ✅ Большие долгосрочные проекты

### Feature-based
- ✅ Большие проекты с четкими доменами
- ✅ Несколько команд работают параллельно
- ✅ Микросервисная архитектура (каждая фича = сервис)

## Связанные паттерны

- [Clean Architecture](./clean-architecture.md) - общие принципы чистой архитектуры
- [Layered Architecture](./layered-architecture.md) - многослойная архитектура
- [Обработка ошибок](../error-handling/) - паттерны обработки ошибок в Go
- [Получение данных](../data-fetching/) - работа с API и внешними сервисами

