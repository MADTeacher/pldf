# Сессионная аутентификация

## Описание

Сессионная аутентификация использует серверные сессии для хранения состояния аутентификации. При логине создается уникальная сессия, которая хранится на сервере, а клиенту отправляется session ID (обычно в cookie).

## Когда использовать

- ✅ Веб-приложения с серверным рендерингом (SSR)
- ✅ Когда нужен контроль над сессиями на сервере
- ✅ Когда требуется возможность мгновенного разлогинивания
- ✅ Традиционные веб-приложения (Django, Rails, PHP)

## Когда НЕ использовать

- ❌ REST API без серверного рендеринга
- ❌ SPA приложения с отдельным бэкендом
- ❌ Микросервисная архитектура (сложно делиться сессиями)
- ❌ Когда нужна stateless архитектура

## Пример реализации

### Backend (Python + Flask)

```python
from flask import Flask, request, jsonify, session
from functools import wraps
from flask_session import Session
import bcrypt
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SESSION_SECRET')
app.config['SESSION_TYPE'] = 'redis'
app.config['SESSION_COOKIE_SECURE'] = os.getenv('FLASK_ENV') == 'production'
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['PERMANENT_SESSION_LIFETIME'] = 86400  # 24 часа

Session(app)

# Логин
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    user = find_user_by_email(email)
    if not user:
        return jsonify({'error': 'Invalid credentials'}), 401
    
    if not bcrypt.checkpw(password.encode('utf-8'), user.password_hash.encode('utf-8')):
        return jsonify({'error': 'Invalid credentials'}), 401
    
    # Создание сессии
    session['user_id'] = user.id
    session['email'] = user.email
    session.permanent = True
    
    return jsonify({
        'message': 'Logged in successfully',
        'user': {'id': user.id, 'email': user.email}
    })

# Middleware для проверки аутентификации
def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

# Защищенный роут
@app.route('/api/profile')
@require_auth
def profile():
    user = find_user_by_id(session['user_id'])
    return jsonify({'user': user.to_dict()})

# Логаут
@app.route('/api/auth/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'message': 'Logged out successfully'})
```

### Хранение сессий в Redis (для масштабирования)

```python
from flask_session import Session
import redis

redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    db=0
)

app.config['SESSION_TYPE'] = 'redis'
app.config['SESSION_REDIS'] = redis_client
app.config['SESSION_COOKIE_SECURE'] = True
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['PERMANENT_SESSION_LIFETIME'] = 86400  # 24 часа

Session(app)
```

## Преимущества

- ✅ Контроль на сервере - можно отозвать сессию в любой момент
- ✅ Безопасность - session ID не содержит данных пользователя
- ✅ Простота - легко реализовать и понять
- ✅ Мгновенное разлогинивание - удаление сессии на сервере

## Недостатки

- ❌ Stateful - требует хранения состояния на сервере
- ❌ Масштабирование - нужен shared storage (Redis) для кластеров
- ❌ Не подходит для REST API без серверного рендеринга
- ❌ Cookie-based - может быть проблемой для мобильных приложений

## Best Practices

1. **Используйте httpOnly cookies** для защиты от XSS атак
2. **Используйте secure flag** в production (HTTPS only)
3. **Установите разумное время жизни сессии** (обычно 24 часа)
4. **Используйте Redis или другую shared storage** для масштабирования
5. **Реализуйте механизм обновления сессии** при активности пользователя
6. **Храните минимум данных в сессии** (только ID пользователя)

## Сравнение с JWT

| Критерий | Сессии | JWT |
|----------|--------|-----|
| Stateful/Stateless | Stateful | Stateless |
| Масштабирование | Требует shared storage | Легко масштабируется |
| Отзыв токена | Мгновенный | До истечения срока |
| Размер | Маленький (session ID) | Больше (весь токен) |
| Подходит для | SSR веб-приложения | REST API, SPA |

## Связанные паттерны

- [JWT аутентификация](jwt-auth.md) - альтернативный подход
- [Обработка ошибок API](../error-handling/api-error-handling.md) - для обработки ошибок аутентификации

