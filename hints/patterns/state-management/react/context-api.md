# Context API для управления состоянием в React

## Описание

Context API - это встроенный механизм React для передачи данных через дерево компонентов без prop drilling. Подходит для простого глобального состояния.

## Когда использовать

- ✅ Простое глобальное состояние
- ✅ Тема, язык, пользователь
- ✅ Когда не нужна сложная логика
- ✅ Для небольших и средних приложений

## Когда НЕ использовать

- ❌ Часто изменяющееся состояние (может быть неэффективно)
- ❌ Очень большое приложение
- ❌ Сложная бизнес-логика

## Базовое использование

```javascript
import { createContext, useContext, useState } from 'react';

// Создание контекста
const CounterContext = createContext();

// Provider
function CounterProvider({ children }) {
  const [count, setCount] = useState(0);

  const increment = () => setCount(c => c + 1);
  const decrement = () => setCount(c => c - 1);

  return (
    <CounterContext.Provider value={{ count, increment, decrement }}>
      {children}
    </CounterContext.Provider>
  );
}

// Hook для использования
function useCounter() {
  const context = useContext(CounterContext);
  if (!context) {
    throw new Error('useCounter must be used within CounterProvider');
  }
  return context;
}

// Использование
function App() {
  return (
    <CounterProvider>
      <Counter />
    </CounterProvider>
  );
}

function Counter() {
  const { count, increment, decrement } = useCounter();

  return (
    <div>
      <div>Count: {count}</div>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  );
}
```

## Преимущества

- ✅ Встроено в React
- ✅ Простота использования
- ✅ Не требует дополнительных библиотек

## Недостатки

- ❌ Может быть неэффективно для частых обновлений
- ❌ Нет встроенной оптимизации

## Best Practices

1. **Разделяйте контексты** по доменам
2. **Используйте useMemo** для значений контекста
3. **Создавайте кастомные хуки** для использования контекста

## Связанные паттерны

- [Redux](redux.md) - для сложного состояния
- [Zustand](zustand.md) - легковесная альтернатива

