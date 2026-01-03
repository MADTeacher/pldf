# OWASP ASVS - База знаний для проверки безопасности

Этот документ содержит описание категорий OWASP Application Security Verification Standard (ASVS) для использования в команде `/pldf.security` при scope = full или asvs.

## Обзор ASVS

OWASP ASVS предоставляет основу для тестирования технических контролей безопасности приложений. Стандарт разделен на три уровня:

- **Level 1 (L1)**: Базовый уровень - для приложений с низким уровнем риска
- **Level 2 (L2)**: Стандартный уровень - для большинства приложений
- **Level 3 (L3)**: Высокий уровень - для приложений с высоким уровнем риска

## V1: Architecture, Design and Threat Modeling

### Описание

Проверка архитектурных решений безопасности, threat modeling, и принципов безопасного дизайна.

### Ключевые проверки

- Наличие threat modeling документации
- Архитектурные решения безопасности задокументированы
- Разделение ответственности (separation of concerns)
- Принцип наименьших привилегий реализован
- Defense in depth применен
- Безопасность учтена на этапе проектирования

### Ресурсы

- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [OWASP Secure Design Principles](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Product_Design_Cheat_Sheet.html)

---

## V2: Authentication

### Описание

Проверка реализации аутентификации, включая MFA, политики паролей, восстановление паролей.

### Ключевые проверки

- Реализована безопасная аутентификация
- Политики паролей соответствуют требованиям (L1: минимум 8 символов, L2: минимум 12 символов с сложностью)
- Реализована защита от brute force атак
- Реализована двухфакторная аутентификация (L2+)
- Безопасное восстановление пароля
- Безопасное хранение учетных данных

### Ресурсы

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

---

## V3: Session Management

### Описание

Проверка управления сессиями, включая генерацию session ID, timeout, invalidation.

### Ключевые проверки

- Session ID генерируются криптографически стойким способом
- Реализован timeout сессий
- Сессии инвалидируются при logout
- Защита от session fixation
- Безопасное хранение session tokens
- HttpOnly, Secure, SameSite флаги для cookies

### Ресурсы

- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)

---

## V4: Access Control

### Описание

Проверка контроля доступа, включая RBAC, ABAC, принцип наименьших привилегий.

### Ключевые проверки

- Реализован RBAC или ABAC
- Проверки прав на всех уровнях (UI, API, DB)
- Защита от privilege escalation
- Защита от IDOR (Insecure Direct Object Reference)
- Принцип наименьших привилегий применен
- Проверки доступа на уровне базы данных

### Ресурсы

- [OWASP Access Control Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)

---

## V5: Validation, Sanitization and Encoding

### Описание

Проверка валидации, санитизации и encoding всех типов входных данных.

### Ключевые проверки

- Валидация всех типов входных данных (строки, числа, файлы, JSON, XML)
- Санитизация перед выводом (защита от XSS)
- Правильное encoding для разных контекстов (HTML, URL, SQL, JavaScript)
- Валидация файлов (тип, размер, содержимое)
- Валидация на клиенте и сервере
- Whitelist подход вместо blacklist

### Ресурсы

- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

---

## V6: Cryptographic Storage

### Описание

Проверка криптографического хранения чувствительных данных.

### Ключевые проверки

- Использование стойких алгоритмов шифрования (AES-256, ChaCha20)
- Безопасное управление ключами шифрования
- Использование authenticated encryption
- Пароли хешируются с использованием bcrypt, argon2, scrypt
- Чувствительные данные зашифрованы при хранении

### Ресурсы

- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

---

## V7: Error Handling and Logging

### Описание

Проверка обработки ошибок и логирования без раскрытия конфиденциальной информации.

### Ключевые проверки

- Обработка ошибок не раскрывает конфиденциальную информацию
- Логирование событий безопасности
- Логирование без секретов
- Структурированное логирование
- Мониторинг подозрительной активности

### Ресурсы

- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [OWASP Error Handling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html)

---

## V8: Data Protection

### Описание

Проверка защиты данных при передаче и хранении.

### Ключевые проверки

- Использование HTTPS/TLS для передачи данных
- Правильная настройка TLS (версия, cipher suites)
- Защита данных при хранении
- Минимизация сбора данных
- Удаление данных после истечения срока хранения

### Ресурсы

- [OWASP Transport Layer Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html)

---

## V9: Communications

### Описание

Проверка безопасности коммуникаций между компонентами системы.

### Ключевые проверки

- Безопасная коммуникация между сервисами
- Использование mTLS для межсервисной коммуникации
- Защита API endpoints
- Rate limiting на API endpoints
- Валидация сертификатов

### Ресурсы

​- [Web Service Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Web_Service_Security_Cheat_Sheet.html)
​
---

## V10: Malicious Code

### Описание

Проверка защиты от вредоносного кода и supply chain атак.

### Ключевые проверки

- Защита от code injection
- Проверка целостности зависимостей
- Использование подписанных пакетов
- Защита от deserialization атак
- Sandboxing для недоверенного кода

### Ресурсы

- [OWASP Deserialization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html)

---

## V11: Business Logic

### Описание

Проверка бизнес-логики на уязвимости безопасности.

### Ключевые проверки

- Проверка бизнес-правил на сервере
- Защита от race conditions
- Защита от массовых операций
- Валидация бизнес-правил
- Защита от обхода бизнес-логики

### Ресурсы

- [OWASP Business Logic Testing](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/10-Business_Logic_Testing/)

---

## V12: Files and Resources

### Описание

Проверка безопасности работы с файлами и ресурсами.

### Ключевые проверки

- Валидация загружаемых файлов
- Ограничение типов и размеров файлов
- Сканирование файлов на вредоносное содержимое
- Безопасное хранение файлов
- Защита от path traversal

### Ресурсы

- [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)

---

## V13: API

### Описание

Проверка безопасности API endpoints.

### Ключевые проверки

- Аутентификация и авторизация API
- Валидация входных данных API
- Rate limiting
- Защита от массовых операций
- Правильная обработка ошибок API

### Ресурсы

- [OWASP API Security Top 10](https://owasp.org/API-Security/)
- [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)

---

## V14: Configuration

### Описание

Проверка конфигурации безопасности приложения и инфраструктуры.

### Ключевые проверки

- Безопасная конфигурация фреймворков
- Отсутствие секретов в конфигурационных файлах
- Правильные настройки CORS, CSP
- Безопасные настройки production окружения
- Отключение debug режима в production

### Ресурсы

- [OWASP ASVS v4.0.3 - Configuration Verification](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Deployment Cheat Sheet](https://www.google.com/search?q=https://cheatsheetseries.owasp.org/cheatsheets/Deployment_Cheat_Sheet.html)
- [OWASP Content Security Policy (CSP) Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

## Процесс проверки ASVS

1. Определить уровень проверки (L1, L2, или L3)
2. Для каждой категории V1-V14 проверить соответствующие требования уровня
3. Документировать найденные проблемы
4. Предоставить рекомендации по устранению

---

**Примечание**: Для полного списка требований ASVS обратитесь к [официальной документации OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/).


