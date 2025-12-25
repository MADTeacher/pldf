# Zustand - легковесное управление состоянием для React

## Описание

Zustand - это легковесная библиотека для управления состоянием в React. Она предоставляет простой API без boilerplate кода, характерного для Redux.

## Когда использовать

- ✅ Средние приложения
- ✅ Когда Redux избыточен, но Context API недостаточен
- ✅ Когда нужна простота и производительность
- ✅ Для быстрой разработки

## Базовое использование

### Установка

```bash
npm install zustand
```

### Создание store

```javascript
import create from 'zustand';

const useStore = create((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
}));

// Использование
function Counter() {
  const { count, increment, decrement } = useStore();

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

- ✅ Минимум boilerplate
- ✅ Хорошая производительность
- ✅ Простота использования
- ✅ Не требует Provider

## Best Practices

1. **Разделяйте stores** по доменам
2. **Используйте селекторы** для оптимизации
3. **Используйте middleware** для расширения функциональности

## Связанные паттерны

- [Redux](redux.md) - для более сложных случаев
- [Context API](context-api.md) - более простая альтернатива

