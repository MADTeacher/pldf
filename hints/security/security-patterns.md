# Паттерны безопасного кодирования

Этот документ содержит безопасные паттерны кодирования для использования в команде `/pldf.security` при анализе кода.

## Безопасная аутентификация

### Использование стойких алгоритмов хеширования

**Плохо:**
```python
import hashlib
password_hash = hashlib.md5(password.encode()).hexdigest()
```

**Хорошо:**
```python
import bcrypt
password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
```

### Проверка паролей

**Плохо:**
```python
if stored_password == input_password:
    # аутентификация успешна
```

**Хорошо:**
```python
import bcrypt
if bcrypt.checkpw(input_password.encode('utf-8'), stored_password_hash):
    # аутентификация успешна
```

### Защита от timing attacks

**Плохо:**
```python
if user.password == input_password:
    # уязвимо к timing attacks
```

**Хорошо:**
```python
import hmac
if hmac.compare_digest(user.password_hash, input_password_hash):
    # защищено от timing attacks
```

---

## Безопасное хранение паролей

### Требования к паролям

**Хорошо:**
```python
import re

def validate_password(password):
    """Валидация пароля с требованиями безопасности"""
    if len(password) < 12:
        return False, "Password must be at least 12 characters"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain lowercase letter"
    if not re.search(r'\d', password):
        return False, "Password must contain digit"
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain special character"
    return True, None
```

### Хранение паролей

**Плохо:**
```python
# Пароли в открытом виде
db.execute("INSERT INTO users (username, password) VALUES (?, ?)", 
           username, password)
```

**Хорошо:**
```python
import bcrypt

def create_user(username, password):
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", 
               username, password_hash)
```

---

## Защита от CSRF

### Использование CSRF токенов

**Плохо:**
```html
<!-- Нет CSRF защиты -->
<form action="/api/transfer" method="POST">
  <input name="amount" type="number">
  <button type="submit">Transfer</button>
</form>
```

**Хорошо:**
```javascript
// Генерация CSRF токена
app.use(csrf({ cookie: true }));

app.get('/form', (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() });
});

// В форме
<form action="/api/transfer" method="POST">
  <input type="hidden" name="_csrf" value="{{csrfToken}}">
  <input name="amount" type="number">
  <button type="submit">Transfer</button>
</form>
```

### SameSite cookies

**Хорошо:**
```javascript
res.cookie('session', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict'  // защита от CSRF
});
```

---

## Защита от XSS

### Санитизация вывода

**Плохо:**
```javascript
// Уязвимо к XSS
document.getElementById('content').innerHTML = userComment;
```

**Хорошо:**
```javascript
// Использование textContent
document.getElementById('content').textContent = userComment;

// Или санитизация с DOMPurify
import DOMPurify from 'dompurify';
document.getElementById('content').innerHTML = DOMPurify.sanitize(userComment);
```

### Content Security Policy

**Хорошо:**
```javascript
app.use((req, res, next) => {
  res.setHeader('Content-Security-Policy', 
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'");
  next();
});
```

---

## Безопасная работа с API

### Валидация входных данных

**Плохо:**
```javascript
app.post('/api/users', (req, res) => {
  const user = req.body;
  db.createUser(user);  // нет валидации
});
```

**Хорошо:**
```javascript
import Joi from 'joi';

const userSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(12).required()
});

app.post('/api/users', (req, res) => {
  const { error, value } = userSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  db.createUser(value);
});
```

### Rate Limiting

**Хорошо:**
```javascript
import rateLimit from 'express-rate-limit';

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 100 // максимум 100 запросов
});

app.use('/api/', apiLimiter);
```

### Аутентификация API

**Хорошо:**
```javascript
// Использование JWT токенов
import jwt from 'jsonwebtoken';

function authenticateToken(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
}

app.get('/api/protected', authenticateToken, (req, res) => {
  res.json({ data: 'protected data' });
});
```

---

## Шифрование данных

### Шифрование при хранении

**Плохо:**
```python
# Данные в открытом виде
db.execute("INSERT INTO users (email, phone) VALUES (?, ?)", 
           email, phone)
```

**Хорошо:**
```python
from cryptography.fernet import Fernet

key = Fernet.generate_key()
cipher = Fernet(key)

def encrypt_data(data):
    return cipher.encrypt(data.encode())

def decrypt_data(encrypted_data):
    return cipher.decrypt(encrypted_data).decode()

# Хранение зашифрованных данных
encrypted_email = encrypt_data(email)
encrypted_phone = encrypt_data(phone)
db.execute("INSERT INTO users (email, phone) VALUES (?, ?)", 
           encrypted_email, encrypted_phone)
```

### Использование HTTPS

**Хорошо:**
```javascript
// Принудительное использование HTTPS в production
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.header('x-forwarded-proto') !== 'https') {
      res.redirect(`https://${req.header('host')}${req.url}`);
    } else {
      next();
    }
  });
}
```

---

## Безопасное логирование

### Не логировать секреты

**Плохо:**
```javascript
console.log('User login:', { username, password });
logger.info('API call:', { apiKey, secret });
```

**Хорошо:**
```javascript
// Удаление секретов перед логированием
const { password, ...userWithoutPassword } = user;
console.log('User login:', userWithoutPassword);

// Или использование специальных функций
function sanitizeForLogging(data) {
  const sensitiveFields = ['password', 'apiKey', 'secret', 'token'];
  const sanitized = { ...data };
  sensitiveFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '***REDACTED***';
    }
  });
  return sanitized;
}

logger.info('API call:', sanitizeForLogging({ apiKey, secret }));
```

### Структурированное логирование

**Хорошо:**
```python
import logging
import json

logger = logging.getLogger(__name__)

def log_security_event(event_type, user_id, ip_address, details=None):
    log_data = {
        'event_type': event_type,
        'user_id': user_id,
        'ip_address': ip_address,
        'timestamp': datetime.utcnow().isoformat(),
        'details': sanitize_for_logging(details)
    }
    logger.info(json.dumps(log_data))
```

---

## Управление секретами

### Использование переменных окружения

**Плохо:**
```javascript
const API_KEY = "sk_live_1234567890abcdef";
const DB_PASSWORD = "mypassword123";
```

**Хорошо:**
```javascript
const API_KEY = process.env.API_KEY;
const DB_PASSWORD = process.env.DB_PASSWORD;

if (!API_KEY || !DB_PASSWORD) {
  throw new Error('Required environment variables are not set');
}
```

### Использование secrets manager

**Хорошо:**
```python
import boto3
import os

def get_secret(secret_name):
    if os.getenv('USE_SECRETS_MANAGER') == 'true':
        client = boto3.client('secretsmanager')
        response = client.get_secret_value(SecretId=secret_name)
        return response['SecretString']
    else:
        return os.getenv(secret_name)
```

---

## Валидация и санитизация

### Валидация на сервере

**Плохо:**
```javascript
// Валидация только на клиенте
// На сервере нет проверки
app.post('/api/users', (req, res) => {
  db.createUser(req.body);
});
```

**Хорошо:**
```javascript
// Валидация на сервере
import validator from 'validator';

function validateUserInput(user) {
  if (!validator.isEmail(user.email)) {
    throw new Error('Invalid email');
  }
  if (!validator.isLength(user.username, { min: 3, max: 30 })) {
    throw new Error('Invalid username length');
  }
  if (!validator.isStrongPassword(user.password)) {
    throw new Error('Password is too weak');
  }
  return true;
}

app.post('/api/users', (req, res) => {
  try {
    validateUserInput(req.body);
    db.createUser(req.body);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

### Санитизация входных данных

**Хорошо:**
```python
import html
import re

def sanitize_input(user_input):
    # Удаление HTML тегов
    sanitized = re.sub(r'<[^>]+>', '', user_input)
    # Экранирование специальных символов
    sanitized = html.escape(sanitized)
    return sanitized
```

---

## Защита от SQL Injection

### Параметризованные запросы

**Плохо:**
```python
query = f"SELECT * FROM users WHERE username = '{username}'"
db.execute(query)
```

**Хорошо:**
```python
query = "SELECT * FROM users WHERE username = ?"
db.execute(query, (username,))
```

### Использование ORM

**Хорошо:**
```javascript
// Использование ORM вместо raw queries
const user = await User.findOne({ where: { username: username } });
```

---

## Защита от Path Traversal

**Плохо:**
```python
filename = request.args.get('file')
with open(f'/uploads/{filename}', 'r') as f:
    # уязвимо к path traversal
    content = f.read()
```

**Хорошо:**
```python
import os

filename = request.args.get('file')
# Нормализация пути
safe_path = os.path.normpath(f'/uploads/{filename}')
# Проверка, что путь находится в разрешенной директории
if not safe_path.startswith('/uploads/'):
    raise ValueError('Invalid file path')
with open(safe_path, 'r') as f:
    content = f.read()
```

---

## Общие принципы

### Принцип наименьших привилегий

- Пользователи и процессы должны иметь только минимально необходимые права
- Регулярно пересматривать права доступа
- Использовать отдельные учетные записи для разных целей

### Defense in Depth

- Множественные уровни защиты
- Не полагаться на одну меру безопасности
- Комбинация технических и организационных мер

### Fail Secure

- При ошибках система должна переходить в безопасное состояние
- По умолчанию запрещать доступ
- Явно разрешать доступ только когда это безопасно

### Keep It Simple

- Простые решения легче понять и проверить
- Избегать излишней сложности
- Использовать проверенные библиотеки и фреймворки

---

**Примечание**: Это базовые паттерны безопасного кодирования. Для более детального изучения обратитесь к OWASP Cheat Sheets и официальной документации по безопасности.


