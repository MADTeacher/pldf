# JWT (JSON Web Tokens) аутентификация

## Описание

JWT - это стандарт для создания токенов доступа, которые позволяют передавать информацию между сторонами в виде JSON объекта. Токен состоит из трех частей: header, payload и signature.

## Когда использовать

- ✅ REST API сервисы
- ✅ SPA приложения (React, Vue, Angular)
- ✅ Мобильные приложения
- ✅ Микросервисная архитектура
- ✅ Когда нужна stateless аутентификация

## Когда НЕ использовать

- ❌ Когда нужен контроль над сессиями на сервере
- ❌ Когда требуется мгновенное разлогинивание всех устройств
- ❌ Для очень чувствительных данных без дополнительных мер безопасности

## Структура JWT

```
header.payload.signature
```

- **Header**: Алгоритм шифрования и тип токена
- **Payload**: Данные пользователя (user ID, роли, время истечения)
- **Signature**: Подпись для проверки подлинности

## Пример реализации

### Backend (Go)

```go
package main

import (
    "context"
    "encoding/json"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
    "net/http"
    "os"
    "strings"
    "time"
)

var jwtSecret = []byte(os.Getenv("JWT_SECRET"))

// Генерация токена при логине
func loginHandler(w http.ResponseWriter, r *http.Request) {
    var credentials struct {
        Email    string `json:"email"`
        Password string `json:"password"`
    }
    
    // Парсинг тела запроса
    if err := json.NewDecoder(r.Body).Decode(&credentials); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }
    
    // Проверка пользователя
    user, err := findUserByEmail(credentials.Email)
    if err != nil || user == nil {
        http.Error(w, "Invalid credentials", http.StatusUnauthorized)
        return
    }
    
    // Проверка пароля
    if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(credentials.Password)); err != nil {
        http.Error(w, "Invalid credentials", http.StatusUnauthorized)
        return
    }
    
    // Генерация JWT токена
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "userId": user.ID,
        "email":  user.Email,
        "exp":    time.Now().Add(time.Hour).Unix(),
    })
    
    tokenString, err := token.SignedString(jwtSecret)
    if err != nil {
        http.Error(w, "Failed to generate token", http.StatusInternalServerError)
        return
    }
    
    json.NewEncoder(w).Encode(map[string]interface{}{
        "token": tokenString,
        "user": map[string]interface{}{
            "id":    user.ID,
            "email": user.Email,
        },
    })
}

// Middleware для проверки токена
func authenticateToken(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        authHeader := r.Header.Get("Authorization")
        if authHeader == "" {
            http.Error(w, "Token required", http.StatusUnauthorized)
            return
        }
        
        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            http.Error(w, "Invalid authorization header", http.StatusUnauthorized)
            return
        }
        
        token, err := jwt.Parse(parts[1], func(token *jwt.Token) (interface{}, error) {
            return jwtSecret, nil
        })
        
        if err != nil || !token.Valid {
            http.Error(w, "Invalid token", http.StatusForbidden)
            return
        }
        
        claims, ok := token.Claims.(jwt.MapClaims)
        if !ok {
            http.Error(w, "Invalid token claims", http.StatusForbidden)
            return
        }
        
        // Сохранение данных пользователя в контекст
        ctx := context.WithValue(r.Context(), "user", claims)
        next(w, r.WithContext(ctx))
    }
}

// Защищенный роут
func profileHandler(w http.ResponseWriter, r *http.Request) {
    user := r.Context().Value("user").(jwt.MapClaims)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "user": user,
    })
}
```

### Frontend (React)

```javascript
// Сохранение токена
const login = async (email, password) => {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  const data = await response.json();
  if (data.token) {
    localStorage.setItem('token', data.token);
  }
};

// Использование токена в запросах
const fetchProfile = async () => {
  const token = localStorage.getItem('token');
  const response = await fetch('/api/profile', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.json();
};
```

## Refresh Tokens

Для повышения безопасности используйте короткоживущие access tokens и долгоживущие refresh tokens:

```go
// Генерация пары токенов
accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
    "userId": user.ID,
    "exp":    time.Now().Add(15 * time.Minute).Unix(),
})
accessTokenString, _ := accessToken.SignedString([]byte(os.Getenv("JWT_SECRET")))

refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
    "userId": user.ID,
    "exp":    time.Now().Add(7 * 24 * time.Hour).Unix(),
})
refreshTokenString, _ := refreshToken.SignedString([]byte(os.Getenv("JWT_REFRESH_SECRET")))

// Сохранение refresh token в базе данных
updateUserRefreshToken(user.ID, refreshTokenString)
```

## Преимущества

- ✅ Stateless - не требует хранения сессий на сервере
- ✅ Масштабируемость - легко масштабировать горизонтально
- ✅ Кроссплатформенность - работает с любыми клиентами
- ✅ Гибкость - можно передавать дополнительную информацию

## Недостатки

- ❌ Невозможно отозвать токен до истечения срока (нужна черная доска токенов)
- ❌ Размер токена больше, чем у сессий
- ❌ Требует дополнительных мер безопасности (HTTPS, короткое время жизни)

## Best Practices

1. **Используйте короткое время жизни access tokens** (15-30 минут)
2. **Храните refresh tokens безопасно** (httpOnly cookies для веба)
3. **Используйте сильный секретный ключ** и храните его в переменных окружения
4. **Валидируйте токены на каждом запросе**
5. **Реализуйте механизм отзыва токенов** (blacklist) для критичных приложений
6. **Не храните чувствительные данные** в payload токена

## Связанные паттерны

- [Refresh Tokens](jwt-auth.md#refresh-tokens) - для обновления токенов
- [Обработка ошибок API](../error-handling/api-error-handling.md) - для обработки ошибок аутентификации

