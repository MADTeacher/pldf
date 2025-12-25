# OAuth 2.0 аутентификация

## Описание

OAuth 2.0 - это протокол авторизации, который позволяет приложениям получать ограниченный доступ к пользовательским аккаунтам на внешних сервисах (Google, GitHub, Facebook и т.д.). Пользователь авторизуется через провайдера, а ваше приложение получает токен доступа.

## Когда использовать

- ✅ Упрощение регистрации пользователей
- ✅ Интеграция с социальными сетями
- ✅ Когда пользователи уже имеют аккаунты в популярных сервисах
- ✅ Когда нужно получить доступ к данным пользователя из внешнего сервиса

## Когда НЕ использовать

- ❌ Когда нужна полная независимость от внешних сервисов
- ❌ Для критичных приложений, где важна полная контроль над аутентификацией
- ❌ Когда провайдеры OAuth недоступны или нестабильны

## Поток OAuth 2.0

1. Пользователь нажимает "Войти через Google"
2. Перенаправление на страницу авторизации провайдера
3. Пользователь авторизуется у провайдера
4. Провайдер перенаправляет обратно с authorization code
5. Приложение обменивает code на access token
6. Приложение использует access token для получения данных пользователя

## Пример реализации

### Backend (Python + Flask + Authlib)

```python
from flask import Flask, redirect, url_for, session, jsonify
from authlib.integrations.flask_client import OAuth
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

oauth = OAuth(app)
google = oauth.register(
    name='google',
    client_id=os.getenv('GOOGLE_CLIENT_ID'),
    client_secret=os.getenv('GOOGLE_CLIENT_SECRET'),
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={
        'scope': 'openid email profile'
    }
)

# Инициация OAuth потока
@app.route('/api/auth/google')
def google_login():
    redirect_uri = url_for('google_callback', _external=True)
    return google.authorize_redirect(redirect_uri)

# Callback от Google
@app.route('/api/auth/google/callback')
def google_callback():
    token = google.authorize_access_token()
    user_info = token.get('userinfo')
    
    if not user_info:
        return redirect('/login')
    
    # Поиск или создание пользователя
    user = find_user_by_google_id(user_info.get('sub'))
    if not user:
        user = create_user(
            google_id=user_info.get('sub'),
            email=user_info.get('email'),
            name=user_info.get('name'),
            avatar=user_info.get('picture')
        )
    
    # Сохранение в сессии
    session['user_id'] = user.id
    session.permanent = True
    
    return redirect('/dashboard')

# Получение текущего пользователя
@app.route('/api/auth/me')
def get_current_user():
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    user = find_user_by_id(session['user_id'])
    return jsonify({'user': user.to_dict()})
```

### Frontend (React)

```javascript
// Кнопка входа через Google
const GoogleLoginButton = () => {
  const handleGoogleLogin = () => {
    window.location.href = '/api/auth/google';
  };

  return (
    <button onClick={handleGoogleLogin}>
      Войти через Google
    </button>
  );
};

// Проверка статуса аутентификации
const useAuth = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/auth/me')
      .then(res => res.json())
      .then(data => {
        setUser(data.user);
        setLoading(false);
      })
      .catch(() => {
        setUser(null);
        setLoading(false);
      });
  }, []);

  return { user, loading };
};
```

## Популярные провайдеры

### Google
- **Документация**: https://developers.google.com/identity/protocols/oauth2
- **Scopes**: profile, email, calendar, drive и т.д.

### GitHub
- **Документация**: https://docs.github.com/en/apps/oauth-apps
- **Scopes**: user, repo, gist и т.д.

### Facebook
- **Документация**: https://developers.facebook.com/docs/facebook-login
- **Scopes**: email, public_profile и т.д.

## Преимущества

- ✅ Упрощение регистрации - пользователь не создает новый пароль
- ✅ Быстрый старт - пользователь может начать использовать приложение сразу
- ✅ Доверие - пользователи доверяют известным провайдерам
- ✅ Доступ к данным - можно получить профиль, аватар и другую информацию

## Недостатки

- ❌ Зависимость от внешних сервисов
- ❌ Меньше контроля над процессом аутентификации
- ❌ Проблемы с приватностью - провайдер видит, что пользователь использует ваше приложение
- ❌ Может быть сложнее для пользователей без аккаунтов в провайдерах

## Best Practices

1. **Предоставляйте альтернативу** - всегда давайте возможность регистрации через email/пароль
2. **Храните минимальные данные** - запрашивайте только необходимые scopes
3. **Обрабатывайте ошибки** - провайдеры могут быть недоступны
4. **Используйте HTTPS** для всех OAuth запросов
5. **Валидируйте токены** - проверяйте, что токен действительно от провайдера
6. **Храните refresh tokens** для долгоживущих сессий

## Гибридный подход

Можно комбинировать OAuth с собственной аутентификацией:

```python
# Пользователь может войти через Google ИЛИ через email/пароль
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    provider = data.get('provider')
    
    if provider == 'google':
        # OAuth поток
        return redirect(url_for('google_login'))
    else:
        # Обычная аутентификация
        email = data.get('email')
        password = data.get('password')
        user = find_user_by_email(email)
        # ... проверка пароля
```

## Связанные паттерны

- [JWT аутентификация](jwt-auth.md) - для работы с токенами после OAuth
- [Сессионная аутентификация](session-auth.md) - альтернативный подход

