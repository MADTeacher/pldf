# Pinia - современное управление состоянием для Vue 3

## Описание

Pinia - это официальная библиотека управления состоянием для Vue 3. Она является преемником Vuex и предоставляет более простой и типобезопасный API.

## Когда использовать

- ✅ Vue 3 приложения
- ✅ Когда нужна простота и типобезопасность
- ✅ Для новых проектов

## Базовое использование

```javascript
import { defineStore } from 'pinia';

export const useCounterStore = defineStore('counter', {
  state: () => ({
    count: 0
  }),
  actions: {
    increment() {
      this.count++;
    },
    decrement() {
      this.count--;
    }
  }
});

// Использование в компоненте
import { useCounterStore } from './stores/counter';

export default {
  setup() {
    const counter = useCounterStore();
    
    return {
      count: computed(() => counter.count),
      increment: () => counter.increment()
    };
  }
}
```

## Преимущества

- ✅ Официальная библиотека Vue 3
- ✅ Проще, чем Vuex
- ✅ Лучшая типобезопасность
- ✅ Меньше boilerplate

## Связанные паттерны

- [Vuex](vuex.md) - для Vue 2 приложений

