# Error Boundaries в React

## Описание

Error Boundary - это React компонент, который перехватывает ошибки JavaScript в любом месте дерева дочерних компонентов, логирует их и отображает запасной UI вместо упавшего компонента.

## Когда использовать

- ✅ Для предотвращения падения всего приложения
- ✅ Для отображения понятных сообщений об ошибках
- ✅ Для логирования ошибок

## Базовое использование

```javascript
import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Логирование ошибки
    console.error('Error caught by boundary:', error, errorInfo);
    // Можно отправить в сервис мониторинга
    // logErrorToService(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div>
          <h2>Что-то пошло не так</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            Попробовать снова
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

// Использование
function App() {
  return (
    <ErrorBoundary>
      <MyComponent />
    </ErrorBoundary>
  );
}
```

## Best Practices

1. **Размещайте Error Boundaries** на стратегических уровнях
2. **Логируйте ошибки** для отладки
3. **Предоставляйте запасной UI** вместо белого экрана
4. **Позволяйте пользователю** попробовать снова

## Связанные паттерны

- [Логирование](logging.md) - для логирования ошибок

