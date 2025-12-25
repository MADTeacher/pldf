# Структура Backend проектов

## Описание

Рекомендации по организации структуры серверных приложений с применением принципов чистой архитектуры. Рассматриваются различные подходы для разных языков и фреймворков.

## Когда использовать

- ✅ Backend приложения любого размера
- ✅ REST API, GraphQL API
- ✅ Микросервисы
- ✅ Долгосрочные проекты

## Общие подходы

### 1. Layered Architecture (Многослойная)

Классический подход с разделением на слои.

```
src/
├── controllers/              # HTTP handlers
├── services/                 # Бизнес-логика
├── repositories/             # Доступ к данным
├── models/                   # Модели данных
└── utils/                    # Утилиты
```

### 2. Clean Architecture

С разделением на domain, use cases, adapters.

```
src/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── repositories/
│   ├── datasources/
│   └── models/
├── presentation/
│   └── controllers/
└── infrastructure/
    ├── database/
    └── external/
```

### 3. Feature-based

Организация по функциональным модулям.

```
src/
├── features/
│   ├── users/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── repositories/
│   │   └── models/
│   └── orders/
│       ├── controllers/
│       ├── services/
│       ├── repositories/
│       └── models/
└── shared/
```

## Примеры для разных технологий

### Go

#### Структура проекта

```
cmd/
└── server/
    └── main.go
internal/
├── config/                   # Конфигурация
│   └── database.go
├── domain/                   # Бизнес-логика
│   ├── entities/
│   │   └── user.go
│   ├── repositories/
│   │   └── user_repository.go
│   └── usecases/
│       ├── create_user.go
│       └── get_user.go
├── data/                     # Реализации
│   ├── repositories/
│   │   └── user_repository_impl.go
│   ├── datasources/
│   │   └── user_datasource.go
│   └── models/
│       └── user_model.go
└── presentation/             # HTTP слой
    ├── handlers/
    │   └── user_handler.go
    ├── routes/
    │   └── user_routes.go
    └── middleware/
        ├── auth.go
        └── error_handler.go
pkg/
└── utils/
```

#### Domain слой

```go
// internal/domain/entities/user.go
package entities

import "time"

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}

func (u *User) IsValid() bool {
    return len(u.Email) > 0 && 
           len(u.Name) > 0 && 
           contains(u.Email, "@")
}

func contains(s, substr string) bool {
    return len(s) >= len(substr) && 
           (s == substr || len(substr) == 0 || 
            indexOfSubstring(s, substr) >= 0)
}

func indexOfSubstring(s, substr string) int {
    for i := 0; i <= len(s)-len(substr); i++ {
        if s[i:i+len(substr)] == substr {
            return i
        }
    }
    return -1
}
```

```go
// internal/domain/repositories/user_repository.go
package repositories

import "github.com/example/app/internal/domain/entities"

type UserRepository interface {
    FindByID(id string) (*entities.User, error)
    FindByEmail(email string) (*entities.User, error)
    Save(user *entities.User) error
    FindAll() ([]*entities.User, error)
}
```

```go
// internal/domain/usecases/create_user.go
package usecases

import (
    "errors"
    "github.com/example/app/internal/domain/entities"
    "github.com/example/app/internal/domain/repositories"
    "time"
    "github.com/google/uuid"
)

type CreateUser struct {
    repo repositories.UserRepository
}

func NewCreateUser(repo repositories.UserRepository) *CreateUser {
    return &CreateUser{repo: repo}
}

func (uc *CreateUser) Execute(email, name string) (*entities.User, error) {
    // Бизнес-логика
    if email == "" || name == "" {
        return nil, errors.New("email and name are required")
    }

    existingUser, _ := uc.repo.FindByEmail(email)
    if existingUser != nil {
        return nil, errors.New("user with this email already exists")
    }

    user := &entities.User{
        ID:        uuid.New().String(),
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
    }

    if !user.IsValid() {
        return nil, errors.New("invalid user data")
    }

    if err := uc.repo.Save(user); err != nil {
        return nil, err
    }

    return user, nil
}
```

#### Data слой

```go
// internal/data/repositories/user_repository_impl.go
package repositories

import (
    "github.com/example/app/internal/domain/entities"
    "github.com/example/app/internal/domain/repositories"
    "github.com/example/app/internal/data/datasources"
)

type UserRepositoryImpl struct {
    dataSource datasources.UserDataSource
}

func NewUserRepository(dataSource datasources.UserDataSource) repositories.UserRepository {
    return &UserRepositoryImpl{dataSource: dataSource}
}

func (r *UserRepositoryImpl) FindByID(id string) (*entities.User, error) {
    data, err := r.dataSource.FindByID(id)
    if err != nil || data == nil {
        return nil, err
    }
    return r.toDomain(data), nil
}

func (r *UserRepositoryImpl) FindByEmail(email string) (*entities.User, error) {
    data, err := r.dataSource.FindByEmail(email)
    if err != nil || data == nil {
        return nil, err
    }
    return r.toDomain(data), nil
}

func (r *UserRepositoryImpl) Save(user *entities.User) error {
    data := r.toData(user)
    saved, err := r.dataSource.Save(data)
    if err != nil {
        return err
    }
    *user = *r.toDomain(saved)
    return nil
}

func (r *UserRepositoryImpl) FindAll() ([]*entities.User, error) {
    dataList, err := r.dataSource.FindAll()
    if err != nil {
        return nil, err
    }
    
    users := make([]*entities.User, len(dataList))
    for i, data := range dataList {
        users[i] = r.toDomain(data)
    }
    return users, nil
}

func (r *UserRepositoryImpl) toDomain(data *datasources.UserData) *entities.User {
    return &entities.User{
        ID:        data.ID,
        Email:     data.Email,
        Name:      data.Name,
        CreatedAt: data.CreatedAt,
    }
}

func (r *UserRepositoryImpl) toData(user *entities.User) *datasources.UserData {
    return &datasources.UserData{
        ID:        user.ID,
        Email:     user.Email,
        Name:      user.Name,
        CreatedAt: user.CreatedAt,
    }
}
```

#### Presentation слой

```go
// internal/presentation/handlers/user_handler.go
package handlers

import (
    "encoding/json"
    "net/http"
    "github.com/example/app/internal/domain/usecases"
    "github.com/gorilla/mux"
)

type UserHandler struct {
    createUser *usecases.CreateUser
    getUser    *usecases.GetUser
}

func NewUserHandler(createUser *usecases.CreateUser, getUser *usecases.GetUser) *UserHandler {
    return &UserHandler{
        createUser: createUser,
        getUser:    getUser,
    }
}

func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
    var req struct {
        Email string `json:"email"`
        Name  string `json:"name"`
    }

    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }

    user, err := h.createUser.Execute(req.Email, req.Name)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "id":    user.ID,
        "email": user.Email,
        "name":  user.Name,
    })
}

func (h *UserHandler) GetByID(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id := vars["id"]
    if id == "" {
        http.Error(w, "ID is required", http.StatusBadRequest)
        return
    }

    user, err := h.getUser.Execute(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    if user == nil {
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "id":    user.ID,
        "email": user.Email,
        "name":  user.Name,
    })
}
```

```go
// internal/presentation/routes/user_routes.go
package routes

import (
    "github.com/example/app/internal/presentation/handlers"
    "github.com/gorilla/mux"
)

func SetupUserRoutes(router *mux.Router, userHandler *handlers.UserHandler) {
    router.HandleFunc("/users", userHandler.Create).Methods("POST")
    router.HandleFunc("/users/{id}", userHandler.GetByID).Methods("GET")
}
```

### Python / FastAPI

#### Структура проекта

```
src/
├── app/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── data/
│   │   ├── repositories/
│   │   └── models/
│   ├── presentation/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       └── endpoints/
│   │   └── schemas/
│   └── infrastructure/
│       └── database/
└── main.py
```

#### Domain слой

```python
# app/domain/entities/user.py
from dataclasses import dataclass
from datetime import datetime

@dataclass
class User:
    id: str
    email: str
    name: str
    created_at: datetime

    def is_valid(self) -> bool:
        return '@' in self.email and len(self.name) > 0
```

```python
# app/domain/repositories/user_repository.py
from abc import ABC, abstractmethod
from app.domain.entities.user import User

class IUserRepository(ABC):
    @abstractmethod
    async def find_by_id(self, user_id: str) -> User | None:
        pass

    @abstractmethod
    async def find_by_email(self, email: str) -> User | None:
        pass

    @abstractmethod
    async def save(self, user: User) -> User:
        pass
```

```python
# app/domain/usecases/create_user.py
from app.domain.entities.user import User
from app.domain.repositories.user_repository import IUserRepository
from datetime import datetime
import uuid

class CreateUser:
    def __init__(self, user_repository: IUserRepository):
        self.user_repository = user_repository

    async def execute(self, email: str, name: str) -> User:
        if not email or not name:
            raise ValueError("Email and name are required")

        existing_user = await self.user_repository.find_by_email(email)
        if existing_user:
            raise ValueError("User with this email already exists")

        user = User(
            id=str(uuid.uuid4()),
            email=email,
            name=name,
            created_at=datetime.now(),
        )

        if not user.is_valid():
            raise ValueError("Invalid user data")

        return await self.user_repository.save(user)
```

#### Data слой

```python
# app/data/repositories/user_repository_impl.py
from app.domain.repositories.user_repository import IUserRepository
from app.domain.entities.user import User
from app.data.models.user_model import UserModel
from app.infrastructure.database.session import get_db

class UserRepositoryImpl(IUserRepository):
    async def find_by_id(self, user_id: str) -> User | None:
        db = next(get_db())
        user_model = db.query(UserModel).filter(UserModel.id == user_id).first()
        if not user_model:
            return None
        return self._to_domain(user_model)

    async def find_by_email(self, email: str) -> User | None:
        db = next(get_db())
        user_model = db.query(UserModel).filter(UserModel.email == email).first()
        if not user_model:
            return None
        return self._to_domain(user_model)

    async def save(self, user: User) -> User:
        db = next(get_db())
        user_model = UserModel(
            id=user.id,
            email=user.email,
            name=user.name,
            created_at=user.created_at,
        )
        db.add(user_model)
        db.commit()
        db.refresh(user_model)
        return self._to_domain(user_model)

    def _to_domain(self, model: UserModel) -> User:
        return User(
            id=model.id,
            email=model.email,
            name=model.name,
            created_at=model.created_at,
        )
```

#### Presentation слой

```python
# app/presentation/schemas/user_schema.py
from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    name: str

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime

    class Config:
        from_attributes = True
```

```python
# app/presentation/api/v1/endpoints/users.py
from fastapi import APIRouter, Depends, HTTPException
from app.presentation.schemas.user_schema import UserCreate, UserResponse
from app.domain.usecases.create_user import CreateUser
from app.data.repositories.user_repository_impl import UserRepositoryImpl

router = APIRouter()

def get_create_user_use_case() -> CreateUser:
    repository = UserRepositoryImpl()
    return CreateUser(repository)

@router.post("/users", response_model=UserResponse, status_code=201)
async def create_user(
    user_data: UserCreate,
    create_user_use_case: CreateUser = Depends(get_create_user_use_case),
):
    try:
        user = await create_user_use_case.execute(user_data.email, user_data.name)
        return UserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            created_at=user.created_at,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

### Go

#### Структура проекта

```
cmd/
└── server/
    └── main.go
internal/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── repositories/
│   └── models/
└── presentation/
    ├── handlers/
    └── routes/
pkg/
└── utils/
```

#### Domain слой

```go
// internal/domain/entities/user.go
package entities

import "time"

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}

func (u *User) IsValid() bool {
    return len(u.Email) > 0 && len(u.Name) > 0
}
```

```go
// internal/domain/repositories/user_repository.go
package repositories

import "github.com/example/app/internal/domain/entities"

type UserRepository interface {
    FindByID(id string) (*entities.User, error)
    FindByEmail(email string) (*entities.User, error)
    Save(user *entities.User) error
}
```

```go
// internal/domain/usecases/create_user.go
package usecases

import (
    "errors"
    "github.com/example/app/internal/domain/entities"
    "github.com/example/app/internal/domain/repositories"
    "time"
    "github.com/google/uuid"
)

type CreateUser struct {
    repo repositories.UserRepository
}

func NewCreateUser(repo repositories.UserRepository) *CreateUser {
    return &CreateUser{repo: repo}
}

func (uc *CreateUser) Execute(email, name string) (*entities.User, error) {
    if email == "" || name == "" {
        return nil, errors.New("email and name are required")
    }

    existing, _ := uc.repo.FindByEmail(email)
    if existing != nil {
        return nil, errors.New("user with this email already exists")
    }

    user := &entities.User{
        ID:        uuid.New().String(),
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
    }

    if !user.IsValid() {
        return nil, errors.New("invalid user data")
    }

    if err := uc.repo.Save(user); err != nil {
        return nil, err
    }

    return user, nil
}
```

## Best Practices

1. **Разделяйте слои** - domain, data, presentation
2. **Используйте интерфейсы** - для репозиториев и сервисов
3. **Dependency Injection** - для управления зависимостями
4. **Обработка ошибок** - явная обработка на каждом слое
5. **Валидация** - на уровне use cases
6. **Тестирование** - unit тесты для use cases, интеграционные для API
7. **Документация** - OpenAPI/Swagger для API

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - общие принципы
- [Repository Pattern](../data-fetching/) - для работы с данными
- [Service Layer](layered-architecture.md) - для бизнес-логики

