# Redux для управления состоянием в React

## Описание

Redux - это предсказуемый контейнер состояния для JavaScript приложений. Он помогает управлять глобальным состоянием приложения через единое хранилище (store) и предсказуемые обновления через actions и reducers.

## Когда использовать

- ✅ Большие приложения с сложным состоянием
- ✅ Когда нужна предсказуемость и отладка
- ✅ Когда состояние нужно в многих компонентах
- ✅ Для командных проектов

## Когда НЕ использовать

- ❌ Простые приложения (может быть избыточно)
- ❌ Когда состояние локальное
- ❌ Для начинающих (более сложный)

## Базовое использование

### Установка

```bash
npm install @reduxjs/toolkit react-redux
```

### Настройка store

```javascript
import { configureStore, createSlice } from '@reduxjs/toolkit';

// Slice
const counterSlice = createSlice({
  name: 'counter',
  initialState: { value: 0 },
  reducers: {
    increment: (state) => {
      state.value += 1;
    },
    decrement: (state) => {
      state.value -= 1;
    },
  },
});

// Store
export const store = configureStore({
  reducer: {
    counter: counterSlice.reducer,
  },
});

export const { increment, decrement } = counterSlice.actions;
```

### Использование в компоненте

```javascript
import { useSelector, useDispatch } from 'react-redux';
import { increment, decrement } from './store';

function Counter() {
  const count = useSelector((state) => state.counter.value);
  const dispatch = useDispatch();

  return (
    <div>
      <div>Count: {count}</div>
      <button onClick={() => dispatch(increment())}>+</button>
      <button onClick={() => dispatch(decrement())}>-</button>
    </div>
  );
}
```

## Преимущества

- ✅ Предсказуемость
- ✅ Отладка через Redux DevTools
- ✅ Подходит для больших приложений
- ✅ Хорошая экосистема

## Недостатки

- ❌ Больше boilerplate
- ❌ Может быть избыточно для простых случаев

## Best Practices

1. **Используйте Redux Toolkit** вместо чистого Redux
2. **Нормализуйте данные** в store
3. **Используйте селекторы** для вычисляемых значений
4. **Разделяйте reducers** по доменам

## Связанные паттерны

- [Context API](context-api.md) - более простая альтернатива
- [Zustand](zustand.md) - легковесная альтернатива

