# OWASP Top 10 - База знаний для проверки безопасности

Этот документ содержит детальное описание каждой категории OWASP Top 10 2021 для использования в команде `/pldf.security`.

## A01:2021 - Broken Access Control

### Описание уязвимости

Broken Access Control возникает, когда приложение не правильно ограничивает доступ пользователей к ресурсам, к которым они не должны иметь доступа. Это может привести к несанкционированному доступу к данным или функциям.

### Примеры проявления в коде

**Проблема: Отсутствие проверки прав доступа**
```javascript
// Плохо: нет проверки, может ли пользователь получить доступ к ресурсу
app.get('/api/users/:id', (req, res) => {
  const user = User.findById(req.params.id);
  res.json(user);
});
```

**Проблема: Прямая ссылка на объект (IDOR)**
```python
# Плохо: пользователь может получить доступ к чужим данным
def get_user_data(user_id):
    return db.query("SELECT * FROM users WHERE id = ?", user_id)
```

**Проблема: Неправильная проверка ролей**
```java
// Плохо: проверка только на клиенте
if (user.getRole().equals("admin")) {
    // выполнить административное действие
}
```

### Способы обнаружения

1. Проверить наличие middleware/декораторов для проверки прав доступа
2. Поиск endpoints без проверки авторизации
3. Проверить проверки ролей на уровне API, а не только UI
4. Проверить CORS настройки (не должны разрешать все источники)
5. Проверить наличие проверок прав на уровне базы данных

### Методы исправления

**Решение: Проверка прав на уровне API**
```javascript
// Хорошо: проверка прав доступа
app.get('/api/users/:id', authenticate, authorize('read:users'), (req, res) => {
  // Проверка, что пользователь может получить доступ только к своим данным
  if (req.user.id !== req.params.id && !req.user.isAdmin()) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const user = User.findById(req.params.id);
  res.json(user);
});
```

**Решение: Использование RBAC**
```python
# Хорошо: проверка ролей на уровне сервера
@require_permission('read:users')
def get_user_data(user_id, current_user):
    if current_user.id != user_id and not current_user.has_role('admin'):
        raise Forbidden()
    return db.query("SELECT * FROM users WHERE id = ?", user_id)
```

### Ресурсы

- [OWASP Access Control Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP Testing Guide - Authorization](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/README)

---

## A02:2021 - Cryptographic Failures

### Описание уязвимости

Cryptographic Failures (ранее Sensitive Data Exposure) возникают, когда приложение не правильно защищает чувствительные данные с помощью криптографии. Это включает неправильное хранение паролей, использование слабых алгоритмов шифрования, передачу данных по незащищенным каналам.

### Примеры проявления в коде

**Проблема: Хранение паролей в plaintext**
```python
# Плохо: пароли хранятся в открытом виде
def create_user(username, password):
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", 
               username, password)
```

**Проблема: Использование слабых алгоритмов хеширования**
```javascript
// Плохо: MD5 легко взломать
const passwordHash = crypto.createHash('md5').update(password).digest('hex');
```

**Проблема: Hardcoded секреты**
```java
// Плохо: секреты в коде
private static final String API_KEY = "sk_live_1234567890abcdef";
```

**Проблема: Передача данных по HTTP**
```javascript
// Плохо: данные передаются по незащищенному соединению
fetch('http://api.example.com/users', {
  method: 'POST',
  body: JSON.stringify({ password: userPassword })
});
```

### Способы обнаружения

1. Поиск паролей в plaintext в базе данных или коде
2. Проверить использование криптографических библиотек
3. Поиск hardcoded секретов (API ключи, пароли, токены)
4. Проверить использование HTTPS/TLS
5. Проверить алгоритмы хеширования (должны быть bcrypt, argon2, scrypt)
6. Проверить шифрование чувствительных данных при хранении

### Методы исправления

**Решение: Безопасное хранение паролей**
```python
# Хорошо: использование bcrypt
import bcrypt

def create_user(username, password):
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", 
               username, password_hash)
```

**Решение: Использование переменных окружения**
```javascript
// Хорошо: секреты в переменных окружения
const API_KEY = process.env.API_KEY;
if (!API_KEY) {
  throw new Error('API_KEY environment variable is required');
}
```

**Решение: Использование HTTPS**
```javascript
// Хорошо: принудительное использование HTTPS
if (process.env.NODE_ENV === 'production' && !req.secure) {
  return res.redirect('https://' + req.headers.host + req.url);
}
```

### Ресурсы

- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

---

## A03:2021 - Injection

### Описание уязвимости

Injection возникает, когда приложение не правильно валидирует и санитизирует пользовательский ввод перед использованием в запросах, командах или коде. Это может привести к выполнению произвольного кода или несанкционированному доступу к данным.

### Примеры проявления в коде

**Проблема: SQL Injection**
```python
# Плохо: SQL injection уязвимость
def get_user(username):
    query = f"SELECT * FROM users WHERE username = '{username}'"
    return db.execute(query)
```

**Проблема: Code Injection**
```javascript
// Плохо: выполнение произвольного кода
eval(userInput);
```

**Проблема: XSS (Cross-Site Scripting)**
```javascript
// Плохо: небезопасное использование innerHTML
document.getElementById('content').innerHTML = userComment;
```

**Проблема: Command Injection**
```python
# Плохо: выполнение shell команд с пользовательским вводом
import os
os.system(f"ping {user_input}")
```

**Проблема: NoSQL Injection**
```javascript
// Плохо: NoSQL injection
db.users.findOne({ username: req.body.username, password: req.body.password });
```

### Способы обнаружения

1. Поиск SQL queries без параметризации
2. Поиск использования `eval()`, `exec()`, `innerHTML`
3. Поиск вызовов shell команд с пользовательским вводом
4. Проверить валидацию и санитизацию входных данных
5. Проверить использование ORM/query builders вместо raw queries

### Методы исправления

**Решение: Параметризованные запросы**
```python
# Хорошо: параметризованный запрос
def get_user(username):
    query = "SELECT * FROM users WHERE username = ?"
    return db.execute(query, (username,))
```

**Решение: Использование ORM**
```javascript
// Хорошо: использование ORM
const user = await User.findOne({ where: { username: req.body.username } });
```

**Решение: Санитизация для XSS**
```javascript
// Хорошо: использование textContent вместо innerHTML
document.getElementById('content').textContent = userComment;

// Или использование библиотек для санитизации
import DOMPurify from 'dompurify';
document.getElementById('content').innerHTML = DOMPurify.sanitize(userComment);
```

**Решение: Валидация входных данных**
```python
# Хорошо: валидация перед использованием
import re

def validate_username(username):
    if not re.match(r'^[a-zA-Z0-9_]{3,20}$', username):
        raise ValueError('Invalid username')
    return username
```

### Ресурсы

- [OWASP Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Injection_Prevention_Cheat_Sheet.html)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

---

## A04:2021 - Insecure Design

### Описание уязвимости

Insecure Design относится к недостаткам в архитектуре и дизайне приложения, которые приводят к уязвимостям безопасности. Это включает отсутствие threat modeling, неправильные архитектурные решения, отсутствие защиты от известных атак.

### Примеры проявления в коде

**Проблема: Отсутствие rate limiting**
```javascript
// Плохо: нет защиты от brute force атак
app.post('/api/login', async (req, res) => {
  const user = await authenticate(req.body.username, req.body.password);
  if (user) {
    res.json({ token: generateToken(user) });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});
```

**Проблема: Отсутствие защиты от CSRF**
```html
<!-- Плохо: нет CSRF токена -->
<form action="/api/transfer" method="POST">
  <input name="amount" type="number">
  <input name="to_account" type="text">
  <button type="submit">Transfer</button>
</form>
```

**Проблема: Небезопасная архитектура**
```python
# Плохо: все права проверяются только на клиенте
if user.is_admin:
    # выполнить административное действие
```

### Способы обнаружения

1. Проверить наличие threat modeling документации
2. Проверить наличие rate limiting
3. Проверить защиту от CSRF
4. Проверить архитектурные решения безопасности
5. Проверить наличие защиты от известных атак (brute force, DDoS)

### Методы исправления

**Решение: Rate Limiting**
```javascript
// Хорошо: использование rate limiting
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 5 // максимум 5 попыток
});

app.post('/api/login', loginLimiter, async (req, res) => {
  // логика аутентификации
});
```

**Решение: CSRF Protection**
```javascript
// Хорошо: использование CSRF токенов
import csrf from 'csurf';
const csrfProtection = csrf({ cookie: true });

app.use(csrfProtection);

app.get('/form', (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() });
});
```

**Решение: Defense in Depth**
```python
# Хорошо: проверка прав на всех уровнях
@require_permission('admin')
def admin_action():
    # проверка на уровне декоратора
    if not current_user.is_admin:
        raise Forbidden()
    # проверка на уровне бизнес-логики
    # проверка на уровне базы данных
```

### Ресурсы

- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)

---

## A05:2021 - Security Misconfiguration

### Описание уязвимости

Security Misconfiguration возникает, когда приложение не правильно настроено с точки зрения безопасности. Это включает неправильные настройки фреймворков, раскрытие конфиденциальной информации, неправильные настройки CORS, CSP и других заголовков безопасности.

### Примеры проявления в коде

**Проблема: Секреты в конфигурационных файлах**
```json
// Плохо: секреты в конфигурационном файле
{
  "database": {
    "password": "mypassword123"
  },
  "api": {
    "key": "sk_live_1234567890"
  }
}
```

**Проблема: Неправильные настройки CORS**
```javascript
// Плохо: разрешены все источники
app.use(cors({
  origin: '*'
}));
```

**Проблема: Неправильные настройки сессий**
```python
# Плохо: небезопасные настройки сессий
app.config['SESSION_COOKIE_SECURE'] = False
app.config['SESSION_COOKIE_HTTPONLY'] = False
```

**Проблема: Логирование секретов**
```javascript
// Плохо: логирование паролей
console.log('User login:', { username, password });
```

### Способы обнаружения

1. Проверить конфигурационные файлы на секреты
2. Проверить настройки безопасности фреймворков
3. Проверить настройки CORS, CSP headers
4. Проверить настройки сессий и cookies
5. Проверить логирование (не должны логироваться секреты)
6. Проверить настройки production окружения

### Методы исправления

**Решение: Использование переменных окружения**
```javascript
// Хорошо: секреты в переменных окружения
const config = {
  database: {
    password: process.env.DB_PASSWORD
  },
  api: {
    key: process.env.API_KEY
  }
};
```

**Решение: Правильные настройки CORS**
```javascript
// Хорошо: разрешены только нужные источники
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS.split(','),
  credentials: true
}));
```

**Решение: Безопасные настройки сессий**
```python
# Хорошо: безопасные настройки сессий
app.config['SESSION_COOKIE_SECURE'] = True  # только HTTPS
app.config['SESSION_COOKIE_HTTPONLY'] = True  # защита от XSS
app.config['SESSION_COOKIE_SAMESITE'] = 'Strict'  # защита от CSRF
```

**Решение: Безопасное логирование**
```javascript
// Хорошо: не логировать секреты
const { password, ...userWithoutPassword } = user;
console.log('User login:', userWithoutPassword);
```

### Ресурсы

- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)

---

## A06:2021 - Vulnerable and Outdated Components

### Описание уязвимости

Vulnerable and Outdated Components возникают, когда приложение использует библиотеки или фреймворки с известными уязвимостями или устаревшие версии. Это может привести к компрометации приложения через уязвимости в зависимостях.

### Примеры проявления в коде

**Проблема: Устаревшие зависимости**
```json
// Плохо: использование устаревших версий
{
  "dependencies": {
    "express": "4.16.0",  // устаревшая версия
    "lodash": "4.17.10"   // устаревшая версия
  }
}
```

**Проблема: Отсутствие lock файлов**
```json
// Плохо: нет package-lock.json или yarn.lock
{
  "dependencies": {
    "express": "^4.16.0"  // может установиться любая версия
  }
}
```

**Проблема: Использование зависимостей с известными уязвимостями**
```json
// Плохо: зависимость с CVE
{
  "dependencies": {
    "axios": "0.18.0"  // имеет известные уязвимости
  }
}
```

### Способы обнаружения

1. Проверить наличие файлов зависимостей (package.json, requirements.txt)
2. Предложить запустить сканеры уязвимостей (npm audit, pip-audit)
3. Проверить версии зависимостей на устаревание
4. Проверить наличие lock файлов
5. Проверить использование автоматических обновлений зависимостей

### Методы исправления

**Решение: Регулярное обновление зависимостей**
```bash
# Хорошо: регулярное обновление
npm audit fix
npm update
```

**Решение: Использование lock файлов**
```bash
# Хорошо: использование lock файлов
npm install --package-lock-only
# или
yarn install --frozen-lockfile
```

**Решение: Автоматическое сканирование в CI/CD**
```yaml
# Хорошо: автоматическое сканирование в CI/CD
- name: Security audit
  run: |
    npm audit --audit-level=moderate
    pip-audit
```

### Ресурсы

- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [npm audit documentation](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [pip-audit documentation](https://pypi.org/project/pip-audit/)

---

## A07:2021 - Identification and Authentication Failures

### Описание уязвимости

Identification and Authentication Failures возникают, когда приложение неправильно реализует аутентификацию и идентификацию пользователей. Это включает слабые пароли, отсутствие защиты от brute force, неправильное управление сессиями.

### Примеры проявления в коде

**Проблема: Слабые политики паролей**
```python
# Плохо: нет требований к паролю
def validate_password(password):
    return len(password) > 0  # слишком слабо
```

**Проблема: Отсутствие защиты от brute force**
```javascript
// Плохо: нет ограничения попыток входа
app.post('/api/login', async (req, res) => {
  const user = await authenticate(req.body.username, req.body.password);
  // можно пробовать бесконечно
});
```

**Проблема: Небезопасное хранение сессий**
```javascript
// Плохо: сессия в localStorage (уязвимо к XSS)
localStorage.setItem('session', token);
```

**Проблема: Отсутствие MFA**
```python
# Плохо: только пароль, нет двухфакторной аутентификации
def login(username, password):
    user = authenticate(username, password)
    return create_session(user)
```

### Способы обнаружения

1. Проверить реализацию аутентификации
2. Проверить наличие защиты от brute force
3. Проверить политики паролей (минимальная длина, сложность)
4. Проверить наличие MFA (если применимо)
5. Проверить безопасность сессий (токены, cookies)
6. Проверить безопасность восстановления пароля

### Методы исправления

**Решение: Сильные политики паролей**
```python
# Хорошо: требования к паролю
import re

def validate_password(password):
    if len(password) < 12:
        return False, "Password must be at least 12 characters"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain lowercase letter"
    if not re.search(r'\d', password):
        return False, "Password must contain digit"
    if not re.search(r'[!@#$%^&*]', password):
        return False, "Password must contain special character"
    return True, None
```

**Решение: Защита от brute force**
```javascript
// Хорошо: rate limiting для логина
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts, please try again later'
});

app.post('/api/login', loginLimiter, async (req, res) => {
  // логика аутентификации
});
```

**Решение: Безопасное хранение сессий**
```javascript
// Хорошо: httpOnly cookies вместо localStorage
res.cookie('session', token, {
  httpOnly: true,  // защита от XSS
  secure: true,    // только HTTPS
  sameSite: 'strict'  // защита от CSRF
});
```

**Решение: MFA**
```python
# Хорошо: двухфакторная аутентификация
def login(username, password, totp_code):
    user = authenticate(username, password)
    if not verify_totp(user.secret, totp_code):
        raise AuthenticationError('Invalid TOTP code')
    return create_session(user)
```

### Ресурсы

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)

---

## A08:2021 - Software and Data Integrity Failures

### Описание уязвимости

Software and Data Integrity Failures возникают, когда приложение не проверяет целостность программного обеспечения и данных. Это включает отсутствие проверки целостности зависимостей, отсутствие защиты от supply chain атак, отсутствие проверки подписей.

### Примеры проявления в коде

**Проблема: Отсутствие проверки целостности зависимостей**
```json
// Плохо: нет проверки checksums
{
  "dependencies": {
    "some-package": "^1.0.0"
  }
}
```

**Проблема: Использование неподписанных пакетов**
```bash
# Плохо: установка без проверки подписи
npm install some-package
```

**Проблема: Отсутствие защиты от supply chain атак**
```python
# Плохо: выполнение произвольного кода из зависимостей
import malicious_package
malicious_package.run()  # может выполнить вредоносный код
```

### Способы обнаружения

1. Проверить целостность зависимостей (lock files, checksums)
2. Проверить использование подписанных пакетов
3. Проверить защиту от supply chain атак
4. Проверить использование CI/CD для проверки целостности
5. Проверить наличие проверки подписей при установке зависимостей

### Методы исправления

**Решение: Использование lock файлов**
```bash
# Хорошо: использование lock файлов для фиксации версий
npm install --package-lock-only
```

**Решение: Проверка подписей**
```bash
# Хорошо: проверка подписей пакетов
npm install --verify-signatures
```

**Решение: Использование доверенных источников**
```python
# Хорошо: использование только доверенных репозиториев
# requirements.txt должен указывать только на PyPI
# или использовать private registry с проверкой
```

**Решение: CI/CD проверки**
```yaml
# Хорошо: автоматическая проверка в CI/CD
- name: Verify dependencies
  run: |
    npm audit --audit-level=moderate
    npm ci  # использование lock файла
```

### Ресурсы

- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)

---

## A09:2021 - Security Logging and Monitoring Failures

### Описание уязвимости

Security Logging and Monitoring Failures возникают, когда приложение не правильно логирует и мониторит события безопасности. Это включает отсутствие логирования аутентификации, отсутствие мониторинга подозрительной активности, логирование секретов.

### Примеры проявления в коде

**Проблема: Отсутствие логирования аутентификации**
```javascript
// Плохо: нет логирования попыток входа
app.post('/api/login', async (req, res) => {
  const user = await authenticate(req.body.username, req.body.password);
  // нет логирования
});
```

**Проблема: Логирование секретов**
```python
# Плохо: логирование паролей
logger.info(f"User login attempt: {username}, {password}")
```

**Проблема: Отсутствие мониторинга**
```javascript
// Плохо: нет мониторинга подозрительной активности
app.post('/api/admin/delete-all', (req, res) => {
  // критическое действие без логирования
  deleteAllData();
});
```

### Способы обнаружения

1. Проверить наличие логирования безопасности
2. Проверить логирование аутентификации/авторизации
3. Проверить логирование ошибок (без раскрытия секретов)
4. Проверить мониторинг подозрительной активности
5. Проверить наличие alerting системы

### Методы исправления

**Решение: Безопасное логирование**
```javascript
// Хорошо: логирование без секретов
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  const user = await authenticate(username, password);
  
  if (user) {
    logger.info('Successful login', { username, ip: req.ip });
  } else {
    logger.warn('Failed login attempt', { username, ip: req.ip });
    // мониторинг подозрительной активности
    await checkBruteForce(username, req.ip);
  }
});
```

**Решение: Структурированное логирование**
```python
# Хорошо: структурированное логирование
import logging
import json

logger = logging.getLogger(__name__)

def log_security_event(event_type, user_id, ip_address, details=None):
    log_data = {
        'event_type': event_type,
        'user_id': user_id,
        'ip_address': ip_address,
        'timestamp': datetime.utcnow().isoformat(),
        'details': details
    }
    logger.info(json.dumps(log_data))
```

**Решение: Мониторинг и alerting**
```javascript
// Хорошо: мониторинг критических событий
async function monitorSecurityEvents(event) {
  if (event.type === 'failed_login') {
    const attempts = await countFailedLogins(event.username, '15m');
    if (attempts > 5) {
      await sendAlert('Brute force attack detected', event);
    }
  }
  
  if (event.type === 'admin_action') {
    await logAdminAction(event);
    await sendAlert('Admin action performed', event);
  }
}
```

### Ресурсы

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [OWASP AppSensor](https://owasp.org/www-project-appsensor/)

---

## A10:2021 - Server-Side Request Forgery (SSRF)

### Описание уязвимости

Server-Side Request Forgery (SSRF) возникает, когда приложение выполняет HTTP запросы к URL, указанным пользователем, без должной валидации. Это может привести к доступу к внутренним ресурсам, обходу firewall, атакам на внутренние сервисы.

### Примеры проявления в коде

**Проблема: Запросы к пользовательским URL без валидации**
```javascript
// Плохо: нет валидации URL
app.get('/api/fetch', async (req, res) => {
  const url = req.query.url;
  const response = await fetch(url);  // может быть внутренний URL
  res.json(await response.json());
});
```

**Проблема: Доступ к внутренним ресурсам**
```python
# Плохо: может получить доступ к внутренним сервисам
import requests

def fetch_url(url):
    response = requests.get(url)  # может быть http://localhost:8080/admin
    return response.json()
```

**Проблема: Отсутствие whitelist**
```javascript
// Плохо: разрешены любые домены
const allowedDomains = ['*'];  // слишком широко
```

### Способы обнаружения

1. Поиск запросов к внешним URL на основе пользовательского ввода
2. Проверить валидацию URL перед запросами
3. Проверить использование whitelist для разрешенных доменов
4. Проверить защиту от доступа к внутренним ресурсам (localhost, private IP)
5. Проверить использование библиотек для безопасных HTTP запросов

### Методы исправления

**Решение: Валидация URL**
```javascript
// Хорошо: валидация URL
const url = require('url');

function validateUrl(userUrl) {
  const parsed = url.parse(userUrl);
  
  // Проверка протокола
  if (!['http:', 'https:'].includes(parsed.protocol)) {
    throw new Error('Invalid protocol');
  }
  
  // Проверка домена (whitelist)
  const allowedDomains = ['api.example.com', 'cdn.example.com'];
  if (!allowedDomains.includes(parsed.hostname)) {
    throw new Error('Domain not allowed');
  }
  
  // Проверка на внутренние адреса
  if (parsed.hostname === 'localhost' || 
      parsed.hostname.startsWith('127.') ||
      parsed.hostname.startsWith('192.168.') ||
      parsed.hostname.startsWith('10.')) {
    throw new Error('Internal addresses not allowed');
  }
  
  return parsed.href;
}
```

**Решение: Использование whitelist**
```python
# Хорошо: использование whitelist
ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com']

def validate_url(user_url):
    parsed = urlparse(user_url)
    
    if parsed.hostname not in ALLOWED_DOMAINS:
        raise ValueError('Domain not in whitelist')
    
    if parsed.scheme not in ['http', 'https']:
        raise ValueError('Invalid scheme')
    
    return user_url
```

**Решение: Использование прокси/API Gateway**
```javascript
// Хорошо: использование прокси вместо прямых запросов
// Вместо прямого запроса к пользовательскому URL,
// использовать внутренний API Gateway с whitelist
app.get('/api/fetch', async (req, res) => {
  const resourceId = req.query.resource;
  // API Gateway проверяет whitelist и выполняет запрос
  const response = await apiGateway.fetch(resourceId);
  res.json(response);
});
```

### Ресурсы

- [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
- [PortSwigger SSRF](https://portswigger.net/web-security/ssrf)

---

## Общие рекомендации

### Процесс проверки

1. **Начните с архитектуры**: Проверьте архитектурные решения безопасности
2. **Проверьте аутентификацию**: Убедитесь, что аутентификация реализована правильно
3. **Проверьте авторизацию**: Убедитесь, что права доступа проверяются на всех уровнях
4. **Проверьте входные данные**: Убедитесь, что все входные данные валидируются и санитизируются
5. **Проверьте криптографию**: Убедитесь, что чувствительные данные защищены
6. **Проверьте зависимости**: Убедитесь, что зависимости обновлены и безопасны
7. **Проверьте логирование**: Убедитесь, что события безопасности логируются

### Инструменты для проверки

- **Статический анализ**: ESLint security plugins, Bandit (Python), SonarQube
- **Динамический анализ**: OWASP ZAP, Burp Suite
- **Сканирование зависимостей**: npm audit, pip-audit, Snyk, Dependabot
- **Проверка конфигурации**: OWASP Dependency-Check, Retire.js

### Регулярность проверок

- После каждого значимого изменения кода
- Перед каждым релизом
- При добавлении новых зависимостей
- При изменении архитектуры
- Минимум раз в квартал для production систем

---

**Примечание**: Этот документ содержит базовую информацию по каждой категории OWASP Top 10. Для более детального изучения обратитесь к официальной документации OWASP.


